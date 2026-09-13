{
  pkgs,
  lib,
  username,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./users/khoa.nix
    ../../modules/dendrites/aoide.nix
    ../../modules/dendrites/autopsy.nix
    ../../modules/dendrites/bluetooth.nix
    ../../modules/dendrites/claude-code.nix
    ../../modules/dendrites/cloudflared.nix
    # desktop stays: it carries pipewire, fonts, fcitx5, portals, and ly
    # login — none of those collide with Aoide's paint. hyprland is not
    # imported, once the paint facets are on.
    ../../modules/dendrites/desktop
    ../../modules/dendrites/gpu-intel.nix
    ../../modules/dendrites/hyprlock.nix
    ../../modules/dendrites/kimi-cli.nix
    ../../modules/dendrites/laptop.nix
    ../../modules/dendrites/pi-coding-agent.nix
    ../../modules/dendrites/portmaster.nix
    ../../modules/dendrites/syncthing.nix
  ];
  dx.stylix.enable = false;

  # The door can exec an agent for peer-summoned sessions (`peer spawn
  # chiyo`), the same wiring sakaki carries — without it the door refuses
  # with "A2A spawn not configured" (observed live 2026-08-28, first
  # yomi→chiyo summon attempt after pairing).
  aoide.a2a = {
    spawnAgent = "claude";
    spawnPath = [ pkgs.claude-code ];
  };

  # chiyo is the full AoideOS carrier (L-C4, task #107): the complete Aoide
  # paint stack owns the session — compositor (Hyprland wiring + livery),
  # stylix (base16 fan-out), and quickshell (bar/dock/launcher/theming) —
  # replacing dxflake's own Hyprland + Stylix dendrites, which are turned off
  # above (hyprland is not imported, `dx.stylix.enable = false`) so only one
  # writer ever touches the leaf options the two stacks share (see
  # modules/dendrites/aoide.nix's header for the full collision reasoning).
  # aoide.hyprland.enable is the separate BEHAVIOUR dendrite (keybinds, input,
  # tiling layout) that pairs with the compositor facet's LOOK — without it
  # chiyo would have a themed but unusable session (no SUPER+SPACE launcher,
  # no window movement). aoide.song stays named explicitly for the same
  # reason yomi-strix's own flake names it: "sonata" is already the default,
  # but naming your song is good practice, not a sign it's a non-default pick.
  aoide.song = "sonata";
  aoide.facets.quickshell.enable = true;
  aoide.facets.compositor.enable = true;
  aoide.facets.stylix.enable = true;
  aoide.hyprland.enable = true;
  aoide.lyra.enable = true;

  # Same Rosé Pine override as osaka's (hosts/osaka/default.nix).
  aoide.livery.override = {
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

  # dunst is the notification DAEMON (org.freedesktop.Notifications, history,
  # pause levels) behind the quickshell herald, which only ever draws what
  # dunst feeds it — no dunst, no notifications reach the bar/dock at all.
  # Off by default (like every dendrite); named explicitly here, same as
  # yomi-strix's own line. Requires aoide.lyra.enable (already on above): the
  # herald-feed rule hands every notification to `lyra herald push`.
  aoide.dunst.enable = true;

  # Login stays dxflake's own ly (the desktop import above), not the
  # compositor facet's greetd stub — two session managers must never race the
  # same tty. The facet assigns `services.greetd.enable` plainly (true), so
  # only an mkForce wins here.
  services.greetd.enable = lib.mkForce false;

  # Lock screen: chiyo does not import the hyprland aggregate, so it takes
  # dxflake's hyprlock dendrite on its own (imported above). Aoide's own
  # hyprland dendrite binds SUPER+ESCAPE to hyprlock directly and
  # shellbridge's powermenu Lock action shells the same binary — Aoide ships
  # no lockscreen anchor of its own yet (modules/dendrites/hyprlock.nix), so
  # the binary + PAM service are carved out and imported independently here.

  # Non-paint utilities the (now-off) hyprland aggregation used to carry.
  # wl-clipboard/cliphist/satty/hyprshot are NOT re-added here: Aoide ships
  # its own equivalents with matching systemd services and keybinds
  # (aoide.clipboard.enable, aoide.screenshot.enable, both flipped below) —
  # duplicating the packages here would just shadow those. brightnessctl and
  # ydotool have no Aoide-side equivalent, so they're rescued directly.
  aoide.clipboard.enable = true;
  aoide.screenshot.enable = true;
  environment.systemPackages = with pkgs; [
    brightnessctl
    ydotool
  ];

  # upowerd on the system bus — the bar's battery gauge and the power stele
  # read Quickshell.Services.UPower, a client only; without the daemon every
  # battery renders as absent ("AC — no battery present").
  services.upower.enable = true;

  # Host-specific Hyprland settings that died with the aggregation: chiyo's
  # own monitor geometry, the fcitx5 IME autostart (fcitx5 itself stays on
  # via the desktop aggregation; only the exec-once trigger lived in the
  # aggregation's hyprland dendrite), the env vars the aggregation's session
  # used to set, and the brightness keys (a laptop-only bind AoideOS's own
  # behaviour dendrite doesn't carry — see modules/dendrites/hyprland.nix's
  # header: media/brightness XF86 keys are deliberately out of its scope).
  # `settings` is a separate option from the `extraConfig`/`lines` option
  # Aoide's own facets and dendrites write to, so this merges alongside them
  # rather than colliding. Only chiyo's own entries are carried — the AOC/
  # Samsung monitor block in the aggregation's hyprland dendrite belongs to
  # osaka, not chiyo. Keybinds/decoration/animations are otherwise NOT
  # carried: AoideOS owns those (aoide.hyprland.enable above).
  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      monitor = [
        ", preferred, auto, 1"
        "eDP-1, 1920x1080@60, auto, 1.25"
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

  # No web service runs here (no dx.caddy),
  # so this tunnel carries ssh only: sshHostnames routes straight to chiyo's
  # own sshd (already on by default, modules/nucleus/openssh.nix), with no
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
}
