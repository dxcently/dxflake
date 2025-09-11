{
  pkgs,
  config,
  lib,
  ...
}: {
  qt = {
    enable = true;
    platformTheme.name = lib.mkForce "qtct";
  };
}
