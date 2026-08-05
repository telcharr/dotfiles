{
  description = "portable home";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      rust-overlay,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      user = "telcharr";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ rust-overlay.overlays.default ];
        config.allowUnfree = false;
      };
    in
    {
      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs user; };
        modules = [ ./home ];
      };

      devShells.${system}.default = pkgs.mkShell {
        DEVSHELL = "dotfiles";
        packages = with pkgs; [
          lua-language-server
          stylua
          selene
          nixd
          nixfmt
          statix
          deadnix
        ];
      };

      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust dev shell";
        };
        lua = {
          path = ./templates/lua;
          description = "Lua dev shell";
        };
        node = {
          path = ./templates/node;
          description = "Node/TypeScript dev shell";
        };
        poly = {
          path = ./templates/poly;
          description = "Polyglot dev shell, edit the enabled list";
        };
        go = {
          path = ./templates/go;
          description = "Go dev shell";
        };
        cpp = {
          path = ./templates/cpp;
          description = "C/C++ dev shell";
        };
        python = {
          path = ./templates/python;
          description = "Python dev shell";
        };
      };
    };
}
