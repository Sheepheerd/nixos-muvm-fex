let
  # This overlay assumes all previous required overlays have been applied
  overlay = final: prev: {
    virglrenderer = prev.virglrenderer.overrideAttrs (old: {
      src = final.fetchurl {
        url = "https://gitlab.freedesktop.org/asahi/virglrenderer/-/archive/asahi-20241205.2/virglrenderer-asahi-20241205.2.tar.bz2";
        hash = "sha256-mESFaB//RThS5Uts8dCRExfxT5DQ+QQgTDWBoQppU7U=";
      };
      mesonFlags = old.mesonFlags ++ [ (final.lib.mesonOption "drm-renderers" "asahi-experimental") ];
    });
    mesa-asahi-edge = final.callPackage ./mesa.nix { inherit (prev) mesa-asahi-edge; };
    muvm = final.callPackage ./muvm.nix {
      inherit (prev) muvm;
      mesa-x86_64-linux = final.pkgsCross.gnu64.mesa-asahi-edge;
    };
    fex = final.callPackage ./fex.nix { };
    fex-x86_64-rootfs = final.runCommand "fex-rootfs" { nativeBuildInputs = [ final.erofs-utils ]; } ''
      mkdir -p rootfs/run/opengl-driver
      cp -R "${final.pkgsCross.gnu64.mesa-asahi-edge}"/* rootfs/run/opengl-driver/
      mkfs.erofs $out rootfs/
    '';
  };

  inputs = import ./inputs.nix;
  inherit (inputs) nixpkgs-muvm;
  nixos-apple-silicon-overlay = import "${inputs.nixos-apple-silicon}/apple-silicon-support/packages/overlay.nix";

  # Overlay which applies changes from https://github.com/NixOS/nixpkgs/pull/397932
  muvm-overlay = final: prev: {
    libkrunfw = final.callPackage "${nixpkgs-muvm}/pkgs/by-name/li/libkrunfw/package.nix" { };
    libkrun = final.callPackage "${nixpkgs-muvm}/pkgs/by-name/li/libkrun/package.nix" { };
    muvm = final.callPackage "${nixpkgs-muvm}/pkgs/by-name/mu/muvm/package.nix" { };
  };

  overlays = [
    nixos-apple-silicon-overlay
    muvm-overlay
    overlay
  ];
in
final: # The final argument is shared between all overlays
prev:
prev.lib.foldl' (result: overlay: result // overlay final (prev // result)) { } overlays
