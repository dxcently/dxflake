# The official Claude Desktop Linux beta, including its Cowork VM runtime.
#
# The package comes from a maintained native-Linux packaging flake because
# nixpkgs does not yet carry Claude Desktop. It patches the upstream .deb
# firmware and virtiofsd paths for the Nix store; this dendrite owns only the
# host integration and VM prerequisites.
{
  nixos =
    {
      inputs,
      pkgs,
      username,
      ...
    }:
    {
      services.gnome.gnome-keyring.enable = true;
      # Claude downloads its helper into the user profile after install; nix-ld
      # supplies the dynamic loader for that future binary.
      programs.nix-ld.enable = true;
      environment.systemPackages = [
        inputs.claude-desktop-nix-flake.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop
      ];

      # Cowork uses KVM and vhost-vsock to run its isolated workspace VM.
      boot.kernelModules = [ "vhost_vsock" ];
      users.groups.kvm.members = [ username ];
    };
}
