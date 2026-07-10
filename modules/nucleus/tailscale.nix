{ config, ... }: {
  services.tailscale = {
    enable = true;
    # Non-interactive enrollment: nodes join the tailnet on rebuild.
    authKeyFile = config.sops.secrets."tailscale/authkey".path;
    # Required for `tailscale funnel` — lets this user obtain the TLS cert.
    permitCertUid = "khoa";
    # Allow khoa to run `tailscale serve/funnel` without sudo.
    extraSetFlags = [ "--operator=khoa" ];
  };

  sops.secrets."tailscale/authkey".sopsFile = ../../secrets/tailscale.yaml;
}
