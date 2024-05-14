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

  outputs = { self, basecamp, ... }: {
    # (...)
  }
}
```

Then define e.g. a devShell:

```nix
    devShells."x86_64-linux".default = basecamp.mkShell {
      pkgs = import nixpkgs { system = "x86_64-linux"; };

      # Enable components depending on what is needed in the project:
      config = {
        # For example, enable the markdown component to allow formatting of the README:
        markdown.enable = true;

        nix.enable = true;
        just.enable = true;
        rust.enable = true;

        # Optionally customize components.
        # Use a stable Rust toolchain but opt for a nightly rust analyzer:
        rust.toolchain = "stable"; # ("stable" is the default)
        rust.rust-analyzer.nightly = true;
      };

      # Any additional packages
      packages = p: [
        p.watchexec
      ];
    };
```
