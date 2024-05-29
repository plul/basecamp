{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe mkPackageOption;
  inherit (pkgs) writeShellApplication;
  inherit (pkgs.basecamp) mkEnableOptionDefaultTrue;
  cfg = config.just;
in
{
  options.just = {
    enable = mkEnableOptionDefaultTrue "just (justfile) module";
    package = mkPackageOption pkgs "just" { };
    recipes.fmt.enable = mkEnableOptionDefaultTrue "`fmt-just` command";
    recipes.check-fmt.enable = mkEnableOptionDefaultTrue "`check-fmt-just` command";
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    namedPackages.check-fmt-just = mkIf cfg.recipes.check-fmt.enable (writeShellApplication {
      name = "check-fmt-just";
      text = ''
        set -x
        ${getExe cfg.package} --unstable --fmt --check
      '';
    });

    namedPackages.fmt-just = mkIf cfg.recipes.fmt.enable (writeShellApplication {
      name = "fmt-just";
      text = ''
        set -x
        ${getExe cfg.package} --unstable --fmt
      '';
    });
  };
}
