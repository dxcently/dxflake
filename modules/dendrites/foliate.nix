{
  homeManager =
    {
      pkgs,
      config,
      ...
    }:
    {
      programs.foliate.enable = true;
    };
}
