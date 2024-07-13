{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    optionals
    optionalString
    getExe
    ;
  inherit (pkgs) writeShellApplication;
  inherit (pkgs.basecamp) mkEnableOptionDefaultTrue;
in
{
  options = {
    packages = mkOption {
      description = "Exported packages.";
      type = types.listOf types.package;
      default = [ ];
    };

    env = mkOption {
      description = "Attribute set of environment variables.";
      type = types.lazyAttrsOf types.str;
      default = { };
      example = {
        FOO = "foo";
      };
    };

    commands = {
      check.enable = mkEnableOptionDefaultTrue "`bc-check` command";
      fmt.enable = mkEnableOptionDefaultTrue "`bc-fmt` command";
    };

    shell = mkOption {
      description = "Dev shell";
      type = types.package;
    };
  };

  config = {
    shell = pkgs.mkShell {
      packages =
        let
          f = condition: package: optionalString condition (getExe package);
        in
        config.packages
        ++ optionals config.commands.check.enable [
          (writeShellApplication {
            name = "bc-check";
            text = ''
              ${f (
                config.just.enable && config.just.checks.enable && config.just.checks.fmt.enable
              ) config.just.checks.fmt.package}
              ${f (
                config.rust.enable && config.rust.checks.enable && config.rust.checks.fmt.enable
              ) config.rust.checks.fmt.package}
              ${f (
                config.toml.enable && config.toml.checks.enable && config.toml.checks.fmt.enable
              ) config.toml.checks.fmt.package}
              ${f (
                config.nix.enable && config.nix.checks.enable && config.nix.checks.fmt.enable
              ) config.nix.checks.fmt.package}
              ${f (
                config.markdown.enable && config.markdown.checks.enable && config.markdown.checks.fmt.enable
              ) config.markdown.checks.fmt.package}
              ${f (
                config.toml.enable && config.toml.checks.enable && config.toml.checks.lint.enable
              ) config.toml.checks.lint.package}
              ${f (
                config.rust.enable && config.rust.checks.enable && config.rust.checks.lint.enable
              ) config.rust.checks.lint.package}
              ${f (
                config.nix.enable && config.nix.checks.enable && config.nix.checks.lint.enable
              ) config.nix.checks.lint.package}
            '';
          })
        ]
        ++ optionals config.commands.fmt.enable [
          (writeShellApplication {
            name = "bc-fmt";
            text = ''
              ${f (config.just.enable && config.just.fmt.enable) config.just.fmt.package}
              ${f (config.rust.enable && config.rust.fmt.enable) config.rust.fmt.package}
              ${f (config.toml.enable && config.toml.fmt.enable) config.toml.fmt.package}
              ${f (config.nickel.enable && config.nickel.fmt.enable) config.nickel.fmt.package}
              ${f (config.nix.enable && config.nix.fmt.enable) config.nix.fmt.package}
              ${f (config.markdown.enable && config.markdown.fmt.enable) config.markdown.fmt.package}
            '';
          })
        ];

      shellHook = ''
        ${pkgs.lib.strings.concatLines (
          pkgs.lib.attrsets.mapAttrsToList (
            name: value: "export ${name}=${pkgs.lib.strings.escapeShellArg value}"
          ) config.env
        )}
      '';
    };
  };
}
