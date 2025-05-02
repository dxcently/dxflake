{
  inputs,
  lib,
  config,
  pkgs,
  theme,
  ...
}: {
  colorScheme = inputs.nix-colors.colorSchemes."${theme}";

  imports = [
    ./../../modules/home
  ];

  home = {
    username = "khoa";
    homeDirectory = "/home/khoa";
  };

  programs = {
    home-manager.enable = true;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
