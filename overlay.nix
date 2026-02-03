let
  # This overlay assumes all previous required overlays have been applied
  overlay = final: prev: {

    virglrenderer = prev.virglrenderer.overrideAttrs (old: {
      src = final.fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "asahi";
        repo = "virglrenderer";
        rev = "main"; # Target the latest branch tip
        hash = "sha256-6o/A+rvbFVFrH6vKnXQzTAINwkn+OTIdo7dXSUFeCqY=";
      };

      # Keep these flags. If the build fails saying "unknown option",
      # try changing "asahi-experimental" to just "asahi".
      mesonFlags = old.mesonFlags ++ [
        (final.lib.mesonOption "drm-renderers" "asahi-experimental")
      ];
    });
    mesa = final.callPackage ./mesa.nix { inherit (prev) mesa; };
    muvm = final.callPackage ./muvm.nix {
      inherit (prev) muvm;
      mesa-x86_64-linux = final.pkgsCross.gnu64.mesa;
    };
    fex = final.callPackage ./fex.nix { };
    fex-x86_64-rootfs = final.runCommand "fex-rootfs" { nativeBuildInputs = [ final.erofs-utils ]; } ''
      mkdir -p rootfs/run/opengl-driver
      cp -R "${final.pkgsCross.gnu64.mesa}"/* rootfs/run/opengl-driver/
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
