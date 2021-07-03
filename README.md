# Cabal User Guide

## Dependencies

All dependencies are provided via nix. This project is defined as a flake so you
can use `nix develop` to enter a shell if you have experimental features
enabled. There is also `flake-compat` setup so a regular `nix shell` should work
if you don't want to use experimental features.

If you don't want to use nix you can install these dependencies by themselves.
It should be noted that the pre-commit-hooks are setup using nix, so if you want
to not use nix it might be convenient to setup your own commit hooks, or you can
run mdformat on your own. CI will fail if markdown files are not correctly
formatted!

- [mdbook](https://rust-lang.github.io/mdBook/cli/index.html)
- [prettier](https://prettier.io/)

### Getting Nix

If you want to install nix please follow the instructions
[here](https://nixos.org/download.html)

## Running Locally

This project is built with mdbook and they have
[great documentation](https://rust-lang.github.io/mdBook/index.html).

The main command for development is `mdbook serve` which will run the book
locally on `localhost:3000`.

## Contributing

Chapters can be edited in their corresponding markdown files (see
[SUMMARY.md](./src/SUMMARY.md) for reference). To add a new chapter, add a link
in SUMMARY.md and then create the corresponding markdown file. For more in depth
instructions on adding content to an mdbook project see the
[official docs](https://rust-lang.github.io/mdBook/format/summary.html)
