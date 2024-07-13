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
    mkIf
    mkOption
    mkPackageOption
    optionals
    types
    ;
  inherit (pkgs) writeShellApplication;
  inherit (pkgs.basecamp) mkEnableOptionDefaultTrue;
  cfg = config.nickel;
  fd = getExe pkgs.fd;
  nickel = getExe cfg.package;
in
{
  options.nickel = {
    enable = mkEnableOption "nickel module";
    package = mkPackageOption pkgs "nickel" { };
    languageServer = {
      enable = mkEnableOptionDefaultTrue "language server for Nickel";
      package = mkPackageOption pkgs "nls" { };
    };

    fmt.enable = mkEnableOptionDefaultTrue "formatting of files";
    fmt.package = mkOption {
      description = "Package to execute to format files";
      type = types.package;
    };
  };

  config = mkIf cfg.enable {
    nickel = {
      fmt.package = mkIf cfg.fmt.enable (writeShellApplication {
        name = "basecamp-nickel-fmt";
        text = ''
          set -x
          ${fd} --extension=ncl --exec-batch ${nickel} format
        '';
      });
    };
    packages = [ cfg.package ] ++ optionals cfg.languageServer.enable [ cfg.languageServer.package ];
  };
}
