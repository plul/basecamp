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
      # Modules using the NixOS module system
      rootModule = {
        imports = [
          ./modules/just.nix
          ./modules/markdown.nix
          ./modules/mk-shell.nix
          ./modules/nix.nix
          ./modules/rust.nix
          ./modules/toml.nix
        ];
      };

      lib =
        pkgs:
        let
          inherit (pkgs) lib;
          inherit (lib) mkOption types;
        in
        {
          mkEnableOptionDefaultTrue =
            description:
            mkOption {
              inherit description;
              type = types.bool;
              default = true;
            };
          mkPackageOption =
            default:
            mkOption {
              description = "The package to use.";
              type = types.package;
              inherit default;
            };
          rust = import ./lib/rust.nix;
        };

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
          specialArgs.basecampLib = self.lib p;
          modules = [
            self.rootModule
            { inherit config; }
          ];
        };

      # Evaluate basecamp config, and return just the package set.
      evalPackages = args: (self.eval args).config.packages;

      # mkShell but with NixOS modules
      mkDevShell =
        {
          pkgs,
          config ? { },
          packages ? pkgs: [ ],
        }:
        let
          basecampPackages = self.evalPackages { inherit pkgs config; };
        in
        pkgs.mkShell { packages = builtins.attrValues basecampPackages ++ (packages pkgs); };

      devShells."x86_64-linux".default = self.mkDevShell {
        pkgs = import nixpkgs { system = "x86_64-linux"; };

        config = {
          # TODO: remove
          just.enable = true;
          markdown.enable = true;
          nix.enable = true;
          rust.enable = true;
          rust.rust-analyzer.nightly = true;
          rust.cargo-udeps.enable = true;
        };

        packages = pkgs: [
          pkgs.fd
          pkgs.just
          pkgs.nodePackages.prettier
          pkgs.nixfmt-rfc-style
          pkgs.watchexec
        ];
      };
    };
}
