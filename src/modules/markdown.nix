{
  basecamp,
  pkgs,
  config,
  ...
}:
let
  inherit (basecamp.lib) mkEnableOptionDefaultTrue;
  inherit (pkgs) lib writeShellApplication;
  inherit (lib) mkIf getExe;
  cfg = config.markdown;
  fd = getExe pkgs.fd;
  prettier = getExe config.prettier.package;
in
{
  options.markdown = {
    enable = mkEnableOptionDefaultTrue "Markdown module";
    recipes.fmt.enable = mkEnableOptionDefaultTrue "`fmt-markdown` command";
    recipes.check-fmt.enable = mkEnableOptionDefaultTrue "`check-fmt-markdown` command";
  };

  config = mkIf cfg.enable {
    namedPackages.check-fmt-markdown = mkIf cfg.recipes.check-fmt.enable (writeShellApplication {
      name = "check-fmt-markdown";
      text = ''
        set -x
        ${fd} --extension=md --exec-batch ${prettier} --check
      '';
    });

    namedPackages.fmt-markdown = mkIf cfg.recipes.fmt.enable (writeShellApplication {
      name = "fmt-markdown";
      text = ''
        set -x
        ${fd} --extension=md --exec-batch ${prettier} --write
      '';
    });
  };
}
