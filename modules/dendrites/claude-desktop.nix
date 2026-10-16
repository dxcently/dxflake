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
let
  # The session exports no XDG_CURRENT_DESKTOP, so Chromium falls back to its
  # unencrypted store and sign-ins do not persist. Name the keyring outright.
  launcher = pkgs.writeShellScriptBin "claude-desktop" ''
    exec ${pkgs.claude-desktop}/bin/claude-desktop --password-store=gnome-libsecret "$@"
  '';

  # A second account is a second profile directory, which also takes its own
  # single-instance lock, so both windows can run at once. Signed builds drop
  # CLAUDE_USER_DATA_DIR, so the profile is chosen with --user-data-dir.
  claude-work = pkgs.writeShellScriptBin "claude-work" ''
    exec ${launcher}/bin/claude-desktop --user-data-dir="$HOME/.config/Claude-work" "$@"
  '';

  # Google sign-in returns through claude://login/…, and only the instance that
  # started it holds the nonce. Send it to the profile that started one last.
  claude-open = pkgs.writeShellScriptBin "claude-open" ''
    started() { grep -h 'Using system browser for: /login/' "$1/logs/main.log" 2>/dev/null | tail -n 1 | cut -c1-19; }
    case "''${1-}" in
      claude://login/*)
        if [[ "$(started "$HOME/.config/Claude-work")" > "$(started "$HOME/.config/Claude")" ]]; then
          exec ${claude-work}/bin/claude-work "$@"
        fi
        ;;
    esac
    exec ${launcher}/bin/claude-desktop "$@"
  '';

  # The app registers its own .desktop name as the claude:// handler and checks
  # it at startup, so the router takes over that entry's Exec, not the default.
  claude-desktop = pkgs.symlinkJoin {
    name = "claude-desktop-routed";
    paths = [
      launcher
      pkgs.claude-desktop
    ];
    postBuild = ''
      entry=$out/share/applications/com.anthropic.Claude.desktop
      source=$(readlink "$entry")
      rm "$entry"
      sed -e 's|^Exec=.* %U$|Exec=${claude-open}/bin/claude-open %U|' \
        -e 's|${pkgs.claude-desktop}/bin/claude-desktop|${launcher}/bin/claude-desktop|' \
        "$source" > "$entry"
    '';
  };
in
{
  services.gnome.gnome-keyring.enable = true;
  # Claude downloads its helper into the user profile after install; nix-ld
  # supplies the dynamic loader for that future binary.
  programs.nix-ld.enable = true;
  nixpkgs.overlays = [ inputs.claude-desktop-nix-flake.overlays.default ];
  environment.systemPackages = [
    claude-desktop
    claude-work
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
