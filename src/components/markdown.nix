{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (pkgs) writeShellApplication;
  inherit (pkgs.basecamp) mkEnableOptionDefaultTrue mkFmtOption mkCheckFmtOption;
  cfg = config.markdown;
  fd = getExe pkgs.fd;
  prettier = getExe config.prettier.package;
in
{
  options.markdown = {
    enable = mkEnableOptionDefaultTrue "Markdown module";

    fmt = mkFmtOption;

    checks = {
      enable = mkEnableOptionDefaultTrue "checks";
      fmt = mkCheckFmtOption;
    };
  };

  config = mkIf cfg.enable {
    markdown.fmt.package = writeShellApplication {
      name = "basecamp-markdown-fmt";
      text = ''
        set -x
        ${fd} --extension=md --exec-batch ${prettier} --write
      '';
    };

    markdown.checks.fmt.package = writeShellApplication {
      name = "basecamp-markdown-checks-fmt";
      text = ''
        set -x
        ${fd} --extension=md --exec-batch ${prettier} --check
      '';
    };
  };
}
