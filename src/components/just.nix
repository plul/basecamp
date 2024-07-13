{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    mkPackageOption
    mkOption
    types
    ;
  inherit (pkgs) writeShellApplication;
  inherit (pkgs.basecamp) mkEnableOptionDefaultTrue;
  cfg = config.just;
in
{
  options.just = {
    enable = mkEnableOptionDefaultTrue "just (justfile) module";
    package = mkPackageOption pkgs "just" { };

    fmt.enable = mkEnableOptionDefaultTrue "formatting of files";
    fmt.package = mkOption {
      description = "Package to execute to format files";
      type = types.package;
      default = writeShellApplication {
        name = "basecamp-just-fmt";
        text = ''
          set -x
          ${getExe cfg.package} --unstable --fmt
        '';
      };
    };

    checks = {
      enable = mkEnableOptionDefaultTrue "checks";

      fmt.enable = mkEnableOptionDefaultTrue "check of correct formatting";
      fmt.package = mkOption {
        description = "Package to execute to check correct formatting";
        type = types.package;
        default = writeShellApplication {
          name = "basecamp-just-check-fmt";
          text = ''
            set -x
            ${getExe cfg.package} --unstable --fmt --check
          '';
        };
      };
    };
  };
}
