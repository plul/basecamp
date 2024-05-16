{
  basecamp,
  pkgs,
  config,
  ...
}:
let
  inherit (basecamp.lib) mkPackageOption mkEnableOptionDefaultTrue;
  inherit (pkgs) lib writeShellApplication;
  inherit (lib) mkIf getExe;
  cfg = config.just;
  just = getExe cfg.package;
in
{
  options.just = {
    enable = mkEnableOptionDefaultTrue "just (justfile) module";
    package = mkPackageOption pkgs.just;
    recipes.fmt.enable = mkEnableOptionDefaultTrue "`fmt-just` command";
    recipes.check-fmt.enable = mkEnableOptionDefaultTrue "`check-fmt-just` command";
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ];

    namedPackages.check-fmt-just = mkIf cfg.recipes.check-fmt.enable (writeShellApplication {
      name = "check-fmt-just";
      text = ''
        set -x
        ${just} --unstable --fmt --check
      '';
    });

    namedPackages.fmt-just = mkIf cfg.recipes.fmt.enable (writeShellApplication {
      name = "fmt-just";
      text = ''
        set -x
        ${just} --unstable --fmt
      '';
    });
  };
}
