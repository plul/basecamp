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
    check-fmt-just
    check-fmt-nix
    check-fmt-markdown

# Format project
fmt:
    fmt-just
    fmt-nix
    fmt-markdown

# (re)-generate options docs
generate-docs:
    nix build .#docs
    cp --dereference result docs/index.html
    chmod +w docs/index.html
    rm result

# Update flake inputs
update-flake-inputs:
    nix flake update

# Run `nix flake check` on changes
watch:
    watchexec --restart --clear -- nix flake check 
