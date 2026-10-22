# chiyo — the laptop, and the full AoideOS paint carrier.
{
  pkgs,
  username,
  ...
}:
{
  habit.rice.declared = "sonata";
  # Built in, not performed: barcarolle is in the runtime rices, staged from
  # the RICE menu or `strx rice mode stage barcarolle`, without a rebuild.
  habit.rice.available = [ "barcarolle" ];

  habit.aggregation = {
    nucleus.enable = true;
    aoide.enable = true;
    network.enable = true;
    # desktop stays: it carries pipewire, fonts, fcitx5 and portals — none of
    # those collide with Aoide's paint. Login is ly, themed from strillix.theme, because sonata ships no
    # greeter face. The shell aggregation is NOT
    # selected here: Aoide's lanes paint instead.
    desktop.enable = true;
  };

  habit.dendrites = {
    aoide.enable = true;
    # Aoide's paint carrier: the Quickshell surface, the strillix runtime, the dunst daemon
    # behind the notifications daemon, Aoide's own clipboard and screenshot services, the
    # hyprland behaviour lane (keybinds, input, tiling), and the stylix and
    # compositor lanes (catalogued as aoide-stylix and aoide-compositor).
    quickshell.enable = true;
    strillix.enable = true;
    dunst.enable = true;
    clipboard.enable = true;
    screenshot.enable = true;
    hyprland.enable = true;
    aoide-stylix.enable = true;
    aoide-compositor = {
      enable = true;
      provider = "hyprland";
    };
    autopsy.enable = true;
    bluetooth.enable = true;
    claude-code.enable = true;
    claude-desktop.enable = true;
    cloudflared.enable = true;
    eidolon.enable = true;
    gpu = {
      enable = true;
      provider = "intel";
    };
    lock = {
      enable = true;
      provider = "hyprlock";
    };
    kimi-cli.enable = true;
    laptop.enable = true;
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
  # The file `strx rice declare --host` and the Declare button rewrite.
  strillix.hostConfig = "/home/${username}/dxflake/hosts/chiyo/default.nix";
  # chiyo is the full AoideOS carrier: the complete Aoide paint stack owns the
  # session — compositor (Hyprland wiring + theme), stylix (base16 fan-out),
  # and quickshell (bar/dock/launcher/theming) — replacing dxflake's own
  # Hyprland + Stylix dendrites, which stay unselected here so only one writer
  # ever touches the leaf options the two stacks
  # share (see modules/dendrites/aoide.nix's header for the collision
  # reasoning). The hyprland lane is the BEHAVIOUR half (keybinds, input,
  # tiling layout) that pairs with the compositor lane's LOOK — without it
  # chiyo would have a themed but unusable session (no SUPER+SPACE launcher,
  # no window movement).
  # Rosé Pine over whichever rice chiyo performs (osaka applies it to sonata only).
  # Blur re-renders behind every moving window; the UHD 620 can't afford it.
  strillix.theme.geometry.blurEnabled = false;
  strillix.theme.override = {
    bg = "#191724";
    fg = "#e0def4";
    accent = "#ebbcba";
    urgent = "#eb6f92";
    hot = "#31748f";
    base16 = {
      base01 = "#1f1d2e";
      base02 = "#26233a";
      base03 = "#6e6a86";
      base04 = "#908caa";
      base06 = "#e0def4";
      base07 = "#524f67";
      base09 = "#f6c177";
      base0C = "#9ccfd8";
      base0D = "#c4a7e7";
      base0E = "#f6c177";
      base0F = "#524f67";
    };
    window.borderInactive = "#9ccfd8";
  };
  stylix.polarity = "dark";
  # The palette is baked into gtksourceview, so every theme change rebuilt
  # it (and virt-manager above it) here, where its 30 s test timeout fails.
  stylix.targets.gtksourceview.enable = false;
  # Login is ly, themed from strillix.theme: sonata ships no greeter face, so Aoide's greeter falls back to ly on tty1.
  # Lock screen: chiyo does not select the shell aggregation, so it takes
  # dxflake's hyprlock provider of the lock slot (set above). Aoide's own
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
  boot = {
    initrd.kernelModules = [ "nvme" ];
    resumeDevice = "/dev/nvme0n1p3";
  };

  # Pins stateful-data formats from the first install; do not change it.
  system.stateVersion = "23.11";

}
