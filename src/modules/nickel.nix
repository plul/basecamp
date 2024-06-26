{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    optionals
    getExe
    mkEnableOption
    mkPackageOption
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
    recipes.fmt.enable = mkEnableOptionDefaultTrue "`fmt-nickel` command";
  };

  config = mkIf cfg.enable {
    packages = [ cfg.package ] ++ optionals cfg.languageServer.enable [ cfg.languageServer.package ];

    namedPackages.fmt-nickel = mkIf cfg.recipes.fmt.enable (writeShellApplication {
      name = "fmt-nickel";
      text = ''
        set -x
        ${fd} --extension=ncl --exec-batch ${nickel} format
      '';
    });
  };
}
