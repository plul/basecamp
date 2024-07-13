{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    mkDefault
    mkIf
    mkPackageOption
    optionalString
    ;
  inherit (pkgs) writeShellApplication;
  inherit (pkgs.basecamp)
    mkEnableOptionDefaultTrue
    mkFmtOption
    mkCheckFmtOption
    mkLintOption
    ;
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

    fmt = mkFmtOption;

    checks = {
      enable = mkEnableOptionDefaultTrue "checks";
      fmt = mkCheckFmtOption;
      lint = mkLintOption;
    };
  };

  config =
    let
      fd = getExe pkgs.fd;
      nixfmt = getExe cfg.nixfmt.package;
      nixpkgs-lint = getExe cfg.nixpkgs-lint.package;
      deadnix = getExe cfg.deadnix.package;
    in
    mkIf cfg.enable {
      nix = {
        fmt.package = mkIf cfg.fmt.enable (
          mkDefault (writeShellApplication {
            name = "basecamp-nix-fmt";
            text = ''
              set -x
              ${fd} --extension=nix --exec-batch ${nixfmt}
            '';
          })
        );

        checks = mkIf cfg.checks.enable {
          fmt.package = mkIf cfg.checks.fmt.enable (
            mkDefault (writeShellApplication {
              name = "basecamp-nix-checks-fmt";
              text = ''
                set -x
                ${fd} --extension=nix --exec-batch ${nixfmt} --check
              '';
            })
          );

          lint.package = mkIf cfg.checks.lint.enable (
            mkDefault (writeShellApplication {
              name = "basecamp-nix-checks-lint";
              text = ''
                set -x

                ${optionalString (cfg.nixpkgs-lint.enable) ''
                  ${fd} --extension=nix --exec-batch ${nixpkgs-lint}
                ''}

                ${optionalString (cfg.deadnix.enable) ''
                  ${fd} --extension=nix --exec-batch ${deadnix} --fail --no-underscore
                ''}
              '';
            })
          );
        };
      };
    };
}
