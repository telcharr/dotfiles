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
        inherit (pkgs) llvmPackages_21;
      in
      {
        devShells.default = (pkgs.mkShell.override { inherit (llvmPackages_21) stdenv; }) {
          DEVSHELL = "cpp";
          packages =
            (with llvmPackages_21; [
              clang-tools
              lldb
            ])
            ++ (with pkgs; [
              cmake
              ninja
              meson
              pkg-config
              gdb
              valgrind
              ccache
              gtest
              catch2_3
            ]);
          shellHook = "export CMAKE_EXPORT_COMPILE_COMMANDS=ON";
        };
      }
    );
}
