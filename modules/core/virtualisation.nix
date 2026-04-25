{
  pkgs,
  config,
  ...
}: {
  virtualisation = {
    libvirtd = {
      enable = true;
    };
    spiceUSBRedirection.enable = true;
    docker.enable = true;
    podman = {
      enable = true;
      dockerCompat = false;
    };
  };
}
