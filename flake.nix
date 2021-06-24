{
  description = "Cabal User Guide";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, pre-commit-hooks, flake-utils, flake-compat }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              custom-prettier = {
                enable = true;
                name = "Custom Prettier";
                entry = "${pkgs.nodePackages.prettier}/bin/prettier --write --list-different --ignore-unknown --config=\".prettierrc\"";
                files = "\\.(md|yml|yaml)$";
                excludes = [ ".pre-commit-config.yaml" ];
                language = "system";
              };
            };
          };
        };
        devShell = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = with pkgs; [ mdbook nodePackages.prettier ];
        };
      }
    );
}
