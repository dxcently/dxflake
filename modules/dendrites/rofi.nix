{username, ...}: {
  home-manager.users.${username} = {
    pkgs,
    config,
    inputs,
    ...
  }: {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi;
    };
  };
}
