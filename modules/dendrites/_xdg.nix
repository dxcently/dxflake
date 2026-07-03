{username, config, lib, ...}: {
  options.dx.xdg.enable = lib.mkEnableOption "xdg";
  config = lib.mkIf config.dx.xdg.enable {
    home-manager.users.${username} = {
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
    };
  };
}
