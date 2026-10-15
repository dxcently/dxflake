{ inputs, ... }: {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # Each host decrypts secrets with its own SSH host key (no private key to copy).
  # Add each host's ssh-to-age pubkey as a recipient in .sops.yaml.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
