{
  username,
  config,
  lib,
  ...
}: {
  options.dx.syncthing.enable = lib.mkEnableOption "syncthing";
  config = lib.mkIf (config.dx.aggregations.desktop || config.dx.syncthing.enable) {
    services = {
      syncthing = {
        enable = true;
        user = username;
        dataDir = "/home/${username}/Documents";
        configDir = "/home/${username}/.config/syncthing";
      };
    };
  };
}
