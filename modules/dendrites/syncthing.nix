{
  username,
  ...
}: {
  services = {
    syncthing = {
      enable = true;
      user = username;
      dataDir = "/home/${username}/Documents";
      configDir = "/home/${username}/.config/syncthing";
    };
  };
}
