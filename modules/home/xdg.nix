{
  pkgs,
  config,
  ...
}: {
  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps = {
      enable = true;
    };
  };
}
