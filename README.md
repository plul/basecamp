<p align="center">
  <img src="assets/logo.webp" alt="Logo" width="20%">
</p>

# Basecamp

Provisioning of opinionated common dependencies, tools and commands, by leveraging the [NixOS module system](https://nixos.wiki/wiki/NixOS_modules).

## Documentation

- Options reference: <https://plul.github.io/basecamp/>

## Usage

Set up imports

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    basecamp.url = "github:plul/basecamp";
    basecamp.inputs.nixpkgs.follows = "nixpkgs";
    basecamp.inputs.rust-overlay.follows = "rust-overlay";

    # (...)
  };

  outputs = { basecamp, nixpkgs, ... }: {
    # (...)
  };
}
```

Then define e.g. a devShell:

```nix
    devShells."x86_64-linux".default = 
      let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
      in
    basecamp.mkShell pkgs {
      # Enable components depending on what is needed in the project:
      rust.enable = true;

      # Optionally customize components.
      # Use a stable Rust toolchain but opt for a nightly rust analyzer:
      rust.toolchain.channel = "stable"; # ("stable" is the default)
      rust.toolchain.components.rust-analyzer.nightly = true;

      # Any additional packages
      packages = [
        pkgs.watchexec
      ];
    };
```

Some modules are enabled by default: `nix`, `just` and `markdown`.
For example, enabling the markdown component allows formatting of the project README.
