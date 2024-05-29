{ pkgs, config, ... }:
let
  inherit (pkgs) writeShellApplication writeShellScriptBin;
  inherit (pkgs.lib)
    getExe
    mkDefault
    mkEnableOption
    mkEnableOptionDefaultTrue
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.rust;
in
{
  options.rust = {
    enable = mkEnableOption "Rust module";
    toolchain = mkOption {
      description = "Determines base toolchain, e.g. stable";
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
    cargo-udeps = {
      enable = mkEnableOption "cargo-udeps";
    };
    recipes.check-fmt.enable = mkEnableOptionDefaultTrue "`check-fmt-rust` command";
    recipes.fmt.enable = mkEnableOptionDefaultTrue "`fmt-rust` command";
    recipes.lint.enable = mkEnableOptionDefaultTrue "`lint-rust` command";

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

  config = mkIf cfg.enable (mkMerge [
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

      namedPackages.is-direct-dependency = writeShellApplication {
        name = "is-direct-dependency";
        runtimeInputs = [ pkgs.jq ];
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
      namedPackages.rust-toolchain = cfg.stable.toolchain;
    })
    (mkIf (cfg.toolchain == "beta") {
      rust.beta.extensions = cfg.extensions;
      namedPackages.rust-toolchain = cfg.beta.toolchain;
    })
    (mkIf (cfg.toolchain == "nightly") {
      rust.nightly.extensions = cfg.extensions;
      namedPackages.rust-toolchain = cfg.nightly.toolchain;
    })

    # rust-src
    (mkIf cfg.rust-src.enable { rust.extensions = [ "rust-src" ]; })

    # Clippy
    (mkIf cfg.clippy.enable {
      rust.extensions = [ "clippy" ];
      namedPackages.lint-rust = mkIf cfg.recipes.lint.enable (writeShellApplication {
        name = "lint-rust";
        runtimeInputs = [ config.namedPackages.is-direct-dependency ];
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
      });
    })

    # rust-analyzer
    (mkIf cfg.rust-analyzer.enable (mkMerge [
      (mkIf (!cfg.rust-analyzer.nightly) {
        # Follow primary toolchain
        rust.extensions = [ "rust-analyzer" ];
      })
      (mkIf (cfg.rust-analyzer.nightly) (mkMerge [
        # If nigthly is the primary toolchain, include it trivially:
        (mkIf (cfg.toolchain == "nightly") { rust.extensions = [ "rust-analyzer" ]; })

        # If however nightly is not the primary toolchain:
        (mkIf (cfg.toolchain != "nightly") {
          rust.nightly.extensions = [ "rust-analyzer" ];
          namedPackages.rust-analyzer = pkgs.runCommand "rust-analyzer" { } ''
            mkdir -p $out/bin
            ln -s ${config.rust.nightly.toolchain}/bin/rust-analyzer $out/bin/rust-analyzer
          '';
        })
      ]))
    ]))

    # rustfmt
    (mkIf cfg.rustfmt.enable (mkMerge [
      (mkIf (!cfg.rustfmt.nightly) {
        # Follow primary toolchain
        rust.extensions = [ "rustfmt" ];
      })
      (mkIf (cfg.rustfmt.nightly) (mkMerge [
        # If nigthly is the primary toolchain, include it trivially:
        (mkIf (cfg.toolchain == "nightly") { rust.extensions = [ "rustfmt" ]; })

        # If however nightly is not the primary toolchain:
        (mkIf (cfg.toolchain != "nightly") {
          rust.nightly.extensions = [ "rustfmt" ];
          packages =
            let
              rustfmt = pkgs.runCommand "rustfmt" { } ''
                mkdir -p $out/bin
                ln -s ${config.rust.nightly.toolchain}/bin/rustfmt $out/bin/rustfmt
              '';
              cargo-fmt = pkgs.runCommand "cargo-fmt" { } ''
                mkdir -p $out/bin
                ln -s ${config.rust.nightly.toolchain}/bin/cargo-fmt $out/bin/cargo-fmt
              '';
            in
            [
              rustfmt
              cargo-fmt
            ];
        })
      ]))
      {
        namedPackages.fmt-rust = mkIf cfg.recipes.fmt.enable (writeShellApplication {
          name = "fmt-rust";
          text = ''
            set -x
            cargo fmt
          '';
        });
        namedPackages.check-fmt-rust = mkIf cfg.recipes.check-fmt.enable (writeShellApplication {
          name = "check-fmt-rust";
          text = ''
            set -x
            cargo fmt -- --check
          '';
        });
      }
    ]))

    # packages: cargo-udeps
    (mkIf config.rust.cargo-udeps.enable {
      namedPackages.cargo-udeps = writeShellScriptBin "cargo-udeps" ''
        RUSTC_BOOTSTRAP=1 exec "${getExe pkgs.cargo-udeps}" "$@"
      '';
    })
  ]);
}
