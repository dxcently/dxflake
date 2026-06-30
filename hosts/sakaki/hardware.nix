{ ... }: {
  # TODO: real hardware-configuration.nix from nixos-generate-config on the box.
  # Minimal stub so the flake evaluates.
  nixpkgs.hostPlatform = "x86_64-linux";
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
