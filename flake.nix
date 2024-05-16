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
        { pkgs, config, ... }:
        {
          imports = [
            ./src/modules/just.nix
            ./src/modules/markdown.nix
            ./src/modules/mk-shell.nix
            ./src/modules/nickel.nix
            ./src/modules/nix.nix
            ./src/modules/rust.nix
            ./src/modules/toml.nix
            ./src/modules/prettier.nix
          ];
        };

      lib = import ./src/lib.nix;

      # Evaluate basecamp config.
      eval =
        {
          pkgs,
          config ? { },
        }:
        let
          p = pkgs.appendOverlays [ (import rust-overlay) ];
        in
        p.lib.evalModules {
          specialArgs.pkgs = p;
          specialArgs.basecamp.lib = self.lib p;
          modules = [
            self.rootModule
            { inherit config; }
          ];
        };

      # Evaluate basecamp config, and return just the package set.
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
          packages ? pkgs: [ ],
        }:
        let
          basecampPackages = self.evalPackages { inherit pkgs config; };
        in
        pkgs.mkShell { packages = basecampPackages ++ (packages pkgs); };

      packages."x86_64-linux" =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          docs = import ./src/docs.nix { inherit self pkgs; };
        in
        {
          inherit (docs) options-markdown docs;
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
