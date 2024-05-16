{
  basecamp,
  pkgs,
  config,
  ...
}:
let
  inherit (basecamp.lib) mkPackageOption mkEnableOptionDefaultTrue;
  inherit (pkgs) lib writeShellApplication;
  inherit (lib) mkIf getExe mkEnableOption;
  cfg = config.nix;
  fd = getExe pkgs.fd;
  nixfmt = getExe cfg.nixfmt.package;
in
{
  options.nix = {
    enable = mkEnableOptionDefaultTrue "nix module";
    nixfmt = {
      enable = mkEnableOption "nixfmt formatter";
      package = mkPackageOption pkgs.nixfmt-rfc-style;
    };
    recipes.fmt.enable = mkEnableOptionDefaultTrue "`fmt-nix` command";
    recipes.check-fmt.enable = mkEnableOptionDefaultTrue "`check-fmt-nix` command";
  };

  config = mkIf cfg.enable {
    packages = mkIf cfg.nixfmt.enable [ cfg.nixfmt.package ];

    namedPackages.check-fmt-nix = mkIf cfg.recipes.check-fmt.enable (writeShellApplication {
      name = "check-fmt-nix";
      text = ''
        set -x
        ${fd} --extension=nix --exec-batch ${nixfmt} --check
      '';
    });

    namedPackages.fmt-nix = mkIf cfg.recipes.fmt.enable (writeShellApplication {
      name = "fmt-nix";
      text = ''
        set -x
        ${fd} --extension=nix --exec-batch ${nixfmt}
      '';
    });
  };
}
