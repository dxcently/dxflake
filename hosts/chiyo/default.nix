# chiyo — the laptop, and the full AoideOS paint carrier.
{
  pkgs,
  username,
  ...
}:
{
  habit.song.declared = "sonata";

  habit.aggregation = {
    nucleus.enable = true;
    aoide.enable = true;
    network.enable = true;
    # desktop stays: it carries pipewire, fonts, fcitx5, portals and ly login —
    # none of those collide with Aoide's paint. The shell aggregation is NOT
    # selected here: Aoide's lanes paint instead.
    desktop.enable = true;
    forensic-tools.enable = true; # the forensics suite: autopsy, imhex, guymager and the sleuthkit CLI.
  };

  habit.dendrites = {
    aoide.enable = true;
    # Aoide's paint carrier: the Quickshell surface, lyra, the dunst daemon
    # behind the herald, Aoide's own clipboard and screenshot services, the
    # hyprland behaviour lane (keybinds, input, tiling), and the stylix and
    # compositor lanes (catalogued as aoide-stylix and aoide-compositor).
    quickshell.enable = true;
    lyra.enable = true;
    dunst.enable = true;
    clipboard.enable = true;
    screenshot.enable = true;
    hyprland.enable = true;
    aoide-stylix.enable = true;
    aoide-compositor = {
      enable = true;
      provider = "hyprland";
    };
    bluetooth.enable = true;
    claude-code.enable = true;
    claude-desktop.enable = true;
    cloudflared.enable = true;
    eidolon.enable = true;
    gpu = {
      enable = true;
      provider = "intel";
    };
    hyprlock.enable = true;
    kimi-cli.enable = true;
    laptop.enable = true;
    opencode.enable = true;
    ros.enable = true;
    syncthing.enable = true;
    postgresql.enable = true;
  };

  habit.users.khoa = {
    definition = ../../users/khoa.nix;
    home.enable = true;
    # The person, not the machine: these groups contribute home halves.
    aggregation = {
      desktop.enable = true;
    };
    dendrites.pi-coding-agent.enable = true;
  };

  imports = [ ./hardware.nix ];
  # osaka builds for chiyo; local builds only when osaka is unreachable.
  nix = {
    distributedBuilds = true;
    settings.builders-use-substitutes = true;
    buildMachines = [
      {
        hostName = "100.102.235.52"; # osaka's tailscale address: reachable off the LAN too
        sshUser = "nixremote";
        sshKey = "/etc/ssh/ssh_host_ed25519_key";
        protocol = "ssh-ng";
        system = "x86_64-linux";
        maxJobs = 8;
        speedFactor = 10;
        supportedFeatures = [
          "big-parallel"
          "kvm"
          "nixos-test"
          "benchmark"
        ];
      }
    ];
  };
  programs.ssh.knownHosts.osaka = {
    hostNames = [ "100.102.235.52" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqMuS6SKujGuBlEaJNOeyJPqN3uXUbiyi8BbHpVgkNS";
  };
  # The door can exec an agent for peer-summoned sessions (`peer spawn
  # chiyo`), the same wiring sakaki carries — without it the door refuses
  # with "A2A spawn not configured" (observed live 2026-08-28, first
  # yomi→chiyo summon attempt after pairing).
  aoide.a2a = {
    spawnAgent = "claude";
    spawnPath = [ pkgs.claude-code ];
  };
  # chiyo is the full AoideOS carrier: the complete Aoide paint stack owns the
  # session — compositor (Hyprland wiring + livery), stylix (base16 fan-out),
  # and quickshell (bar/dock/launcher/theming) — replacing dxflake's own
  # Hyprland + Stylix dendrites, which stay unselected here so only one writer
  # ever touches the leaf options the two stacks
  # share (see modules/dendrites/aoide.nix's header for the collision
  # reasoning). The hyprland lane is the BEHAVIOUR half (keybinds, input,
  # tiling layout) that pairs with the compositor lane's LOOK — without it
  # chiyo would have a themed but unusable session (no SUPER+SPACE launcher,
  # no window movement).
  # The palette is the rice's, not this host's: the fixed Rosé Pine, read from
  # the one file that authors it, so chiyo and osaka paint identically rather
  # than each carrying a copy of the same sixteen hexes — which is how they
  # drifted apart in the two slots they disagreed on (hot and base0F).
  # Blur re-renders behind every moving window; the UHD 620 can't afford it.
  aoide.livery.geometry.blurEnabled = false;
  aoide.livery.override = (import ../../song/songbook/transience/palette.nix).override;
  stylix.polarity = "dark";
  # The palette is baked into gtksourceview, so every livery change rebuilt
  # it (and virt-manager above it) here, where its 30 s test timeout fails.
  stylix.targets.gtksourceview.enable = false;
  # Login stays dxflake's own ly (the desktop import above); the greeter lane
  # is not selected, so nothing else claims `services.greetd`.
  # Lock screen: chiyo does not select the shell aggregation, so it takes
  # dxflake's hyprlock dendrite on its own (imported above). Aoide's own
  # hyprland lane binds SUPER+ESCAPE to hyprlock directly and
  # shellbridge's powermenu Lock action shells the same binary — Aoide ships
  # no lockscreen anchor of its own yet (modules/dendrites/hyprlock.nix), so
  # the binary + PAM service are carved out and imported independently here.
  # Non-paint utilities the (unselected) shell aggregation used to carry.
  # wl-clipboard/cliphist/satty/hyprshot stay OFF: Aoide's clipboard and
  # screenshot lanes ship their own equivalents with matching systemd
  # services and keybinds — switching those packages on here would just
  # shadow them. brightnessctl and ydotool have no Aoide-side equivalent,
  # so this host selects those two by name: it does not select the shell
  # aggregation that would otherwise carry them.
  habit.dendrites.brightnessctl.enable = true;
  habit.dendrites.ydotool.enable = true;
  habit.dendrites.librewolf.enable = true;
  habit.dendrites.netbird.enable = true;
  # upowerd on the system bus — the bar's battery gauge and the power stele
  # read Quickshell.Services.UPower, a client only; without the daemon every
  # battery renders as absent ("AC — no battery present").
  services.upower.enable = true;
  # Host-specific Hyprland settings the shell aggregation would have carried: chiyo's
  # own monitor geometry, the fcitx5 IME autostart (fcitx5 itself stays on
  # via the desktop aggregation; only the exec-once trigger lived in the
  # shell aggregation's compositor dendrite), the env vars that session
  # used to set, and the brightness keys (a laptop-only bind AoideOS's own
  # behaviour dendrite doesn't carry — see modules/dendrites/compositor/hyprland/hyprland.nix's
  # header: media/brightness XF86 keys are deliberately out of its scope).
  # `settings` is a separate option from the `extraConfig`/`lines` option
  # Aoide's own lanes write to, so this merges alongside them
  # rather than colliding. Only chiyo's own entries are carried — the AOC/
  # Samsung monitor block belongs to osaka's host (its Hyprland monitor lines),
  # not chiyo. Keybinds/decoration are otherwise NOT carried:
  # AoideOS owns those (the hyprland lane above). Animations are carried:
  # Aoide writes none, and Hyprland's built-in global is 800 ms.
  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      monitor = [
        ", preferred, auto, 1"
        "eDP-1, 1920x1080@60, auto, 1"
      ];
      animation = [
        "global, 1, 3, default"
        "fade, 1, 2, default"
      ];
      "exec-once" = [ "fcitx5" ];
      env = [
        "XCURSOR_SIZE, 40"
        "QT_QPA_PLATFORMTHEME, qt5ct"
        "WLR_NO_HARDWARE_CURSORS, 1"
        "HYPRLAND_NO_START_WRAPPERS, 1"
      ];
      bind = [
        ", XF86MonBrightnessDown, exec, brightnessctl s 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl s 5%+"
      ];
    };
  };
  # No web service runs here (no services.caddy),
  # so this tunnel carries ssh only: sshHostnames routes straight to chiyo's
  # own sshd (already on by default, modules/dendrites/openssh.nix), with no
  # Caddy in the path. See modules/dendrites/cloudflared.nix for the
  # one-time `cloudflared tunnel create` + sops steps this depends on.
  dx.cloudflared = {
    tunnelId = "18bb461d-818f-4768-adb1-89b5f21e5a10";
    credentialsSopsFile = ../../secrets/cloudflared-chiyo.yaml;
    sshHostnames = [ "chiyo-ssh.necoconeco.net" ];
  };

  # The off-tailnet sync path. This laptop spends its day on wifi that lets 443
  # out and little else — controlplane.tailscale.com and syncthing's relays are
  # both blackholed there, so neither the tailnet nor the public relay can find
  # sakaki. sakaki therefore publishes its sync port through the tunnel as raw
  # TCP, and this side parks it on 127.0.0.1:22001, one of the addresses on
  # sakaki's device entry below. Nothing replaces the tailnet: the tunnel is
  # only the last address in the list.
  systemd.user.services.cloudflared-syncthing-sync = {
    description = "cloudflared access tcp to sakaki's syncthing sync port";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared access tcp --hostname syncthing-sync.necoconeco.net --url 127.0.0.1:22001";
      Restart = "always";
      RestartSec = 5;
    };
  };
  # The device entry keeps every path, in the order syncthing should try them:
  # `dynamic` (discovery + relays, for a network that lets them through),
  # MagicDNS `sakaki` (a direct tailnet dial — discovery alone would not find
  # it, since broadcast never crosses the tailnet), and the tunnel's local port
  # as the fallback. There is no LAN path to keep: sakaki opens 22000 only on
  # tailscale0. sakaki's own entry for chiyo stays `dynamic` — this side does
  # the dialing.
  services.syncthing.settings.devices.sakaki.addresses = [
    "dynamic"
    "tcp://sakaki:22000"
    "tcp://127.0.0.1:22001"
  ];
  boot = {
    initrd.kernelModules = [ "nvme" ];
    resumeDevice = "/dev/nvme0n1p3";
  };

  # Pins stateful-data formats from the first install; do not change it.
  system.stateVersion = "23.11";

}
