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
      pkgsX86 = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

    in
    {
      overlays.default = overlay;

      packages.${system} = {
        inherit (pkgs')
          muvm
          fex
          fex-x86_64-rootfs
          ;
        mesa-x86_64-linux = pkgsX86.mesa;
      };
    };
}
