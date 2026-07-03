{
  pkgs,
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dx.aggregations.gaming {
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = false;
        extraCompatPackages = [pkgs.proton-ge-bin];
        gamescopeSession.enable = true;
        protontricks.enable = true;
      };
      gamescope = {
        enable = true;
        capSysNice = true;
        args = [
          "--rt"
          "--expose-wayland"
        ];
      };
    };
  };
}
