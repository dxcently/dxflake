{
  pkgs,
  config,
  ...
}: {
  programs = {
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
        thunar-media-tags-plugin
      ];
    };
    file-roller.enable = true;
  };

  services = {
    tumbler.enable = true;
  };
}
