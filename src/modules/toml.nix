{
  basecamp,
  pkgs,
  config,
  ...
}:
let
  inherit (basecamp.lib) mkPackageOption mkEnableOptionDefaultTrue;
  inherit (pkgs) lib writeShellApplication;
  inherit (lib) mkIf mkEnableOption;
  cfg = config.toml;
in
{
  options.toml = {
    enable = mkEnableOption "Enable TOML module";
    taplo = {
      enable = mkEnableOptionDefaultTrue "Enable taplo.";
      package = mkPackageOption pkgs.taplo;
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      (mkIf cfg.taplo.enable {
        packages.taplo = cfg.taplo.package;

        packages.lint-toml = writeShellApplication {
          name = "lint-toml";
          runtimeInputs = [
            cfg.taplo.package
            pkgs.fd
          ];
          text = ''
            set -x
            fd --extension=toml --exec-batch taplo lint
          '';
        };

        packages.check-fmt-toml = writeShellApplication {
          name = "check-fmt-toml";
          runtimeInputs = [
            cfg.taplo.package
            pkgs.fd
          ];
          text = ''
            set -x
            fd --extension=toml --exec-batch taplo fmt --check
          '';
        };

        packages.fmt-toml = writeShellApplication {
          name = "fmt-toml";
          runtimeInputs = [
            cfg.taplo.package
            pkgs.fd
          ];
          text = ''
            set -x
            fd --extension=toml --exec-batch taplo fmt
          '';
        };
      })
    ]
  );
}
