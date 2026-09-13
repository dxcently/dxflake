{
  nixos = { ... }: {
    config = {
      services.flatpak.enable = true;
    };
  };
}
