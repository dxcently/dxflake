{
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [ ./hardware.nix ];
  dx.aggregations = {
    # desktop stays true: it carries pipewire, fonts, fcitx5, portals, and ly
    # login — none of those collide with Aoide's paint. hyprland flips off
    # below, once the paint facets are on.
    desktop = true;
    hyprland = false;
  };
  dx.stylix.enable = false;
  dx.bluetooth.enable = true;
  dx.claude-code.enable = true;
  dx.pi-coding-agent.enable = true;
  dx.kimi-cli.enable = true;
  dx.syncthing.enable = true;
  dx.laptop.enable = true;
  # consolidated to sakaki-only, 2026-07-31
  dx.melete.enable = false;
  dx.gpu-intel.enable = true;

  # Core Aoide (modules/dendrites/aoide.nix: binaries + aoided + the A2A
  # door + the secrets broker), joining the yomi-strix/sakaki/osaka
  # federation mesh — same baseline as those two, no host-specific a2a/
  # secrets knobs set here yet.
  dx.aoide.enable = true;

  # chiyo is the full AoideOS carrier (L-C4, task #107): the complete Aoide
  # paint stack owns the session — compositor (Hyprland wiring + livery),
  # stylix (base16 fan-out), and quickshell (bar/dock/launcher/theming) —
  # replacing dxflake's own Hyprland + Stylix dendrites, which are turned off
  # above (`dx.aggregations.hyprland = false`, `dx.stylix.enable = false`) so
  # only one writer ever touches the leaf options the two stacks share (see
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

  # dunst is the notification DAEMON (org.freedesktop.Notifications, history,
  # pause levels) behind the quickshell herald, which only ever draws what
  # dunst feeds it — no dunst, no notifications reach the bar/dock at all.
  # Off by default (like every dendrite); named explicitly here, same as
  # yomi-strix's own line. Requires aoide.lyra.enable (already on above): the
  # herald-feed rule hands every notification to `lyra herald push`.
  aoide.dunst.enable = true;

  # Login stays dxflake's own ly (dx.aggregations.desktop above), not the
  # compositor facet's greetd stub — two session managers must never race the
  # same tty. The facet assigns `services.greetd.enable` plainly (true), so
  # only an mkForce wins here.
  services.greetd.enable = lib.mkForce false;

  # Lock screen: dxflake's hyprlock dendrite normally rides the hyprland
  # aggregation (now off above), but Aoide's own hyprland dendrite binds
  # SUPER+ESCAPE to hyprlock directly and shellbridge's powermenu Lock action
  # shells the same binary — Aoide ships no lockscreen anchor of its own yet
  # (modules/dendrites/hyprlock.nix), so the binary + PAM service are carved
  # out and re-enabled independently here.
  dx.hyprlock.enable = true;

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

  # chiyo lives mostly on public/corporate wifi that blocks WireGuard and
  # tailscale outright, so the tailnet can't be relied on to reach it. A
  # Cloudflare Tunnel only ever dials OUT to the Cloudflare edge over https,
  # which those networks let through — so it's the one mechanism that
  # survives chiyo's usual network. No web service runs here (no dx.caddy),
  # so this tunnel carries ssh only: sshHostnames routes straight to chiyo's
  # own sshd (already on by default, modules/nucleus/openssh.nix), with no
  # Caddy in the path. See modules/dendrites/cloudflared.nix for the
  # one-time `cloudflared tunnel create` + sops steps this depends on.
  dx.cloudflared = {
    enable = true;
    tunnelId = "18bb461d-818f-4768-adb1-89b5f21e5a10";
    credentialsSopsFile = ../../secrets/cloudflared-chiyo.yaml;
    sshHostnames = [ "chiyo-ssh.necoconeco.net" ];
  };

  boot = {
    initrd.kernelModules = [ "nvme" ];
    resumeDevice = "/dev/nvme0n1p3";
  };
}
