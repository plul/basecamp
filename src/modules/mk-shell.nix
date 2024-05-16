# Options suitable for forwarding to mkShell
{ config, pkgs, ... }:
let
  inherit (pkgs) lib;
  inherit (lib) mkOption types;
in
{
  options = {
    packages = mkOption {
      description = "Exported packages. These are included in shells created with `basecamp.mkShell`";
      type = types.listOf types.package;
      default = [ ];
    };

    namedPackages = mkOption {
      description = "Exported packages. These are included in shells created with `basecamp.mkShell`";
      type = types.attrsOf types.package;
      default = { };
      example = {
        foo = pkgs.writeShellScriptBin ''
          echo hello world;
        '';
      };
    };
  };

  config = {
    namedPackages.basecamp-list-packages =
      let
        package_names = lib.attrNames config.namedPackages;
        echo_package_names = builtins.map (pname: "echo " + pname) package_names;
        echo_package_list = lib.strings.concatStringsSep "\n" echo_package_names;
      in
      pkgs.writeShellScriptBin "basecamp-list-packages" echo_package_list;
  };
}
