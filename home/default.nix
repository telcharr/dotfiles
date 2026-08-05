{
  pkgs,
  config,
  user,
  ...
}:
let
  dots = "${config.home.homeDirectory}/dotfiles";
in
{
  imports = [
    ./shell.nix
    ./git.nix
    ./dev.nix
    ./nvim.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "26.05";
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      MANPAGER = "nvim +Man!";
    };
  };

  programs.home-manager.enable = true;

  programs.fuzzel = {
    enable = true;
    package = null;
    settings = {
      main = {
        terminal = "foot";
        font = "CommitMono Nerd Font:size=12";
        layer = "overlay";
        width = 40;
        lines = 10;
        horizontal-pad = 24;
        vertical-pad = 20;
        inner-pad = 10;
        icons-enabled = false;
      };
      colors = {
        background = "0e0e0eff";
        text = "8a8a8aff";
        match = "ff5c00ff";
        selection = "171717ff";
        selection-text = "f0f0f0ff";
        selection-match = "ff5c00ff";
        border = "2a2a2aff";
      };
      border = {
        width = 1;
        radius = 0;
      };
    };
  };

  services.mako = {
    enable = true;
    package = null;
    settings = {
      font = "CommitMono Nerd Font 11";
      background-color = "#0e0e0e";
      text-color = "#d4d4d4";
      border-color = "#2a2a2a";
      border-size = 1;
      border-radius = 0;
      padding = "14";
      margin = "10";
      default-timeout = 5000;
      width = 360;
      "urgency=high" = {
        border-color = "#ff5c00";
        text-color = "#f0f0f0";
      };
    };
  };

  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    just
    gh
    difftastic
    hyperfine
    tokei
    watchexec
    sqlite
    postgresql
    pgcli
    usql
    sqlfluff
    uv
    nixd
    nixfmt
    statix
    deadnix
    yq-go
    jq
    dust
    duf
    procs
    ripgrep
    fd
    neovim
    helix
    btop
    htop
    fastfetch
    yazi
    lazydocker
  ];

  xdg.configFile = {
    "hypr".source = config.lib.file.mkOutOfStoreSymlink "${dots}/raw/hypr";
    "waybar".source = config.lib.file.mkOutOfStoreSymlink "${dots}/raw/waybar";
    "foot".source = config.lib.file.mkOutOfStoreSymlink "${dots}/raw/foot";
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${dots}/raw/nvim";
  };

  gtk = {
    enable = true;
    theme.name = "adw-gtk3-dark";
    iconTheme.name = "Papirus-Dark";
    font = {
      name = "IBM Plex Sans";
      size = 11;
    };
  };

  home.pointerCursor = {
    enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
}
