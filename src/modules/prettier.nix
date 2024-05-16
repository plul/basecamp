{
  basecamp,
  pkgs,
  config,
  ...
}:
let
  inherit (basecamp.lib) mkPackageOption;
  inherit (pkgs) lib;
  inherit (lib) mkIf mkEnableOption;
  cfg = config.prettier;
in
{
  options.prettier = {
    enable = mkEnableOption "prettier";
    package = mkPackageOption pkgs.nodePackages.prettier;
  };

  config = mkIf cfg.enable { packages = [ cfg.prettier.package ]; };
}
