{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
    };
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      flake = false;
    };
    nixpkgs-muvm = {
      url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
      flake = false;
    };
    __flake-compat = {
      url = "git+https://git.lix.systems/lix-project/flake-compat.git";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      system = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      overlay = import ./overlay.nix;
      pkgs' = pkgs.extend overlay;
    in
    {
      overlays.default = overlay;

      packages.${system} = {
        inherit (pkgs')
          mesa-asahi-edge
          muvm
          fex
          fex-x86_64-rootfs
          ;
        mesa-x86_64-linux = pkgs'.pkgsCross.gnu64.mesa-asahi-edge;
      };
    };
}
