# The official Claude Desktop Linux beta, including its Cowork VM runtime.
#
# The package comes from a maintained native-Linux packaging flake because
# nixpkgs does not yet carry Claude Desktop. It patches the upstream .deb
# firmware and virtiofsd paths for the Nix store; this dendrite owns only the
# host integration and VM prerequisites.
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
  nixpkgs.overlays = [ inputs.claude-desktop-nix-flake.overlays.default ];
  # A second account is a second profile directory, which also takes its own
  # single-instance lock, so both windows can run at once. Signed builds drop
  # CLAUDE_USER_DATA_DIR, so the profile is chosen with --user-data-dir.
  environment.systemPackages = [
    pkgs.claude-desktop
    (pkgs.writeShellScriptBin "claude-work" ''
      exec ${pkgs.claude-desktop}/bin/claude-desktop --user-data-dir="$HOME/.config/Claude-work" "$@"
    '')
    (pkgs.makeDesktopItem {
      name = "claude-work";
      desktopName = "Claude (Work)";
      exec = "claude-work %U";
      icon = "claude-desktop";
      categories = [
        "Utility"
        "Development"
      ];
    })
  ];

  # Cowork uses KVM and vhost-vsock to run its isolated workspace VM.
  boot.kernelModules = [ "vhost_vsock" ];
  users.groups.kvm.members = [ username ];
}
