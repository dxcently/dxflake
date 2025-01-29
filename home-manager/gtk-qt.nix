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
      name = "ShureTechMono Nerd Font";
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
      name = "elementary-xfce-icon-theme";
      package = pkgs.elementary-xfce-icon-theme;
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
      /*
      name = "Catppuccin-Macchiato-Compact-Rosewater-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "rosewater" ];
        tweaks = [
          "rimless"
          "normal"
        ];
        variant = "macchiato";
        size = "compact";
      };
      */
      name = "adwaita-light";
      package = pkgs.adwaita-qt;
    };
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-light";
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Catppuccin-Macchiato-Rosewater-Cursors";
    package = pkgs.catppuccin-cursors.macchiatoRosewater;
    size = 28;
  };
}
