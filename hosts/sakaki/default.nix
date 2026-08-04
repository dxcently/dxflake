{ ... }: {
  imports = [
    ./hardware.nix
    ./syncthing.nix
  ];
  dx.aggregations.server = true;
  dx.claude-code.enable = true;
  dx.pi-coding-agent.enable = true;
  dx.kimi-cli.enable = true;
  dx.syncthing.enable = true;
  dx.autologin.enable = true;
  dx.melete.enable = true;
  dx.nas-mounts = {
    enable = true;
    mounts."/mnt/kaori-media" = {
      export = "/volume1/media";
      requiredBy = [
        "jellyfin"
        "slskd"
      ];
    };
  };
  dx.mneme.enable = true;
  dx.immich.enable = true;
  dx.slskd.enable = true;

  # Public face: Cloudflare Tunnel -> Caddy on loopback :8080. Media stays on
  # the tailnet; only the lightweight web UIs are exposed for now.
  dx.cloudflared = {
    enable = true;
    tunnelId = "304afa6f-0ac6-4d0e-abf1-206cde260bd3";
    hostnames = [
      "jellyfin.necoconeco.net"
      "syncthing.necoconeco.net"
    ];
  };
  dx.caddy = {
    enable = true;
    sites = {
      "jellyfin.necoconeco.net".proxy = "http://127.0.0.1:8096";
      "syncthing.necoconeco.net".proxy = "http://127.0.0.1:8384";
    };
  };
}
