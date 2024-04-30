_list:
    @just --list

# Check project
check:
    just check-fmt
    just check-nix

# Check Nix
check-nix:
    nix flake check

# Check formatting
check-fmt:
    just check-fmt-just
    just check-fmt-nix
    just check-fmt-markdown

# Check formatting of justfile
check-fmt-just:
    just --unstable --fmt --check

# Check formatting of Nix
check-fmt-nix:
    fd -e=nix -X nixfmt --check

# Check formatting of Markdown
check-fmt-markdown:
    fd -e=md -X prettier --check

# Format project
fmt:
    just fmt-just
    just fmt-nix
    just fmt-markdown

# Format Justfile
fmt-just:
    just --unstable --fmt

# Format Nix
fmt-nix:
    fd -e=nix -X nixfmt

# Format Markdown
fmt-markdown:
    fd -e=md -X prettier --write 

# Update flake inputs
update-flake-inputs:
    nix flake update

watch:
    watchexec --restart --clear -- nix flake check
