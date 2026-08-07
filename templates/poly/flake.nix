{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        spec = builtins.fromJSON (builtins.readFile ./devshell.json);
        enabled = spec.languages or [ ];
        extra = spec.packages or [ ];

        toolchains = {
          rust = with pkgs; [
            rustc
            cargo
            rust-analyzer
            clippy
            rustfmt
            pkg-config
            openssl
          ];
          go = with pkgs; [
            go
            gopls
            gotools
            delve
            golangci-lint
          ];
          python = with pkgs; [
            python313
            uv
            ruff
            basedpyright
          ];
          cpp = with pkgs; [
            clang-tools
            cmake
            ninja
            gdb
          ];
          lua = with pkgs; [
            luajit
            lua-language-server
            stylua
            selene
          ];
          node = with pkgs; [
            nodejs
            typescript-language-server
            biome
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          DEVSHELL = "poly";
          packages = builtins.concatMap (n: toolchains.${n}) enabled ++ map (n: pkgs.${n}) extra;
        };
      }
    );
}
