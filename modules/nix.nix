{
  basecampLib,
  pkgs,
  config,
  ...
}:
let
  inherit (basecampLib) mkPackageOption mkEnableOptionDefaultTrue;
  inherit (pkgs) lib writeShellApplication writeShellScriptBin;
  inherit (lib)
    types
    mkIf
    mkOption
    mkEnableOption
    ;
  cfg = config.nix;
in
{
  options.nix = {
    enable = mkEnableOption "Enable nix module";
    nixfmt = {
      enable = mkEnableOptionDefaultTrue "Enable nixfmt";
      package = mkPackageOption pkgs.nixfmt-rfc-style;
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      (mkIf cfg.nixfmt.enable {
        packages.nixfmt = cfg.nixfmt.package;

        packages.check-fmt-nix = writeShellApplication {
          name = "check-fmt-nix";
          runtimeInputs = [
            cfg.nixfmt.package
            pkgs.fd
          ];
          text = ''
            set -x
            fd --extension=nix --exec-batch nixfmt --check
          '';
        };

        packages.fmt-nix = writeShellApplication {
          name = "fmt-nix";
          runtimeInputs = [
            cfg.nixfmt.package
            pkgs.fd
          ];
          text = ''
            set -x
            fd --extension=nix --exec-batch nixfmt
          '';
        };
      })
    ]
  );
}
