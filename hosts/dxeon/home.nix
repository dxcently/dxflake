{
  inputs,
  lib,
  config,
  pkgs,
  theme,
  gtkThemeFromScheme,
  ...
}: {
  colorScheme = inputs.nix-colors.colorSchemes."${theme}";

  imports = [
    inputs.nix-colors.homeManagerModules.default
    # You can also split up your configuration and import pieces of it here:
    ../../home-manager/imports.nix
  ];

  home = {
    username = "khoa";
    homeDirectory = "/home/khoa";
  };

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "dxcently";
      userEmail = "dxcently@gmail.com";
    };
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
