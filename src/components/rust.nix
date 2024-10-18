{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    optionals
    getExe
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (pkgs) writeShellApplication writeShellScriptBin symlinkJoin;
  inherit (pkgs.basecamp) mkEnableOptionDefaultTrue;
  cfg = config.rust;
in
{
  options.rust = {
    enable = mkEnableOption "Rust module";

    toolchain =
      let
        mkToolchainOption = {
          package = mkOption {
            description = "Toolchain package";
            type = types.nullOr types.package;
            default = null;
            visible = false;
          };
          components = mkOption {
            description = "Components, see https://rust-lang.github.io/rustup/concepts/components.html";
            type = types.listOf types.str;
            default = [ ];
            example = [ "rust-docs" ];
          };
        };
      in
      {
        package = mkOption {
          description = "Rust toolchain";
          type = types.package;
          readOnly = true;
        };

        channel = mkOption {
          description = "Sets base channel, e.g. stable";
          type = types.enum [
            "stable"
            "beta"
            "nightly"
          ];
          default = "stable";
          example = "beta";
        };

        components = {
          rust-src = {
            enable = mkEnableOptionDefaultTrue "rust-src component";
          };

          clippy = {
            enable = mkEnableOptionDefaultTrue "Clippy";
          };

          rust-analyzer = {
            enable = mkEnableOptionDefaultTrue "rust-analyzer";
            nightly = mkEnableOption "use of a nightly rust-analyzer";
          };

          rustfmt = {
            enable = mkEnableOptionDefaultTrue "rustfmt formatter";
            nightly = mkEnableOptionDefaultTrue "use of a nightly rustfmt";
          };

          extra = mkOption {
            description = "Any extra extensions to be installed with the primary toolchain, see https://rust-lang.github.io/rustup/concepts/components.html";
            type = types.listOf types.str;
            default = [ ];
            example = [ "rust-docs" ];
          };
        };

        targets = mkOption {
          description = "Targets to be installed with the primary toolchain";
          type = types.listOf types.str;
          default = [ ];
          example = [ "wasm32-unknown-unknown" ];
        };

        stable = mkToolchainOption;
        beta = mkToolchainOption;
        nightly = mkToolchainOption;
      };

    fmt.enable = mkEnableOptionDefaultTrue "formatting of files";
    fmt.package = mkOption {
      description = "Package to execute to format files";
      type = types.package;
      default = writeShellApplication {
        name = "basecamp-rust-fmt";
        text = ''
          set -x
          cargo fmt
        '';
      };
    };

    checks = {
      enable = mkEnableOptionDefaultTrue "checks";

      fmt.enable = mkEnableOptionDefaultTrue "check of correct formatting";
      fmt.package = mkOption {
        description = "Package to execute to check correct formatting";
        type = types.package;
        default = writeShellApplication {
          name = "basecamp-rust-checks-fmt";
          text = ''
            set -x
            cargo fmt -- --check
          '';
        };
      };

      lint.enable = mkEnableOptionDefaultTrue "linting";
      lint.package = mkOption {
        type = types.package;
        description = "Package to execute to perform linting";
        default = writeShellApplication {
          name = "basecamp-rust-checks-lint";
          runtimeInputs = [ config.rust.packages.is-direct-dependency ];
          text = ''
            set -x
            if is-direct-dependency clap; then
              DEPENDS_ON_CLAP="yes"
            fi
            cargo clippy --workspace --all-features --tests --examples \
              ''${DEPENDS_ON_CLAP:+--features clap/deprecated} \
              -- \
              --deny warnings
          '';
        };
      };
    };

    packages.cargo-udeps = {
      enable = mkEnableOption "cargo-udeps";
      package = mkOption {
        description = "cargo-udeps package. By default this is a patched version of pkgs.cargo-udeps to account for cargo-udeps's dependency on nightly";
        type = types.package;
        default = writeShellScriptBin "cargo-udeps" ''
          RUSTC_BOOTSTRAP=1 exec "${getExe pkgs.cargo-udeps}" "$@"
        '';
      };
    };

    packages.is-direct-dependency = mkOption {
      description = "Returns true if the given package is a direct dependency";
      type = types.package;
      default = writeShellApplication {
        name = "is-direct-dependency";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          DEP="''$1"
          set -x
          cargo metadata --format-version=1 --no-deps | jq --exit-status ".packages[] .dependencies[] | select(.name == \"''${DEP}\")"
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Enable TOML support as well as a common requisite for Rust development with Cargo
      toml.enable = mkDefault true;
    }

    # Resolve components
    (
      let
        c = cfg.toolchain.components;
        components =
          [ ]
          ++ optionals c.rust-src.enable [ "rust-src" ]
          ++ optionals c.clippy.enable [ "clippy" ]
          ++ optionals (c.rust-analyzer.enable && !c.rust-analyzer.nightly) [ "rust-analyzer" ]
          ++ optionals (c.rustfmt.enable && !c.rustfmt.nightly) [ "rustfmt" ];
        nightlyComponents =
          [ ]
          ++ optionals (c.rust-analyzer.enable && c.rust-analyzer.nightly) [ "rust-analyzer" ]
          ++ optionals (c.rustfmt.enable && c.rustfmt.nightly) [ "rustfmt" ];
      in
      mkMerge [
        {
          rust.toolchain.stable.components = mkIf (cfg.toolchain.channel == "stable") components;
          rust.toolchain.beta.components = mkIf (cfg.toolchain.channel == "beta") components;
          rust.toolchain.nightly.components = mkIf (cfg.toolchain.channel == "nightly") components;
        }
        { rust.toolchain.nightly.components = nightlyComponents; }
      ]
    )

    # Set toolchains
    {
      rust.toolchain = {
        stable.package = pkgs.rust-bin.stable.latest.minimal.override {
          extensions = cfg.toolchain.stable.components;
          targets = cfg.toolchain.targets;
        };
        beta.package = pkgs.rust-bin.beta.latest.minimal.override {
          extensions = cfg.toolchain.beta.components;
          targets = cfg.toolchain.targets;
        };
        nightly.package = pkgs.rust-bin.selectLatestNightlyWith (
          toolchain:
          toolchain.minimal.override {
            extensions = cfg.toolchain.nightly.components;
            targets = cfg.toolchain.targets;
          }
        );
      };
    }

    # Assemble toolchain
    {
      rust.toolchain.package =
        let
          base =
            {
              "stable" = cfg.toolchain.stable.package;
              "beta" = cfg.toolchain.beta.package;
              "nightly" = cfg.toolchain.nightly.package;
            }
            .${cfg.toolchain.channel};
        in
        symlinkJoin {
          name = "basecamp-rust-toolchain";
          inherit (base) meta passthru;
          paths =
            [ base ]
            ++ optionals (
              cfg.toolchain.channel != "stable" && builtins.length cfg.toolchain.stable.components > 0
            ) [ cfg.toolchain.stable.package ]
            ++ optionals (
              cfg.toolchain.channel != "beta" && builtins.length cfg.toolchain.beta.components > 0
            ) [ cfg.toolchain.beta.package ]
            ++ optionals (
              cfg.toolchain.channel != "nightly" && builtins.length cfg.toolchain.nightly.components > 0
            ) [ cfg.toolchain.nightly.package ];
        };
      packages = [ config.rust.toolchain.package ];
    }

    # Add supporting packages
    {
      packages = [ ] ++ optionals cfg.packages.cargo-udeps.enable [ cfg.packages.cargo-udeps.package ];
    }
  ]);
}
