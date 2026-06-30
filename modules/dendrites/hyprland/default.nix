{
  username,
  ...
}: {
  imports = [./packages.nix];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  programs.hyprlock.enable = true;
  security.pam.services.hyprlock = {};

  home-manager.users.${username}.imports = [
    ../../home/hyprland.nix
    ../../home/waybar.nix
    ../../home/hyprlock.nix
    ../../home/hyprpaper.nix
    ../../home/wlogout.nix
    ../../home/rofi.nix
    ../../home/swappy.nix
  ];
}
