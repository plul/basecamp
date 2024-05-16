{
  basecamp,
  pkgs,
  config,
  ...
}:
let
  inherit (basecamp.lib) mkPackageOption mkEnableOptionDefaultTrue;
  inherit (pkgs) lib writeShellApplication;
  inherit (lib) mkIf;
  cfg = config.just;
in
{
  options.just = {
    enable = mkEnableOptionDefaultTrue "just (justfile) module";
    package = mkPackageOption pkgs.just;
  };

  config = mkIf cfg.enable {
    packages.just = cfg.package;
    packages.check-fmt-just = writeShellApplication {
      name = "check-fmt-just";
      runtimeInputs = [ cfg.package ];
      text = ''
        set -x
        just --unstable --fmt --check
      '';
    };
    packages.fmt-just = writeShellApplication {
      name = "fmt-just";
      runtimeInputs = [ cfg.package ];
      text = ''
        set -x
        just --unstable --fmt
      '';
    };
  };
}
