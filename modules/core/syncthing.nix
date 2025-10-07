{
  pkgs,
  config,
  ...
}: {
  services = {
    syncthing = {
      enable = false;
      user = "khoa";
      dataDir = "/home/khoa/school/refile";
      configDir = "/home/khoa/.config/syncthing";
    };
  };
}
