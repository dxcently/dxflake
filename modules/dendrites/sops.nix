# modules/dendrites/sops.nix — sops-nix, the secrets module. A member of `core`,
# so it is imported only on hosts that select core. Four dendrites write `sops.*`
# (tailscale, cloudflared, syncthing and slskd); a host that keeps any of them
# needs this one too, or evaluation fails with "The option `sops' does not exist".

{ inputs, ... }: {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # Each host decrypts secrets with its own SSH host key (no private key to copy).
  # Add each host's ssh-to-age pubkey as a recipient in .sops.yaml.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
