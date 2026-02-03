# nixos-muvm-fex

This is a small piece of Nix code which packages muvm with FEX to allow seamless x86_64 emulation on Asahi systems.

The intent is to have most of this code upstreamed into nixpkgs so that all aarch64-linux systems can take advantage of it,
and whatever is Asahi-specific to move into nixos-apple-silicon, and eventually nixos-hardware.

## Usage

Once you add this project to your configuration, either through flakes or any other pinning solution,
apply the overlay this project exposes (by `import`-ing `overlay.nix` or referencing `outputs.overlays.default`),
and add `muvm` to your package list.

Example NixOS+flakes usage:
```nix
{ pkgs, inputs, ... }: {
  # Applying the overlay globally
  nixpkgs.overlays = [ inputs.nixos-mmuvm-fex.overlays.default ];
  environment.systemPackages = [ pkgs.muvm ];

  # Applying the overlay only for muvm
  environment.systemPackages = [ (pkgs.extend inputs.nixos-muvm-fex.overlays.default).muvm ];
}
```
