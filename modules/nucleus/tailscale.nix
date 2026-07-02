{ config, ... }: {
  services.tailscale = {
    enable = true;
    # Non-interactive enrollment: nodes join the tailnet on rebuild.
    authKeyFile = config.sops.secrets."tailscale/authkey".path;
  };

  sops.secrets."tailscale/authkey".sopsFile = ../../secrets/tailscale.yaml;
}
