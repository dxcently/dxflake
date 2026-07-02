{username, ...}: {
  home-manager.users.${username} = {
    pkgs,
    config,
    lib,
    ...
  }: {
    qt = {
      enable = true;
      platformTheme.name = lib.mkForce "qtct";
    };
  };
}
