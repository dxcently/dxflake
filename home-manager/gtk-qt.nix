{
  pkgs,
  config,
  gtkThemeFromScheme,
  ...
}:

{

  gtk =
    let
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    in
    {
      enable = true;
      font = {
        name = "ShureTechMono Nerd Font";
        size = 12;
        package = pkgs.nerdfonts;
      };
      theme = {
        name = "rose-pine";
        package = pkgs.rose-pine-gtk-theme;
      };
      iconTheme = {
        name = "rose-pine";
        package = pkgs.rose-pine-icon-theme;
      };
      gtk3 = {
        inherit extraConfig;
      };
      gtk4 = {
        inherit extraConfig;
      };
    };
  qt = {
    enable = true;
    platformTheme = "gtk";
    style = {
      name = "rose-pine";
      package = pkgs.rose-pine-gtk-theme;
    };
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  /*
    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package =
    };
  */
}
