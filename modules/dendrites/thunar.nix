{
  pkgs,
  config,
  ...
}: {
  programs = {
    thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
        thunar-media-tags-plugin
      ];
    };
  };

  services = {
    tumbler.enable = true;
    # file-manager substrate — automount, mount-without-root, trash/mtp/network
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;
  };
}
