{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      ...
    }:
    {
      # Modules using the NixOS module system.
      rootModule =
        { ... }:
        {
          imports = [
            ./src/modules/just.nix
            ./src/modules/markdown.nix
            ./src/modules/mk-shell.nix
            ./src/modules/nickel.nix
            ./src/modules/nix.nix
            ./src/modules/prettier.nix
            ./src/modules/recipes.nix
            ./src/modules/rust.nix
            ./src/modules/toml.nix
          ];
        };

      overlays.default = _final: prev: {
        basecamp = {
          mkEnableOptionDefaultTrue = description: prev.lib.mkEnableOption description // { default = true; };
        };
      };

      # Evaluate basecamp config.
      eval =
        {
          pkgs,
          config ? { },
        }:
        let
          p = pkgs.appendOverlays [
            self.overlays.default
            (import rust-overlay)
          ];
        in
        p.lib.evalModules {
          specialArgs.pkgs = p;
          modules = [
            self.rootModule
            { inherit config; }
          ];
        };

      # Evaluate basecamp config, and return just the package set as a list.
      evalPackages =
        evalArgs:
        let
          config = (self.eval evalArgs).config;
        in
        config.packages ++ (builtins.attrValues config.namedPackages);

      # mkShell but with (opinionated) NixOS modules
      mkShell =
        {
          pkgs,
          config ? { },
          packages ? _pkgs: [ ],
        }:
        let
          basecampPackages = self.evalPackages { inherit pkgs config; };
        in
        pkgs.mkShell { packages = basecampPackages ++ (packages pkgs); };

      packages."x86_64-linux" =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          docs = import ./src/docs.nix { inherit self pkgs; };
          templates = import ./src/templates.nix { inherit self pkgs; };
        in
        {
          inherit (docs) options-markdown docs;
          inherit (templates) template-rust;
        };

      apps."x86_64-linux".template-rust = {
        type = "app";
        program = "${self.packages."x86_64-linux".template-rust}/bin/bc-template-rust";
      };

      devShells."x86_64-linux" =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        {
          default = self.mkShell {
            inherit pkgs;
            packages = pkgs: [ pkgs.watchexec ];
          };
        };
    };
}
