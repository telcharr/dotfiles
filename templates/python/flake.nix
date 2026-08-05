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
          DEVSHELL = "python";
          packages = with pkgs; [
            python313
            uv
            ruff
            basedpyright
          ];
          shellHook = ''
            export UV_PYTHON="${pkgs.python313}/bin/python3.13"
            export UV_PYTHON_DOWNLOADS=never
          '';
        };
      }
    );
}
