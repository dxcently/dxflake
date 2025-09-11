{
  pkgs,
  config,
  ...
}: {
  gtk = {
    enable = true;
    iconTheme = {
      name = "faba-icon-theme";
      package = pkgs.faba-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };
}
