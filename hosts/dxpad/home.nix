{
  inputs,
  lib,
  config,
  pkgs,
  theme,
  gtkThemeFromScheme,
  ...
}: {
  imports = [
    ./../../modules/home
  ];

  home = {
    username = "khoa";
    homeDirectory = "/home/khoa";
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
