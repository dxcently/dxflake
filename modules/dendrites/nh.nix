{username, ...}: {
  home-manager.users.${username} = {
    pkgs,
    inputs,
    ...
  }: {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 1w --keep 10";
      };
      flake = "/home/khoa/dxflake/";
    };
  };
}
