_list:
    @just --list

# Check project
check:
    bc-check
    nix flake check

# Check formatting
check-fmt:
    bc-check-fmt

# Format project
fmt:
    bc-fmt

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
