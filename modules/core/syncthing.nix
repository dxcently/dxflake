{
  pkgs,
  config,
  ...
}: {
  services = {
    syncthing = {
      enable = false;
      user = "khoa";
      dataDir = "/home/khoa/Documents/school/s2025/refile";
      configDir = "/home/khoa/.config/syncthing";
    };
  };
}
