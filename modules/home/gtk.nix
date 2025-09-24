{
  pkgs,
  config,
  ...
}: {
  gtk = {
    enable = true;
    iconTheme = {
      name = "windows10";
      package = pkgs.windows10-icons;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };
}
