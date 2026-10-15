# modules/sops.nix — sops-nix, imported on every host through `extraModules` in
# flake.nix rather than selected by an aggregation. Four dendrites write
# `sops.*` (tailscale, cloudflared, syncthing and slskd), so the option tree has
# to exist on every host, even one that selects none of them.

{ inputs, ... }: {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # Each host decrypts secrets with its own SSH host key (no private key to copy).
  # Add each host's ssh-to-age pubkey as a recipient in .sops.yaml.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
