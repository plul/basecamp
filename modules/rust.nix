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
    mkDefault
    mkEnableOption
    ;
  cfg = config.rust;
in
{
  options.rust = {
    enable = mkEnableOption "Enable Rust module";
    toolchain = mkOption {
      description = "Base toolchain, e.g. stable";
      type = types.enum [
        "stable"
        "beta"
        "nightly"
      ];
      default = "stable";
    };
    extraExtensions = mkOption {
      description = "Set of extra components to install with the main toolchain, see https://rust-lang.github.io/rustup/concepts/components.html";
      type = types.listOf types.str;
      default = [ ];
      example = [ "rust-docs" ];
    };
    rust-src = {
      enable = mkEnableOptionDefaultTrue "Enable rust-src component";
    };
    clippy = {
      enable = mkEnableOptionDefaultTrue "Enable clippy";
    };
    rust-analyzer = {
      enable = mkEnableOptionDefaultTrue "Enable rust-analyzer";
      nightly = mkEnableOption "Whether to force a nightly rust-analyzer.";
    };
    rustfmt = {
      enable = mkEnableOptionDefaultTrue "Enable rustfmt";
      nightly = mkEnableOptionDefaultTrue "Whether to force a nightly rustfmt.";
    };
    cargo-udeps = {
      enable = mkEnableOption "Enable cargo-udeps.";
    };

    # non user facing options
    internal = {
      extensions = mkOption {
        description = "Extensions to be installed with the primary toolchain";
        type = types.listOf types.str;
        default = [ ];
      };
      stable = {
        extensions = mkOption {
          description = "Extensions to install from stable toolchain";
          type = types.listOf types.str;
          default = [ ];
        };
        toolchain = mkOption {
          description = "Stable toolchain";
          type = types.nullOr types.package;
          default = null;
        };
      };
      beta = {
        extensions = mkOption {
          description = "Extensions to install from beta toolchain";
          type = types.listOf types.str;
          default = [ ];
        };
        toolchain = mkOption {
          description = "Beta toolchain";
          type = types.nullOr types.package;
          default = null;
        };
      };
      nightly = {
        extensions = mkOption {
          description = "Extensions to install from nightly toolchain";
          type = types.listOf types.str;
          default = [ ];
        };
        toolchain = mkOption {
          description = "Nightly toolchain";
          type = types.nullOr types.package;
          default = null;
        };
      };
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        # Enable TOML support as well as a common requisite for Rust development with Cargo
        toml.enable = mkDefault true;

        rust.internal.stable.toolchain = basecampLib.rust.mkStable {
          inherit pkgs;
          inherit (config.rust.internal.stable) extensions;
        };
        rust.internal.beta.toolchain = basecampLib.rust.mkBeta {
          inherit pkgs;
          inherit (config.rust.internal.beta) extensions;
        };
        rust.internal.nightly.toolchain = basecampLib.rust.mkNightly {
          inherit pkgs;
          inherit (config.rust.internal.nightly) extensions;
        };

        packages.is-direct-dependency = writeShellApplication {
          name = "is-direct-dependency";
          runtimeInputs = [
            # TODO: pin cargo dependency?
            pkgs.jq
          ];
          text = ''
            DEP="''$1"
            set -x
            cargo metadata --format-version=1 --no-deps | jq --exit-status ".packages[] .dependencies[] | select(.name == \"''${DEP}\")"
          '';
        };
      }

      # Pick a primary toolchain
      (mkIf (cfg.toolchain == "stable") {
        rust.internal.stable.extensions = cfg.internal.extensions;
        packages.rust-toolchain = cfg.internal.stable.toolchain;
      })
      (mkIf (cfg.toolchain == "beta") {
        rust.internal.beta.extensions = cfg.internal.extensions;
        packages.rust-toolchain = cfg.internal.beta.toolchain;
      })
      (mkIf (cfg.toolchain == "nightly") {
        rust.internal.nightly.extensions = cfg.internal.extensions;
        packages.rust-toolchain = cfg.internal.nightly.toolchain;
      })

      # rust-src
      (mkIf cfg.rust-src.enable { rust.internal.extensions = [ "rust-src" ]; })

      # Clippy
      (mkIf cfg.clippy.enable {
        rust.internal.extensions = [ "clippy" ];
        packages.lint-rust = writeShellApplication {
          name = "lint-rust";
          runtimeInputs = [
            # TODO add clippy as input?
            config.packages.is-direct-dependency
          ];
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
      })

      # rust-analyzer
      (mkIf cfg.rust-analyzer.enable (
        lib.mkMerge [
          (mkIf (!cfg.rust-analyzer.nightly) {
            # Follow primary toolchain
            rust.internal.extensions = [ "rust-analyzer" ];
          })
          (mkIf (cfg.rust-analyzer.nightly) (
            lib.mkMerge [
              # If nigthly is the primary toolchain, include it trivially:
              (mkIf (cfg.toolchain == "nightly") { rust.internal.extensions = [ "rust-analyzer" ]; })

              # If however nightly is not the primary toolchain:
              (mkIf (cfg.toolchain != "nightly") {
                rust.internal.nightly.extensions = [ "rust-analyzer" ];
                packages.rust-analyzer = pkgs.runCommand "rust-analyzer" { } ''
                  mkdir -p $out/bin
                  ln -s ${config.rust.internal.nightly.toolchain}/bin/rust-analyzer $out/bin/rust-analyzer
                '';
              })
            ]
          ))
        ]
      ))

      # rustfmt
      (mkIf cfg.rustfmt.enable (
        lib.mkMerge [
          (mkIf (!cfg.rustfmt.nightly) {
            # Follow primary toolchain
            rust.internal.extensions = [ "rustfmt" ];
          })
          (mkIf (cfg.rustfmt.nightly) (
            lib.mkMerge [
              # If nigthly is the primary toolchain, include it trivially:
              (mkIf (cfg.toolchain == "nightly") { rust.internal.extensions = [ "rustfmt" ]; })

              # If however nightly is not the primary toolchain:
              (mkIf (cfg.toolchain != "nightly") {
                rust.internal.nightly.extensions = [ "rustfmt" ];
                packages.rustfmt = pkgs.runCommand "rustfmt" { } ''
                  mkdir -p $out/bin
                  ln -s ${config.rust.internal.nightly.toolchain}/bin/rustfmt $out/bin/rustfmt
                '';
                packages.cargo-fmt = pkgs.runCommand "cargo-fmt" { } ''
                  mkdir -p $out/bin
                  ln -s ${config.rust.internal.nightly.toolchain}/bin/cargo-fmt $out/bin/cargo-fmt
                '';
              })
            ]
          ))
          {
            packages.fmt-rust = writeShellScriptBin "fmt-rust" ''
              cargo fmt
            '';
            packages.check-fmt-rust = writeShellScriptBin "check-fmt-rust" ''
              cargo fmt -- --check
            '';
          }
        ]
      ))

      # packages: cargo-udeps
      (mkIf config.rust.cargo-udeps.enable {
        packages.cargo-udeps =
          let
            binary = lib.getExe pkgs.cargo-udeps;
          in
          writeShellScriptBin "cargo-udeps" ''
            RUSTC_BOOTSTRAP=1 exec "${binary}" "$@"
          '';
      })
    ]
  );
}
