{
  pkgs,
  inputs,
  ...
}: {
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 1w --keep 4";
    };
    flake = "/home/khoa/dxflake/";
  };
}
