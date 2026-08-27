{ ... }: {
  imports = [ ./hardware.nix ];
  dx.aggregations = {
    desktop = true;
    hyprland = true;
  };
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

  # chiyo is the first host to carry lyra (the paint/rice binary) beside the
  # core door — the minimal paint substrate, not the full desktop shape.
  # aoide.facets.quickshell.enable is the actual render surface (bar/dock/
  # notifications/…, modules/facets/quickshell); aoide.lyra.enable installs
  # the `lyra` CLI that composes/mints a rice for it to render (it would
  # default to following quickshell.enable — named explicitly here since
  # this pairing IS the point of this host). Deliberately NOT
  # aoide.facets.compositor or aoide.facets.stylix: chiyo already runs
  # dxflake's own Hyprland + Stylix dendrites (dx.aggregations.hyprland/
  # desktop above), which already provide the graphical session quickshell
  # needs (graphical-session.target, WAYLAND_DISPLAY/
  # HYPRLAND_INSTANCE_SIGNATURE imported) — Aoide's own compositor/stylix
  # facets would duplicate that work and collide with it (both assign
  # `wayland.windowManager.hyprland.systemd.variables` and `stylix.
  # base16Scheme` outright; see modules/dendrites/aoide.nix's header for the
  # full reasoning). aoide.song stays named explicitly for the same reason
  # yomi-strix's own flake names it: "sonata" is already the default, but
  # naming your song is good practice, not a sign it's a non-default pick.
  aoide.song = "sonata";
  aoide.facets.quickshell.enable = true;
  aoide.lyra.enable = true;

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
    tunnelId = "REPLACE_WITH_CHIYO_TUNNEL_UUID";
    credentialsSopsFile = ../../secrets/cloudflared-chiyo.yaml;
    sshHostnames = [ "chiyo-ssh.necoconeco.net" ];
  };

  boot = {
    initrd.kernelModules = [ "nvme" ];
    resumeDevice = "/dev/nvme0n1p3";
  };
}
