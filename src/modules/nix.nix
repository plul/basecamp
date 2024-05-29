{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    mkPackageOption
    optionalString
    ;
  inherit (pkgs) writeShellApplication;
  inherit (pkgs.basecamp) mkEnableOptionDefaultTrue;
  cfg = config.nix;
in
{
  options.nix = {
    enable = mkEnableOptionDefaultTrue "nix module";
    nixfmt = {
      enable = mkEnableOptionDefaultTrue "nixfmt formatter";
      package = mkPackageOption pkgs "nixfmt-rfc-style" { };
    };
    nixpkgs-lint = {
      enable = mkEnableOptionDefaultTrue "nixpkgs-lint linter";
      package = mkPackageOption pkgs "nixpkgs-lint-community" { };
    };
    deadnix = {
      enable = mkEnableOptionDefaultTrue "deadnix linter";
      package = mkPackageOption pkgs "deadnix" { };
      noUnderscore = mkEnableOptionDefaultTrue "--no-underscore option (Don't check any bindings that start with a _)";
    };
    recipes.fmt.enable = mkEnableOptionDefaultTrue "`fmt-nix` command";
    recipes.check-fmt.enable = mkEnableOptionDefaultTrue "`check-fmt-nix` command";
    recipes.lint.enable = mkEnableOptionDefaultTrue "`lint-nix` command";
  };

  config =
    let
      fd = getExe pkgs.fd;
      nixfmt = getExe cfg.nixfmt.package;
      nixpkgs-lint = getExe cfg.nixpkgs-lint.package;
      deadnix = getExe cfg.deadnix.package;
    in
    mkIf cfg.enable {
      packages = mkIf cfg.nixfmt.enable [ cfg.nixfmt.package ];

      namedPackages.check-fmt-nix = mkIf cfg.recipes.check-fmt.enable (writeShellApplication {
        name = "check-fmt-nix";
        text = ''
          set -x
          ${fd} --extension=nix --exec-batch ${nixfmt} --check
        '';
      });

      namedPackages.fmt-nix = mkIf cfg.recipes.fmt.enable (writeShellApplication {
        name = "fmt-nix";
        text = ''
          set -x
          ${fd} --extension=nix --exec-batch ${nixfmt}
        '';
      });

      namedPackages.lint-nix = mkIf cfg.recipes.lint.enable (writeShellApplication {
        name = "lint-nix";
        text = ''
          set -x

          ${optionalString (cfg.nixpkgs-lint.enable) ''
            ${fd} --extension=nix --exec-batch ${nixpkgs-lint}
          ''}

          ${optionalString (cfg.deadnix.enable) ''
            ${fd} --extension=nix --exec-batch ${deadnix} --fail --no-underscore
          ''}
        '';
      });
    };
}
