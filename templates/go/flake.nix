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
      in
      {
        devShells.default = pkgs.mkShell {
          DEVSHELL = "go";
          packages = with pkgs; [
            go
            gopls
            gotools
            go-tools
            delve
            golangci-lint
            gotestsum
          ];
          shellHook = ''
            export GOPATH="$PWD/.direnv/go"
            export PATH="$GOPATH/bin:$PATH"
          '';
        };
      }
    );
}
