{
  config,
  pkgs,
  ...
}: {
  #nix options
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    starship.enable = true;
    dconf.enable = true;
    bash.blesh.enable = true;
    nm-applet.enable = true;
    virt-manager.enable = true;
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
        thunar-media-tags-plugin
      ];
    };
    file-roller.enable = true;
    system-config-printer.enable = true;
  };
}
