{
  basecamp,
  pkgs,
  config,
  ...
}:
let
  inherit (basecamp.lib) mkPackageOption mkEnableOptionDefaultTrue;
  inherit (pkgs) lib writeShellApplication;
  inherit (lib) mkIf;
  cfg = config.markdown;
in
{
  options.markdown = {
    enable = mkEnableOptionDefaultTrue "Markdown module";
    prettier = {
      enable = mkEnableOptionDefaultTrue "prettier formatter";
      package = mkPackageOption pkgs.nodePackages.prettier;
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      (mkIf cfg.prettier.enable {
        packages.prettier = cfg.prettier.package;

        packages.check-fmt-markdown = writeShellApplication {
          name = "check-fmt-markdown";
          runtimeInputs = [
            cfg.prettier.package
            pkgs.fd
          ];
          text = ''
            set -x
            fd --extension=md --exec-batch prettier --check
          '';
        };

        packages.fmt-markdown = writeShellApplication {
          name = "fmt-markdown";
          runtimeInputs = [
            cfg.prettier.package
            pkgs.fd
          ];
          text = ''
            set -x
            fd --extension=md --exec-batch prettier --write
          '';
        };
      })
    ]
  );
}
