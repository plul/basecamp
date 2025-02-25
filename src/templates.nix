{ pkgs, ... }:

let
  name = "bc-template-rust";
  justfile = ''
    _default:
        @just --unsorted --list

    # Check project
    check:
        bc-check

    # Format project
    fmt:
        bc-fmt
  '';
  flake = ''
    {
      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

        rust-overlay.url = "github:oxalica/rust-overlay";
        rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

        basecamp.url = "github:plul/basecamp";
        basecamp.inputs.nixpkgs.follows = "nixpkgs";
        basecamp.inputs.rust-overlay.follows = "rust-overlay";
      };

      outputs =
        { basecamp, nixpkgs, ... }:
        {
          devShells."x86_64-linux".default =
            let
              pkgs = import nixpkgs { system = "x86_64-linux"; };
            in
            basecamp.mkShell pkgs {
              rust.enable = true;
              packages = [ ];
            };
        };
    }
  '';
  rustfmt = ''
    unstable_features = true
    version = "Two"
    imports_granularity = "Item"
    group_imports = "One"
    use_field_init_shorthand = true
    max_width = 150
  '';
  changelog = ''
    # Changelog

    ## Unreleased

    ## v0.1.0

    - Initial release
  '';
  workspace_cargo_toml = ''
    [workspace]
    resolver = "3"

    members = []

    [workspace.package]
    edition = "2024"

    [workspace.lints.rust]
    future_incompatible = { level = "deny", priority = -1 }
    nonstandard_style = { level = "deny", priority = -1 }
    rust_2018_idioms = { level = "deny", priority = -1 }
    missing_docs = "warn"
    missing_debug_implementations = "warn"
  '';
  main_rs = ''
    //! <docstring>.

    fn main() {}
  '';
in
{
  template-rust = pkgs.writeShellApplication {
    inherit name;
    text = ''
      set -euo pipefail

      if [ $# -eq 0 ]; then
        echo "Usage: ${name} <directory>"
        exit 1
      fi

      path=$1
      name=''$(basename "''${path}")

      if [ -d "''${path}" ]; then
        echo "Directory ''${path} already exists!"
        exit 1
      fi

      mkdir "''${path}"
      cd "''${path}"

      # Git
      git init
      touch .gitignore

      # Flake
      echo '${flake}' > flake.nix
      git add flake.nix

      # Direnv
      echo 'use flake' > .envrc
      echo '/.direnv/' >> .gitignore

      # Justfile
      echo '${justfile}' > justfile

      # Changelog
      echo '${changelog}' > CHANGELOG.md

      # Readme
      echo "# ''${name}" > README.md

      # Rust
      echo '/target/' >> .gitignore
      echo '${workspace_cargo_toml}' > Cargo.toml
      mkdir crates
      nix develop --command cargo init "crates/''${name}"
      nix develop --command cargo tree
      echo '${main_rs}' | sed -e "s|<docstring>|''${name}|" > "crates/''${name}/src/main.rs"
      echo '${rustfmt}' > rustfmt.toml

      # Format and stage
      nix develop --command just fmt
      git add .
    '';
  };
}
