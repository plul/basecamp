# NixOS module defining options suitable for forwarding to mkShell
{ pkgs, config, ... }:
let
  inherit (pkgs) lib;
  inherit (lib) mkOption types;
in
{
  options.packages = mkOption {
    type = types.attrsOf types.package;
    default = { };
  };
}
