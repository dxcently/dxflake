{
  pkgs,
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dx.aggregations.gaming {
    environment.systemPackages = with pkgs; [
      osu-lazer-bin # osu! lazer rhythm game
      lutris # open gaming platform
      wine # run Windows applications on Linux
      protonup-qt # GUI manager for Proton-GE/Wine-GE
      bottles # manage Wine prefixes with a GTK4 UI
      prismlauncher # Minecraft launcher
      r2modman # mod manager
      winetricks # helper for Wine prefixes
      protontricks # winetricks for Proton/Steam
    ];
  };
}
