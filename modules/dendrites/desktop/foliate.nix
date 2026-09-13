{
  username,
  ...
}: {
  config = {
    home-manager.users.${username} = {
      pkgs,
      config,
      ...
    }: {
      programs.foliate.enable = true;
    };
  };
}
