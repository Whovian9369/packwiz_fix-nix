{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # This maps to https://github.com/NixOS/nixpkgs/tree/nixos-unstable
    # The `url` option is the pattern of `github:USER_OR_ORG/REPO/BRANCH`

  outputs = {
    self,
    nixpkgs,
  }:
    let
      # List of explicitly unsupported systems
      explicitlyUnsupportedSystems = [];

      # Packwiz should support all 64-bit systems supported by go, but nix only
      # support strictly less, so all nix-supported systems are included
      # (except ones in explicitlyUnsupportedSystems).
      supportedSystems =
        nixpkgs.lib.filter
        # Filter out systems that are explicitly supported
        (s: ! nixpkgs.lib.elem s explicitlyUnsupportedSystems)
        # This lists all systems reasonably well-supported by nix
        (import "${nixpkgs}/lib/systems/flake-systems.nix" {});

      # Helper generating outputs for each supported system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Import nixpkgs' package set for each system.
      nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
    in {
      # Packwiz package
      packages = forAllSystems (system: let
        pkgs = nixpkgsFor.${system};
      in rec {
        packwiz = pkgs.callPackage ./nix {
          version = nixpkgs.lib.substring 0 8 self.rev or "dirty";
          vendorSha256 = nixpkgs.lib.readFile ./nix/vendor-sha256;
          buildGoModule = pkgs.buildGoModule;
            # As of writing, `pkgs.buildGoModule` is aliased to
            # `pkgs.buildGo121Module` in Nixpkgs.
        };
        # Build packwiz by default when no package name is specified
        default = packwiz;
      });

      # This flake's nix code formatter
      formatter = forAllSystems (system: nixpkgsFor.${system}.alejandra);
    };
}
