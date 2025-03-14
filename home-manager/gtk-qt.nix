{
  pkgs,
  config,
  gtkThemeFromScheme,
  ...
}: let
  palette = config.colorScheme.palette;
in {
  gtk = let
    extraConfig = {
      #gtk-application-prefer-light = 0;
    };
  in {
    enable = true;
    font = {
      name = "Lekton Nerd Font Mono";
      size = 12;
    };
    /*
    theme = {
      name = "Catppuccin-Macchiato-Compact-Rosewater-Light";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "rosewater" ];
        tweaks = [
          "rimless"
          "normal"
        ];
        variant = "macchiato";
        size = "compact";
      };
    };
    */

    theme = {
      name = "${config.colorScheme.slug}";
      package = gtkThemeFromScheme {scheme = config.colorScheme;};
    };

    iconTheme = {
      name = "faba-icon-theme";
      package = pkgs.faba-icon-theme;
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
      name = "kvantum";
    };
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.openzone-cursors;
    name = "OpenZone_White_Slim";
    size = 28;
  };
}
