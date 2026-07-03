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
  };
}
