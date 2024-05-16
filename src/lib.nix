pkgs:

let
  inherit (pkgs) lib;
  inherit (lib) mkOption types;
in
{
  mkEnableOptionDefaultTrue =
    description:
    mkOption {
      description = "Whether to enable " + description;
      type = types.bool;
      default = true;
    };
  mkPackageOption =
    default:
    mkOption {
      description = "The package to use.";
      type = types.package;
      inherit default;
    };
}
