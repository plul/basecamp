{
  basecamp,
  pkgs,
  config,
  ...
}:
let
  inherit (basecamp.lib) mkEnableOptionDefaultTrue;
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
    enable = mkEnableOption "Enables Rust module.";
    toolchain = mkOption {
      description = "Determines base toolchain, e.g. stable.";
      type = types.enum [
        "stable"
        "beta"
        "nightly"
      ];
      default = "stable";
    };
    extraExtensions = mkOption {
      description = "Sets extra components to install with the main toolchain, see https://rust-lang.github.io/rustup/concepts/components.html";
      type = types.listOf types.str;
      default = [ ];
      example = [ "rust-docs" ];
    };
    rust-src = {
      enable = mkEnableOptionDefaultTrue "Enables rust-src component.";
    };
    clippy = {
      enable = mkEnableOptionDefaultTrue "Enables Clippy.";
    };
    rust-analyzer = {
      enable = mkEnableOptionDefaultTrue "Enables rust-analyzer.";
      nightly = mkEnableOption "Forces use of a nightly rust-analyzer.";
    };
    rustfmt = {
      enable = mkEnableOptionDefaultTrue "Enables rustfmt.";
      nightly = mkEnableOptionDefaultTrue "Forces use of a nightly rustfmt.";
    };
    cargo-udeps = {
      enable = mkEnableOption "Enables cargo-udeps.";
    };

    # non user facing options
    extensions = mkOption {
      description = "Extensions to be installed with the primary toolchain";
      type = types.listOf types.str;
      default = [ ];
      visible = false;
    };
    stable = {
      extensions = mkOption {
        description = "Extensions to install from stable toolchain";
        type = types.listOf types.str;
        default = [ ];
        visible = false;
      };
      toolchain = mkOption {
        description = "Stable toolchain";
        type = types.nullOr types.package;
        default = null;
        visible = false;
      };
    };
    beta = {
      extensions = mkOption {
        description = "Extensions to install from beta toolchain";
        type = types.listOf types.str;
        default = [ ];
        visible = false;
      };
      toolchain = mkOption {
        description = "Beta toolchain";
        type = types.nullOr types.package;
        default = null;
        visible = false;
      };
    };
    nightly = {
      extensions = mkOption {
        description = "Extensions to install from nightly toolchain";
        type = types.listOf types.str;
        default = [ ];
        visible = false;
      };
      toolchain = mkOption {
        description = "Nightly toolchain";
        type = types.nullOr types.package;
        default = null;
        visible = false;
      };
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        # Enable TOML support as well as a common requisite for Rust development with Cargo
        toml.enable = mkDefault true;

        rust.stable.toolchain = pkgs.rust-bin.stable.latest.minimal.override {
          inherit (config.rust.stable) extensions;
        };
        rust.beta.toolchain = pkgs.rust-bin.stable.latest.minimal.override {
          inherit (config.rust.beta) extensions;
        };
        rust.nightly.toolchain = pkgs.rust-bin.selectLatestNightlyWith (
          toolchain: toolchain.minimal.override { inherit (config.rust.nightly) extensions; }
        );

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
        rust.stable.extensions = cfg.extensions;
        packages.rust-toolchain = cfg._stable.toolchain;
      })
      (mkIf (cfg.toolchain == "beta") {
        rust.beta.extensions = cfg.extensions;
        packages.rust-toolchain = cfg._beta.toolchain;
      })
      (mkIf (cfg.toolchain == "nightly") {
        rust.nightly.extensions = cfg.extensions;
        packages.rust-toolchain = cfg._nightly.toolchain;
      })

      # rust-src
      (mkIf cfg.rust-src.enable { rust.extensions = [ "rust-src" ]; })

      # Clippy
      (mkIf cfg.clippy.enable {
        rust.extensions = [ "clippy" ];
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
            rust.extensions = [ "rust-analyzer" ];
          })
          (mkIf (cfg.rust-analyzer.nightly) (
            lib.mkMerge [
              # If nigthly is the primary toolchain, include it trivially:
              (mkIf (cfg.toolchain == "nightly") { rust.extensions = [ "rust-analyzer" ]; })

              # If however nightly is not the primary toolchain:
              (mkIf (cfg.toolchain != "nightly") {
                rust.nightly.extensions = [ "rust-analyzer" ];
                packages.rust-analyzer = pkgs.runCommand "rust-analyzer" { } ''
                  mkdir -p $out/bin
                  ln -s ${config.rust.nightly.toolchain}/bin/rust-analyzer $out/bin/rust-analyzer
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
            rust.extensions = [ "rustfmt" ];
          })
          (mkIf (cfg.rustfmt.nightly) (
            lib.mkMerge [
              # If nigthly is the primary toolchain, include it trivially:
              (mkIf (cfg.toolchain == "nightly") { rust.extensions = [ "rustfmt" ]; })

              # If however nightly is not the primary toolchain:
              (mkIf (cfg.toolchain != "nightly") {
                rust.nightly.extensions = [ "rustfmt" ];
                packages.rustfmt = pkgs.runCommand "rustfmt" { } ''
                  mkdir -p $out/bin
                  ln -s ${config.rust.nightly.toolchain}/bin/rustfmt $out/bin/rustfmt
                '';
                packages.cargo-fmt = pkgs.runCommand "cargo-fmt" { } ''
                  mkdir -p $out/bin
                  ln -s ${config.rust.nightly.toolchain}/bin/cargo-fmt $out/bin/cargo-fmt
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
