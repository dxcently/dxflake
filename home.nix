{
  inputs,
  lib,
  config,
  pkgs,
  theme,
  gtkThemeFromScheme,
  ...
}:

{

  colorScheme = inputs.nix-colors.colorSchemes."${theme}";

  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    inputs.nix-colors.homeManagerModules.default
    #inputs.nixvim.homeManagerModules.nixvim
    #inputs.hyprland.homeManagerModules.default
    #inputs.spicetify-nix.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    ./home-manager/imports.nix
  ];

  home = {
    username = "khoa";
    homeDirectory = "/home/khoa";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  # home.packages = with pkgs; [ steam ];

  # Enable home-manager and git
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
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
