{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionalString getExe;
  inherit (pkgs) writeShellApplication;
  inherit (pkgs.basecamp) mkEnableOptionDefaultTrue;
  cfg = config.recipes;
  np = config.namedPackages;
  fmt-just = getExe np.fmt-just;
  fmt-markdown = getExe np.fmt-markdown;
  fmt-nickel = getExe np.fmt-nickel;
  fmt-nix = getExe np.fmt-nix;
  fmt-rust = getExe np.fmt-rust;
  fmt-toml = getExe np.fmt-toml;
  check-fmt = getExe np.check-fmt;
  check-fmt-just = getExe np.check-fmt-just;
  check-fmt-markdown = getExe np.check-fmt-markdown;
  # check-fmt-nickel = getExe np.check-fmt-nickel;
  check-fmt-nix = getExe np.check-fmt-nix;
  check-fmt-rust = getExe np.check-fmt-rust;
  check-fmt-toml = getExe np.check-fmt-toml;
  lint = getExe np.lint;
  lint-rust = getExe np.lint-rust;
  lint-toml = getExe np.lint-toml;
  lint-nix = getExe np.lint-nix;
in
{
  options.recipes = {
    fmt.enable = mkEnableOptionDefaultTrue "`bc-fmt` command";
    check-fmt.enable = mkEnableOptionDefaultTrue "`bc-check-fmt` command";
    check.enable = mkEnableOptionDefaultTrue "`bc-check` command";
    lint.enable = mkEnableOptionDefaultTrue "`bc-lint` command";
  };

  config = {
    namedPackages.fmt = mkIf cfg.fmt.enable (writeShellApplication {
      name = "bc-fmt";
      text = ''
        ${optionalString (config.just.enable && config.just.recipes.fmt.enable) fmt-just}
        ${optionalString (config.markdown.enable && config.markdown.recipes.fmt.enable) fmt-markdown}
        ${optionalString (config.nickel.enable && config.nickel.recipes.fmt.enable) fmt-nickel}
        ${optionalString (config.nix.enable && config.nix.recipes.fmt.enable) fmt-nix}
        ${optionalString (config.rust.enable && config.rust.recipes.fmt.enable) fmt-rust}
        ${optionalString (config.toml.enable && config.toml.recipes.fmt.enable) fmt-toml}
      '';
    });

    namedPackages.check-fmt = mkIf cfg.check-fmt.enable (writeShellApplication {
      name = "bc-check-fmt";
      text = ''
        ${optionalString (config.just.enable && config.just.recipes.check-fmt.enable) check-fmt-just}
        ${optionalString (
          config.markdown.enable && config.markdown.recipes.check-fmt.enable
        ) check-fmt-markdown}
        # TODO: check-fmt for Nickel not supported
        ${optionalString (config.nix.enable && config.nix.recipes.check-fmt.enable) check-fmt-nix}
        ${optionalString (config.rust.enable && config.rust.recipes.check-fmt.enable) check-fmt-rust}
        ${optionalString (config.toml.enable && config.toml.recipes.check-fmt.enable) check-fmt-toml}
      '';
    });

    namedPackages.check = mkIf cfg.check.enable (writeShellApplication {
      name = "bc-check";
      text = ''
        ${optionalString (cfg.check-fmt.enable) check-fmt}
        ${optionalString (cfg.check-fmt.enable) lint}
        # TODO
      '';
    });

    namedPackages.lint = mkIf cfg.lint.enable (writeShellApplication {
      name = "bc-lint";
      text = ''
        ${optionalString (config.rust.enable && config.rust.recipes.lint.enable) lint-rust}
        ${optionalString (config.toml.enable && config.toml.recipes.lint.enable) lint-toml}
        ${optionalString (config.nix.enable && config.nix.recipes.lint.enable) lint-nix}
      '';
    });
  };
}
