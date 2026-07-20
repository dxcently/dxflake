{
  pkgs,
  username,
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dx.aggregations.server {
    environment.systemPackages = [pkgs.jellyfin pkgs.jellyfin-web pkgs.jellyfin-ffmpeg];
    services.jellyfin = {
      enable = true;
      package = pkgs.jellyfin;
      openFirewall = true;
      user = username;
    };
    # MusicBrainz/TMDb lookups were failing TLS handshake — service unit had no
    # CA bundle path, unlike interactive shells which get it via NIX_SSL_CERT_FILE.
    systemd.services.jellyfin.environment = {
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    };
  };
}
