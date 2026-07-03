{username, config, lib, ...}: {
  config = lib.mkIf config.dx.aggregations.desktop {
    home-manager.users.${username} = {
      pkgs,
      config,
      ...
    }: {
      gtk = {
        enable = true;
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
      };
    };
  };
}
