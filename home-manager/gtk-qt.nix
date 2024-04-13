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
      };
      /*
        theme = {
          name = "${config.colorScheme.slug}";
          package = gtkThemeFromScheme {scheme = config.colorScheme;};
        };
      */
      iconTheme = {
        name = "Arc";
        package = pkgs.arc-icon-theme;
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
    name = "Catppuccin-Macchiato-Rosewater-Cursors";
    package = pkgs.catppuccin-cursors.macchiatoRosewater;
    size = 28;
  };
}
