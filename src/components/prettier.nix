{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkPackageOption;
  cfg = config.prettier;
in
{
  options.prettier = {
    enable = mkEnableOption "prettier";
    package = mkPackageOption pkgs [
      "nodePackages"
      "prettier"
    ] { };
  };

  config = mkIf cfg.enable { packages = [ cfg.prettier.package ]; };
}
