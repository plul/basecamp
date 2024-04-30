{
  basecampLib,
  pkgs,
  config,
  ...
}:
let
  inherit (basecampLib) mkPackageOption;
  inherit (pkgs) lib writeShellApplication writeShellScriptBin;
  inherit (lib)
    types
    mkIf
    mkOption
    mkEnableOption
    ;
  cfg = config.just;
in
{
  options.just = {
    enable = mkEnableOption "Enable just (justfile) module";
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
