DOTS="${DOTFILES_DIR:-$HOME/dotfiles}"
TEMPLATES="$DOTS/templates"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  A=$'\033[38;2;255;92;0m'
  D=$'\033[38;2;110;110;110m'
  B=$'\033[1m'
  R=$'\033[0m'
else
  A="" D="" B="" R=""
fi

die() {
  printf '%sdev%s %s\n' "$A" "$R" "$*" >&2
  exit 1
}

hint() {
  printf '    %s%s%s\n' "$D" "$*" "$R" >&2
}

say() {
  printf '%sdev%s %s\n' "$A" "$R" "$*"
}

field() {
  printf '  %s%-10s%s %s\n' "$D" "$1" "$R" "$2"
}

list_templates() {
  [ -d "$TEMPLATES" ] || die "no templates directory at $TEMPLATES"
  find "$TEMPLATES" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

composable() {
  sed -n '/toolchains = {/,/^        };/p' "$TEMPLATES/poly/flake.nix" |
    sed -n 's/^[[:space:]]*\([a-z][a-z0-9_]*\) = with pkgs;.*/\1/p'
}

is_template() {
  list_templates | grep -qx -- "$1"
}

is_composable() {
  composable | grep -qx -- "$1"
}

bins_for() {
  case $1 in
    rust) printf 'rustc cargo rust-analyzer rustfmt' ;;
    go) printf 'go gopls dlv golangci-lint' ;;
    python) printf 'python3 uv ruff basedpyright-langserver' ;;
    cpp) printf 'clang clangd cmake ninja' ;;
    lua) printf 'luajit lua-language-server stylua selene' ;;
    node) printf 'node typescript-language-server biome' ;;
    dotfiles) printf 'lua-language-server stylua nixd nixfmt statix deadnix' ;;
    *) printf '' ;;
  esac
}

markers_for() {
  case $1 in
    rust) printf 'Cargo.toml' ;;
    go) printf 'go.mod' ;;
    python) printf 'pyproject.toml setup.py setup.cfg requirements.txt' ;;
    node) printf 'package.json' ;;
    cpp) printf 'CMakeLists.txt compile_commands.json' ;;
    *) printf '' ;;
  esac
}

SIDECAR=devshell.json

spec_read() {
  [ -f "$SIDECAR" ] || return 1
  python3 -c '
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    raise SystemExit(1)
if isinstance(d, list):
    d = {"languages": d, "packages": []}
for x in d.get(sys.argv[2], []) or []:
    print(x)
' "$SIDECAR" "$1"
}

spec_write() {
  local key=$1
  shift
  python3 -c '
import json, os, sys
path, key, vals = sys.argv[1], sys.argv[2], sys.argv[3:]
d = {"languages": [], "packages": []}
if os.path.exists(path):
    try:
        cur = json.load(open(path))
        if isinstance(cur, list):
            cur = {"languages": cur, "packages": []}
        for k in ("languages", "packages"):
            d[k] = list(cur.get(k) or [])
    except Exception:
        pass
d[key] = vals
with open(path, "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")
' "$SIDECAR" "$key" "$@"
  git_track "$SIDECAR"
}

git_track() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  git ls-files --error-unmatch "$1" >/dev/null 2>&1 && return 0
  if git add -N "$1" 2>/dev/null; then
    hint "git add -N $1  (so nix can see it)"
  fi
}

git_exclude() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  local ex
  ex=$(git rev-parse --git-path info/exclude) || return 0
  mkdir -p "$(dirname "$ex")"
  grep -qxF -- "$1" "$ex" 2>/dev/null && return 0
  printf '%s\n' "$1" >>"$ex"
  hint "excluded $1 via .git/info/exclude"
}

in_repo_note() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  hint "not your repo? dev shell $*  (writes nothing)"
}

poly_langs() {
  spec_read languages
}

poly_pkgs() {
  spec_read packages
}

is_poly() {
  [ -f "$SIDECAR" ] && [ "$(dir_lang 2>/dev/null)" = poly ]
}

is_legacy_poly() {
  [ -f flake.nix ] && [ ! -f "$SIDECAR" ] &&
    grep -q '^[[:space:]]*enabled = \[' flake.nix
}

legacy_guard() {
  if is_legacy_poly; then
    printf '%sdev%s this poly shell predates devshell.json\n' "$A" "$R" >&2
    hint "migrate: dev switch $(sed -n 's/^[[:space:]]*enabled = \[\(.*\)\];.*/\1/p' flake.nix | tr -d '"') -f"
    exit 1
  fi
}

dir_lang() {
  [ -f flake.nix ] || return 1
  local v
  v=$(sed -n 's/^[[:space:]]*DEVSHELL = "\([a-z0-9_]*\)";.*/\1/p' flake.nix | head -1)
  [ -n "$v" ] || return 1
  printf '%s\n' "$v"
}

set_poly_langs() {
  spec_write languages "$@"
}

set_poly_pkgs() {
  spec_write packages "$@"
}

validate_pkg() {
  nix eval --raw "nixpkgs#$1.name" >/dev/null 2>&1
}

dedupe() {
  awk 'NF && !seen[$0]++'
}

active_langs() {
  if [ -n "${DEV_LANGS:-}" ]; then
    printf '%s\n' "$DEV_LANGS" | tr ' ' '\n'
  elif [ "${DEVSHELL:-}" = poly ] && is_poly; then
    poly_langs
  elif [ -n "${DEVSHELL:-}" ]; then
    printf '%s\n' "$DEVSHELL"
  fi
}

rc_state() {
  direnv status --json 2>/dev/null | python3 -c '
import json, sys
try:
    s = json.load(sys.stdin)["state"]
except Exception:
    print("none"); raise SystemExit
rc = s.get("foundRC")
if not rc:
    print("none")
elif rc.get("allowed") == 0:
    print("loaded" if s.get("loadedRC") else "allowed")
else:
    print("blocked")
'
}

require_composable() {
  local n
  for n in "$@"; do
    if [ "$n" = poly ]; then
      printf '%sdev%s poly takes language names\n' "$A" "$R" >&2
      hint "try: dev init $(composable | tr '\n' ' ' | sed 's/ *$//')"
      exit 1
    fi
    if ! is_composable "$n"; then
      printf '%sdev%s cannot combine %s\n' "$A" "$R" "$n" >&2
      hint "combinable: $(composable | tr '\n' ' ' | sed 's/ *$//')"
      [ -n "$(is_template "$n" && echo y)" ] && hint "'$n' works on its own: dev init $n"
      exit 1
    fi
  done
}

reload_note() {
  hint "cd out and back, or run 'direnv reload', to enter it"
}

write_single() {
  cp -f "$TEMPLATES/$1/flake.nix" ./flake.nix
  cp -f "$TEMPLATES/$1/.envrc" ./.envrc
  direnv allow . 2>/dev/null || true
  say "$1 shell ready"
  git_track flake.nix
  in_repo_note "$1"
  reload_note
}

write_poly() {
  cp -f "$TEMPLATES/poly/flake.nix" ./flake.nix
  cp -f "$TEMPLATES/poly/.envrc" ./.envrc
  rm -f "$SIDECAR"
  set_poly_langs "$@"
  direnv allow . 2>/dev/null || true
  say "poly shell ready ($*)"
  git_track flake.nix
  in_repo_note "$@"
  reload_note
}

# copies the template out to a cache dir rather than pointing nix at
# ~/dotfiles/templates directly. nix writes flake.lock next to the flake and
# git-adds it, which would dirty the dotfiles repo on every invocation.
shell_dir() {
  local -a langs
  mapfile -t langs < <(printf '%s\n' "$@" | sort -u)

  local dir
  if [ ${#langs[@]} -eq 1 ]; then
    dir="${XDG_CACHE_HOME:-$HOME/.cache}/dev/${langs[0]}"
    mkdir -p "$dir"
    cp -f "$TEMPLATES/${langs[0]}/flake.nix" "$dir/flake.nix"
  else
    dir="${XDG_CACHE_HOME:-$HOME/.cache}/dev/poly-$(printf '%s-' "${langs[@]}" | sed 's/-$//')"
    mkdir -p "$dir"
    cp -f "$TEMPLATES/poly/flake.nix" "$dir/flake.nix"
    printf '{\n  "languages": [%s],\n  "packages": []\n}\n' \
      "$(printf '"%s",' "${langs[@]}" | sed 's/,$//')" >"$dir/devshell.json"
  fi
  printf '%s\n' "$dir"
}

LANGS=()
FORCE=0
FRESH=0

split_flags() {
  LANGS=()
  FORCE=0
  FRESH=0
  local a
  for a in "$@"; do
    case $a in
      -f | --force) FORCE=1 ;;
      --fresh) FRESH=1 ;;
      -*) die "unknown flag '$a'; try: dev help" ;;
      *) LANGS+=("$a") ;;
    esac
  done
}

scaffold() {
  local -a uniq
  mapfile -t uniq < <(printf '%s\n' "${LANGS[@]}" | dedupe)
  if [ ${#uniq[@]} -eq 1 ] && [ "${uniq[0]}" != poly ] && ! is_composable "${uniq[0]}"; then
    is_template "${uniq[0]}" || die "unknown shell '${uniq[0]}'; try: dev list"
    write_single "${uniq[0]}"
  elif [ ${#uniq[@]} -eq 1 ] && [ "${uniq[0]}" != poly ]; then
    write_single "${uniq[0]}"
  else
    require_composable "${uniq[@]}"
    write_poly "${uniq[@]}"
  fi
}

cmd_list() {
  local active t
  active=" $(active_langs | tr '\n' ' ')"
  while IFS= read -r t; do
    local summary
    if [ "$t" = poly ]; then
      summary="combine any of the others"
    else
      summary=$(bins_for "$t" | cut -d' ' -f1-3)
    fi
    if printf '%s' "$active" | grep -q " $t "; then
      printf '%s* %-8s%s %s%s%s\n' "$A" "$t" "$R" "$D" "$summary" "$R"
    else
      printf '  %-8s %s%s%s\n' "$t" "$D" "$summary" "$R"
    fi
  done < <(list_templates)
}

cmd_which() {
  local langs state
  langs=$(active_langs | tr '\n' ' ' | sed 's/ *$//')

  if [ "${DEVSHELL:-}" = poly ]; then
    field "shell" "poly ${D}($langs)${R}"
  else
    field "shell" "${DEVSHELL:-none}"
  fi

  state=$(rc_state)
  case $state in
    blocked) field "direnv" "not trusted ${D}(dev allow)${R}" ;;
    allowed) field "direnv" "allowed, not loaded ${D}(direnv reload)${R}" ;;
    loaded) field "direnv" "loaded" ;;
    *)
      if [ -n "${DEV_LANGS:-}" ]; then
        field "direnv" "${D}ephemeral shell, no .envrc${R}"
      else
        field "direnv" "no .envrc here ${D}(dev init <lang>)${R}"
        if [ -n "${DEVSHELL:-}" ]; then
          field "" "${A}shell above is inherited, not from this directory${R}"
        fi
      fi
      ;;
  esac

  if [ -f flake.nix ]; then
    field "flake" "$PWD/flake.nix"
  elif [ -f .envrc ]; then
    local out
    out=$(sed -n 's|^use flake \(/.*\)$|\1|p' .envrc | head -1)
    [ -n "$out" ] && field "flake" "$out/flake.nix ${D}(attached)${R}"
  fi

  local l b path
  for l in $langs; do
    for b in $(bins_for "$l"); do
      if path=$(command -v "$b" 2>/dev/null); then
        case $path in
          /nix/store/*) printf '  %-10s %-27s %sdevshell%s\n' "" "$b" "$D" "$R" ;;
          *) printf '  %-10s %-27s %ssystem%s\n' "" "$b" "$D" "$R" ;;
        esac
      else
        printf '  %-10s %-27s %sMISSING%s\n' "" "$b" "$A" "$R"
      fi
    done
  done
}

cmd_init() {
  split_flags "$@"
  [ ${#LANGS[@]} -ge 1 ] || die "which shell? try: dev list"

  if [ -e flake.nix ]; then
    printf '%sdev%s flake.nix already exists here\n' "$A" "$R" >&2
    if [ -e .envrc ]; then
      hint "already set up  ->  dev which"
      hint "replace it      ->  dev switch ${LANGS[*]} -f"
    else
      hint "keep your flake ->  dev adopt"
      hint "replace it      ->  dev switch ${LANGS[*]} -f"
    fi
    exit 1
  fi

  scaffold
}

cmd_adopt() {
  [ -f flake.nix ] || die "no flake.nix here; try: dev init <lang>"
  if [ -f .envrc ]; then
    say ".envrc already present"
  else
    printf 'use flake\n' >.envrc
    say "added .envrc for your existing flake"
  fi
  direnv allow .
  reload_note
}

cmd_shell() {
  [ $# -ge 1 ] || die "which shell? try: dev list"

  local -a langs
  mapfile -t langs < <(printf '%s\n' "$@" | dedupe)

  if [ ${#langs[@]} -eq 1 ] && [ "${langs[0]}" != poly ]; then
    is_template "${langs[0]}" || die "unknown shell '${langs[0]}'; try: dev list"
  else
    require_composable "${langs[@]}"
  fi

  local dir
  dir=$(shell_dir "${langs[@]}")
  say "${langs[*]} shell, ephemeral"
  DEV_LANGS="${langs[*]}" exec nix develop "$dir" --command "${SHELL:-bash}"
}

# the flake lives out of tree because nix only sees git-tracked files, so an
# in-worktree flake.nix would have to be staged to work at all. .envrc is never
# read by nix, so it can sit in .git/info/exclude instead.
cmd_attach() {
  split_flags "$@"
  [ ${#LANGS[@]} -ge 1 ] || die "which shell? try: dev list"

  local -a uniq
  mapfile -t uniq < <(printf '%s\n' "${LANGS[@]}" | dedupe)
  if [ ${#uniq[@]} -eq 1 ] && [ "${uniq[0]}" != poly ]; then
    is_template "${uniq[0]}" || die "unknown shell '${uniq[0]}'; try: dev list"
  else
    require_composable "${uniq[@]}"
  fi

  if [ -e .envrc ] && [ "$FORCE" -eq 0 ]; then
    printf '%sdev%s .envrc already exists here\n' "$A" "$R" >&2
    hint "replace it: dev attach ${uniq[*]} -f"
    exit 1
  fi

  local dir
  dir=$(shell_dir "${uniq[@]}")
  printf 'export DEV_LANGS="%s"\nuse flake %s\n' "${uniq[*]}" "$dir" >.envrc
  git_exclude .envrc
  direnv allow . 2>/dev/null || true
  say "${uniq[*]} shell attached, nothing added to the repo"
  reload_note
}

cmd_add() {
  legacy_guard
  [ $# -ge 1 ] || die "which language? try: dev list"
  [ -f flake.nix ] || die "no shell here; try: dev init $*"

  local -a merged
  if is_poly; then
    require_composable "$@"
    mapfile -t merged < <(
      poly_langs
      printf '%s\n' "$@"
    )
    mapfile -t merged < <(printf '%s\n' "${merged[@]}" | dedupe)
    set_poly_langs "${merged[@]}"
    direnv allow . 2>/dev/null || true
    say "shell now: ${merged[*]}"
    reload_note
    return
  fi

  local cur
  if ! cur=$(dir_lang); then
    printf '%sdev%s this flake was not made by dev\n' "$A" "$R" >&2
    hint "replace it: dev switch $* -f"
    exit 1
  fi

  require_composable "$cur" "$@"
  mapfile -t merged < <(
    printf '%s\n' "$cur"
    printf '%s\n' "$@"
  )
  mapfile -t merged < <(printf '%s\n' "${merged[@]}" | dedupe)

  if [ -f flake.lock ]; then
    hint "keeping flake.lock"
  fi
  [ "$cur" = rust ] && hint "note: poly uses nixpkgs rust, not the pinned rust-overlay toolchain"

  write_poly "${merged[@]}"
}

cmd_rm() {
  legacy_guard
  [ $# -ge 1 ] || die "which language?"
  if ! is_poly; then
    printf '%sdev%s this is a single-language shell%s\n' "$A" "$R" \
      "$([ -n "$(dir_lang 2>/dev/null)" ] && printf ' (%s)' "$(dir_lang)")"
    hint "nothing to remove from; use: dev switch <lang> -f"
    exit 1
  fi
  local -a kept
  mapfile -t kept < <(poly_langs | grep -vxF -f <(printf '%s\n' "$@") || true)
  if [ ${#kept[@]} -eq 0 ]; then
    printf '%sdev%s that removes every language\n' "$A" "$R" >&2
    hint "to change shell entirely: dev switch <lang> -f"
    exit 1
  fi
  set_poly_langs "${kept[@]}"
  direnv allow . 2>/dev/null || true
  say "shell now: ${kept[*]}"
  reload_note
}

cmd_pkg() {
  local sub=${1:-}
  [ $# -gt 0 ] && shift
  case $sub in
    add)
      [ $# -ge 1 ] || die "which package?"
      legacy_guard
      is_poly || die "packages need a poly shell; try: dev add <lang>"
      local n
      for n in "$@"; do
        printf '%sdev%s checking %s in nixpkgs...\n' "$D" "$R" "$n"
        validate_pkg "$n" || die "no such package '$n' in nixpkgs"
      done
      local -a merged
      mapfile -t merged < <(
        poly_pkgs
        printf '%s\n' "$@"
      )
      mapfile -t merged < <(printf '%s\n' "${merged[@]}" | dedupe)
      set_poly_pkgs "${merged[@]}"
      direnv allow . 2>/dev/null || true
      say "packages now: ${merged[*]}"
      reload_note
      ;;
    rm | remove)
      [ $# -ge 1 ] || die "which package?"
      legacy_guard
      is_poly || die "not a poly shell"
      local -a kept
      mapfile -t kept < <(poly_pkgs | grep -vxF -f <(printf '%s\n' "$@") || true)
      set_poly_pkgs "${kept[@]}"
      direnv allow . 2>/dev/null || true
      if [ ${#kept[@]} -eq 0 ]; then
        say "no extra packages"
      else
        say "packages now: ${kept[*]}"
      fi
      reload_note
      ;;
    list | ls | "")
      legacy_guard
      is_poly || die "not a poly shell"
      local out
      out=$(poly_pkgs)
      if [ -z "$out" ]; then
        say "no extra packages"
      else
        printf '%s\n' "$out" | sed 's/^/  /'
      fi
      ;;
    *) die "unknown: dev pkg $sub; try add, rm, list" ;;
  esac
}

cmd_switch() {
  split_flags "$@"
  [ ${#LANGS[@]} -ge 1 ] || die "which shell? try: dev list"

  if [ -e flake.nix ] && [ "$FORCE" -eq 0 ]; then
    printf '%sdev%s this replaces flake.nix and .envrc here\n' "$A" "$R" >&2
    hint "confirm: dev switch ${LANGS[*]} -f"
    exit 1
  fi

  if [ "$FRESH" -eq 1 ]; then
    rm -f flake.lock
  elif [ -f flake.lock ]; then
    hint "keeping flake.lock (--fresh discards it)"
  fi

  scaffold
}

cmd_allow() {
  [ -f .envrc ] || die "no .envrc here; try: dev init <lang>"
  direnv allow .
  say "allowed"
}

cmd_update() {
  [ -f flake.nix ] || die "no flake.nix here"
  nix flake update
}

cmd_doctor() {
  local problems=0

  printf '%senvironment%s\n' "$B" "$R"
  if [ -d "$TEMPLATES" ]; then
    field "templates" "$TEMPLATES"
  else
    field "templates" "${A}missing at $TEMPLATES${R}"
    problems=$((problems + 1))
  fi
  if command -v direnv >/dev/null 2>&1; then
    field "direnv" "$(command -v direnv)"
  else
    field "direnv" "${A}not installed${R}"
    problems=$((problems + 1))
  fi

  printf '\n%sthis directory%s\n' "$B" "$R"
  if [ -f flake.nix ]; then
    field "flake.nix" "present"
  else
    field "flake.nix" "${A}absent${R} ${D}(dev init <lang>)${R}"
    problems=$((problems + 1))
  fi

  if [ -f .envrc ]; then
    field ".envrc" "present"
  else
    field ".envrc" "${A}absent${R} ${D}(dev init <lang>, or dev adopt)${R}"
    problems=$((problems + 1))
  fi

  case $(rc_state) in
    loaded) field "direnv" "loaded" ;;
    allowed)
      field "direnv" "${A}allowed but not loaded${R} ${D}(direnv reload)${R}"
      problems=$((problems + 1))
      ;;
    blocked)
      field "direnv" "${A}not trusted${R} ${D}(dev allow)${R}"
      problems=$((problems + 1))
      ;;
    *) field "direnv" "${D}nothing to load${R}" ;;
  esac

  if [ -n "${DEVSHELL:-}" ]; then
    if [ -f .envrc ]; then
      field "loaded" "$DEVSHELL"
    else
      field "loaded" "$DEVSHELL ${A}(inherited, not from here)${R}"
    fi
  else
    field "loaded" "${A}no shell in this environment${R}"
    problems=$((problems + 1))
  fi

  local langs l b m found
  langs=$(active_langs | tr '\n' ' ')

  if [ -n "$langs" ]; then
    printf '\n%stoolchains%s\n' "$B" "$R"
    local missing=0
    for l in $langs; do
      for b in $(bins_for "$l"); do
        if ! command -v "$b" >/dev/null 2>&1; then
          field "$l" "${A}$b missing${R}"
          missing=$((missing + 1))
          problems=$((problems + 1))
        fi
      done
    done
    [ "$missing" -eq 0 ] && field "" "${D}all present${R}"

    local marker_out="" marker_bad=0
    for l in $langs; do
      m=$(markers_for "$l")
      [ -n "$m" ] || continue
      found=0
      for b in $m; do
        [ -e "$b" ] && found=1
      done
      if [ "$found" -eq 1 ]; then
        marker_out="$marker_out$(field "$l" "ok")"$'\n'
      else
        marker_out="$marker_out$(field "$l" "${A}none of: $m${R}")"$'\n'
        marker_bad=1
        problems=$((problems + 1))
      fi
    done
    if [ -n "$marker_out" ]; then
      printf '\n%slsp root markers%s\n' "$B" "$R"
      printf '%s' "$marker_out"
      [ "$marker_bad" -eq 1 ] && hint "language servers may not attach without one of these"
    fi
  fi

  printf '\n'
  if [ "$problems" -eq 0 ]; then
    say "no problems found"
  else
    say "$problems thing(s) to look at"
  fi
}


T_PASS=0
T_FAIL=0

t_ok() {
  T_PASS=$((T_PASS + 1))
  printf '  %-38s %sok%s\n' "$1" "$D" "$R"
}

t_no() {
  T_FAIL=$((T_FAIL + 1))
  printf '  %-38s %sFAIL%s  %s\n' "$1" "$A" "$R" "${2:-}"
}

t_check() {
  local name=$1 expect=$2 got=$3
  if [ "$expect" = "$got" ]; then t_ok "$name"; else t_no "$name" "want [$expect] got [$got]"; fi
}

cmd_selftest() {
  SELFTEST_ROOT=$(mktemp -d)
  local root=$SELFTEST_ROOT
  trap 'rm -rf "$SELFTEST_ROOT"' EXIT
  local here=$PWD

  printf '%sscaffolding%s\n' "$B" "$R"

  mkdir -p "$root/a" && cd "$root/a"
  dev init go >/dev/null 2>&1 || true
  t_check "init single writes flake+envrc" "yes" "$([ -f flake.nix ] && [ -f .envrc ] && echo yes)"
  t_check "single shell has no sidecar" "yes" "$([ ! -f devshell.json ] && echo yes)"

  mkdir -p "$root/b" && cd "$root/b"
  dev init go python node >/dev/null 2>&1 || true
  t_check "init poly writes sidecar" "go python node" "$(poly_langs | tr '\n' ' ' | sed 's/ *$//')"

  mkdir -p "$root/c" && cd "$root/c"
  dev init go go python >/dev/null 2>&1 || true
  t_check "duplicate languages deduped" "go python" "$(poly_langs | tr '\n' ' ' | sed 's/ *$//')"

  mkdir -p "$root/d" && cd "$root/d"
  t_check "single 'poly' rejected" "1" "$(dev init poly >/dev/null 2>&1; echo $?)"
  t_check "  ...left no files" "yes" "$([ ! -f flake.nix ] && echo yes)"

  mkdir -p "$root/e" && cd "$root/e"
  dev init rust -f >/dev/null 2>&1 || true
  t_check "-f parsed as flag not language" "rust" "$(dir_lang 2>/dev/null)"

  mkdir -p "$root/f" && cd "$root/f"
  t_check "unknown language rejected" "1" "$(dev init go haskell >/dev/null 2>&1; echo $?)"
  t_check "  ...left no files" "yes" "$([ ! -f flake.nix ] && echo yes)"

  printf '\n%sdestructive guards%s\n' "$B" "$R"

  mkdir -p "$root/g" && cd "$root/g"
  printf '{ outputs = _: {}; }\n' >flake.nix
  dev init rust >/dev/null 2>&1 || true
  t_check "init refuses over existing flake" "{ outputs = _: {}; }" "$(cat flake.nix)"

  mkdir -p "$root/h" && cd "$root/h"
  dev init go >/dev/null 2>&1 || true
  printf 'KEEP\n' >flake.lock
  dev switch python -f >/dev/null 2>&1 || true
  t_check "switch preserves flake.lock" "KEEP" "$(cat flake.lock 2>/dev/null)"
  dev switch python -f --fresh >/dev/null 2>&1 || true
  t_check "switch --fresh discards lock" "gone" "$([ ! -f flake.lock ] && echo gone)"

  mkdir -p "$root/i" && cd "$root/i"
  printf '{ description = "mine"; outputs = _: {}; }\n' >flake.nix
  dev adopt >/dev/null 2>&1 || true
  t_check "adopt adds envrc" "use flake" "$(cat .envrc 2>/dev/null)"
  t_check "adopt leaves flake alone" "yes" "$(grep -q 'description = "mine"' flake.nix && echo yes)"

  printf '\n%ssidecar%s\n' "$B" "$R"

  mkdir -p "$root/j" && cd "$root/j"
  dev init go >/dev/null 2>&1 || true
  dev add python >/dev/null 2>&1 || true
  t_check "add upgrades single to poly" "go python" "$(poly_langs | tr '\n' ' ' | sed 's/ *$//')"
  dev add python >/dev/null 2>&1 || true
  t_check "add is idempotent" "go python" "$(poly_langs | tr '\n' ' ' | sed 's/ *$//')"
  dev rm python >/dev/null 2>&1 || true
  t_check "rm works" "go" "$(poly_langs | tr '\n' ' ' | sed 's/ *$//')"
  t_check "rm of last language refused" "1" "$(dev rm go >/dev/null 2>&1; echo $?)"

  nixfmt flake.nix >/dev/null 2>&1 || true
  t_check "survives nixfmt on flake.nix" "go" "$(poly_langs | tr '\n' ' ' | sed 's/ *$//')"

  set_poly_pkgs ffmpeg jq
  t_check "packages round-trip" "ffmpeg jq" "$(poly_pkgs | tr '\n' ' ' | sed 's/ *$//')"
  t_check "  ...languages untouched" "go" "$(poly_langs | tr '\n' ' ' | sed 's/ *$//')"
  set_poly_langs go rust
  t_check "  ...packages survive lang write" "ffmpeg jq" "$(poly_pkgs | tr '\n' ' ' | sed 's/ *$//')"

  mkdir -p "$root/k" && cd "$root/k" && git init -q .
  dev init go python >/dev/null 2>&1 || true
  t_check "sidecar git-tracked in a repo" "yes" "$(git ls-files | grep -qx devshell.json && echo yes)"
  t_check "poly flake git-tracked in a repo" "yes" "$(git ls-files | grep -qx flake.nix && echo yes)"

  mkdir -p "$root/m" && cd "$root/m" && git init -q .
  dev init rust >/dev/null 2>&1 || true
  t_check "single flake git-tracked in a repo" "yes" "$(git ls-files | grep -qx flake.nix && echo yes)"

  printf '\n%sephemeral shells%s\n' "$B" "$R"

  mkdir -p "$root/n" && cd "$root/n"
  export XDG_CACHE_HOME="$root/cache"
  local d
  d=$(shell_dir rust)
  t_check "single dir keyed by language" "$root/cache/dev/rust" "$d"
  t_check "  ...carries the rust template" "yes" "$(grep -q rust-overlay "$d/flake.nix" && echo yes)"
  t_check "  ...no sidecar" "yes" "$([ ! -f "$d/devshell.json" ] && echo yes)"

  d=$(shell_dir python go)
  t_check "poly dir key is sorted" "$root/cache/dev/poly-go-python" "$d"
  t_check "  ...sidecar lists both" "go python" "$(cd "$d" && spec_read languages | tr '\n' ' ' | sed 's/ *$//')"
  t_check "  ...arg order shares one cache dir" "$d" "$(shell_dir go python)"
  t_check "wrote nothing into cwd" "yes" "$([ ! -e flake.nix ] && [ ! -e .envrc ] && [ ! -e devshell.json ] && echo yes)"

  mkdir -p "$root/o" && cd "$root/o" && git init -q .
  dev attach rust >/dev/null 2>&1 || true
  t_check "attach writes only .envrc" "yes" "$([ -f .envrc ] && [ ! -e flake.nix ] && [ ! -e devshell.json ] && echo yes)"
  t_check "  ...points out of tree" "$root/cache/dev/rust" "$(sed -n 's|^use flake ||p' .envrc)"
  t_check "  ...carries DEV_LANGS" 'export DEV_LANGS="rust"' "$(head -1 .envrc)"
  t_check "  ...git-excluded, not staged" "yes" "$(grep -qx '.envrc' .git/info/exclude && [ -z "$(git status --porcelain)" ] && echo yes)"
  dev attach go >/dev/null 2>&1 || true
  t_check "attach refuses over existing .envrc" "$root/cache/dev/rust" "$(sed -n 's|^use flake ||p' .envrc)"
  dev attach go -f >/dev/null 2>&1 || true
  t_check "attach -f replaces it" "$root/cache/dev/go" "$(sed -n 's|^use flake ||p' .envrc)"
  t_check "  ...exclude not duplicated" "1" "$(grep -cx '.envrc' .git/info/exclude)"
  t_check "attach poly rejected" "1" "$(dev attach poly >/dev/null 2>&1; echo $?)"

  mkdir -p "$root/p" && cd "$root/p" && git init -q .
  dev attach go python >/dev/null 2>&1 || true
  t_check "attach poly points at shared dir" "$root/cache/dev/poly-go-python" "$(sed -n 's|^use flake ||p' .envrc)"
  t_check "  ...carries both langs" 'export DEV_LANGS="go python"' "$(head -1 .envrc)"

  t_check "shell with no args rejected" "1" "$(dev shell >/dev/null 2>&1; echo $?)"
  t_check "shell poly rejected" "1" "$(dev shell poly >/dev/null 2>&1; echo $?)"
  t_check "shell unknown language rejected" "1" "$(dev shell haskell >/dev/null 2>&1; echo $?)"
  unset XDG_CACHE_HOME

  printf '\n%slegacy%s\n' "$B" "$R"
  mkdir -p "$root/l" && cd "$root/l"
  printf '{\n  enabled = [ "go" "rust" ];\n}\n' >flake.nix
  t_check "legacy inline flake detected" "1" "$(dev add python >/dev/null 2>&1; echo $?)"

  cd "$here"
  printf '\n'
  if [ "$T_FAIL" -eq 0 ]; then
    say "$T_PASS passed, 0 failed"
  else
    say "$T_PASS passed, ${A}$T_FAIL failed${R}"
    return 1
  fi
}

usage() {
  printf '%susage%s dev <command> [args]\n\n' "$B" "$R"
  printf '  %-22s available shells, %s*%s marks active\n' "list" "$A" "$R"
  printf '  %-22s active shell, direnv state, toolchain\n' "which"
  printf '  %-22s diagnose why tooling is not working\n' "doctor"
  printf '\n'
  printf '  %-22s enter a shell without writing anything here\n' "shell <lang>..."
  printf '  %-22s persistent shell here, nothing committable added\n' "attach <lang>..."
  printf '  %-22s scaffold flake.nix + .envrc here\n' "init <lang>..."
  printf '  %-22s add .envrc to a flake.nix you already have\n' "adopt"
  printf '  %-22s replace this directory'\''s shell\n' "switch <lang>..."
  printf '  %-22s add a language to a poly shell\n' "add <lang>..."
  printf '  %-22s remove a language from a poly shell\n' "rm <lang>..."
  printf '  %-22s add/rm/list extra nixpkgs packages\n' "pkg <add|rm|list>"
  printf '\n'
  printf '  %-22s trust this directory'\''s .envrc\n' "allow"
  printf '  %-22s update this directory'\''s flake inputs\n' "update"
  printf '\n'
  printf '%sflags%s  -f, --force   skip the replace confirmation\n' "$D" "$R"
  printf '       --fresh       discard flake.lock on switch\n'
}

main() {
  local cmd=${1:-which}
  [ $# -gt 0 ] && shift
  case $cmd in
    list | ls) cmd_list "$@" ;;
    which | status | st) cmd_which "$@" ;;
    doctor | check) cmd_doctor "$@" ;;
    init | new) cmd_init "$@" ;;
    shell) cmd_shell "$@" ;;
    attach) cmd_attach "$@" ;;
    adopt) cmd_adopt "$@" ;;
    switch | use) cmd_switch "$@" ;;
    add) cmd_add "$@" ;;
    pkg | pkgs) cmd_pkg "$@" ;;
    rm | remove) cmd_rm "$@" ;;
    allow | trust) cmd_allow "$@" ;;
    update) cmd_update "$@" ;;
    selftest) cmd_selftest "$@" ;;
    help | -h | --help) usage ;;
    *) die "unknown command '$cmd'; try: dev help" ;;
  esac
}

main "$@"
