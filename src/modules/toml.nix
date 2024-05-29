{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    mkIf
    mkEnableOption
    optionals
    mkPackageOption
    ;
  inherit (pkgs) writeShellApplication;
  inherit (pkgs.basecamp) mkEnableOptionDefaultTrue;
  cfg = config.toml;
  fd = getExe pkgs.fd;
  taplo = getExe cfg.taplo.package;
in
{
  options.toml = {
    enable = mkEnableOption "TOML module";
    taplo = {
      enable = mkEnableOptionDefaultTrue "taplo";
      package = mkPackageOption pkgs "taplo" { };
    };
    recipes.fmt.enable = mkEnableOptionDefaultTrue "`fmt-toml` command";
    recipes.check-fmt.enable = mkEnableOptionDefaultTrue "`check-fmt-toml` command";
    recipes.lint.enable = mkEnableOptionDefaultTrue "`lint-toml` command";
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      (mkIf cfg.taplo.enable {
        packages = [ ] ++ optionals cfg.taplo.enable [ cfg.taplo.package ];

        namedPackages.lint-toml = mkIf cfg.recipes.lint.enable (writeShellApplication {
          name = "lint-toml";
          text = ''
            set -x
            ${fd} --extension=toml --exec-batch ${taplo} lint
          '';
        });

        namedPackages.check-fmt-toml = mkIf cfg.recipes.check-fmt.enable (writeShellApplication {
          name = "check-fmt-toml";
          text = ''
            set -x
            ${fd} --extension=toml --exec-batch ${taplo} fmt --check
          '';
        });

        namedPackages.fmt-toml = mkIf cfg.recipes.fmt.enable (writeShellApplication {
          name = "fmt-toml";
          text = ''
            set -x
            ${fd} --extension=toml --exec-batch ${taplo} fmt
          '';
        });
      })
    ]
  );
}
