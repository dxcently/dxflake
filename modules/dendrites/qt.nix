{username, config, lib, ...}: {
  config = lib.mkIf config.dx.aggregations.desktop {
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
  };
}
