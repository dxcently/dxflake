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
