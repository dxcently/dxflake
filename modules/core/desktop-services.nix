{
  pkgs,
  config,
  ...
}: {
  services = {
    devmon.enable = true;
    blueman.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
    flatpak.enable = true;
    printing.enable = true;
  };
}
