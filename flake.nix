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
      # Root module for components (tree of NixOS modules)
      components =
        { ... }:
        {
          imports = [
            ./src/components/just.nix
            ./src/components/markdown.nix
            ./src/components/mk-shell.nix
            ./src/components/nickel.nix
            ./src/components/nix.nix
            ./src/components/prettier.nix
            ./src/components/rust.nix
            ./src/components/toml.nix
          ];
        };

      overlays.default = _final: prev: {
        basecamp = rec {
          mkEnableOptionDefaultTrue = description: prev.lib.mkEnableOption description // { default = true; };

          mkFmtOption = {
            enable = mkEnableOptionDefaultTrue "formatting of files";
            package = prev.lib.mkOption {
              description = "Package to execute to format files";
              type = prev.lib.types.package;
            };
          };

          mkCheckFmtOption = {
            enable = mkEnableOptionDefaultTrue "check of correct formatting";
            package = prev.lib.mkOption {
              description = "Package to execute to check correct formatting";
              type = prev.lib.types.package;
            };
          };

          mkLintOption = {
            enable = mkEnableOptionDefaultTrue "linting";
            package = prev.lib.mkOption {
              description = "Package to execute to perform linting";
              type = prev.lib.types.package;
            };
          };

          writeJustfile =
            {
              name ? "justfile",
              recipes,
              ...
            }:
            let
              indentLines =
                text: builtins.concatStringsSep "\n" (map (line: "    " + line) (prev.lib.splitString "\n" text));

              # Convert the recipes attribute set into justfile content
              justfileRecipes = prev.lib.mapAttrsToList (recipe_name: text: ''
                ${recipe_name}:
                ${indentLines text}
              '') recipes;
              justfileRecipesTrimmed = prev.lib.lists.forEach justfileRecipes prev.lib.strings.trim;
              justfileContent = builtins.concatStringsSep "\n\n" justfileRecipesTrimmed;
            in
            prev.writeText name justfileContent;
        };
      };

      appendOverlays =
        pkgs:
        pkgs.appendOverlays [
          self.overlays.default
          (import rust-overlay)
        ];

      eval = {
        components =
          {
            pkgs,
            config ? { },
          }:
          let
            p = self.appendOverlays pkgs;
          in
          p.lib.evalModules {
            specialArgs.pkgs = p;
            modules = [
              self.components
              { inherit config; }
            ];
          };
      };

      mkShell = pkgs: config: (self.eval.components { inherit pkgs config; }).config.shell;

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
          default = self.mkShell pkgs { packages = [ pkgs.watchexec ]; };
        };
    };
}
