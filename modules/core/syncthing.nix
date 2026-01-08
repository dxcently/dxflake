{
  pkgs,
  config,
  ...
}: {
  services = {
    syncthing = {
      enable = true;
      user = "khoa";
      dataDir = "/home/khoa/Documents";
      configDir = "/home/khoa/.config/syncthing";
    };
  };
}
