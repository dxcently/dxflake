{
  username,
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dx.aggregations.desktop {
    home-manager.users.${username} = {
      pkgs,
      config,
      ...
    }: {
      programs.foliate.enable = true;
    };
  };
}
