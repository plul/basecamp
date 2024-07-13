{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    mkEnableOption
    mkDefault
    mkIf
    mkPackageOption
    optionals
    ;
  inherit (pkgs) writeShellApplication;
  inherit (pkgs.basecamp)
    mkEnableOptionDefaultTrue
    mkFmtOption
    mkCheckFmtOption
    mkLintOption
    ;
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

    fmt = mkFmtOption;

    checks = {
      enable = mkEnableOptionDefaultTrue "checks";
      fmt = mkCheckFmtOption;
      lint = mkLintOption;
    };
  };

  config = mkIf cfg.enable {
    packages = [ ] ++ optionals cfg.taplo.enable [ cfg.taplo.package ];

    toml.fmt.package = mkIf cfg.fmt.enable (
      mkDefault (writeShellApplication {
        name = "basecamp-toml-fmt";
        text = ''
          set -x
          ${fd} --extension=toml --exec-batch ${taplo} fmt
        '';
      })
    );

    toml.checks = mkIf cfg.checks.enable {
      fmt.package = mkIf cfg.checks.fmt.enable (
        mkDefault (writeShellApplication {
          name = "basecamp-toml-checks-fmt";
          text = ''
            set -x
            ${fd} --extension=toml --exec-batch ${taplo} fmt --check
          '';
        })
      );

      lint.package = mkIf cfg.checks.lint.enable (
        mkDefault (writeShellApplication {
          name = "basecamp-toml-checks-lint";
          text = ''
            set -x
            ${fd} --extension=toml --exec-batch ${taplo} lint
          '';
        })
      );
    };
  };
}
