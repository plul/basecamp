{ pkgs, config, ... }:
let
  inherit (pkgs) lib;
  inherit (lib) mkIf mkEnableOption mkPackageOptionDefault;
  cfg = config.prettier;
in
{
  options.prettier = {
    enable = mkEnableOption "prettier";
    package = mkPackageOptionDefault pkgs.nodePackages.prettier;
  };

  config = mkIf cfg.enable { packages = [ cfg.prettier.package ]; };
}
