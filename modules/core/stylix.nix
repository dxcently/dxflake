{
  pkgs,
  config,
  ...
}: {
  stylix = {
    enable = true;
    polarity = "dark";
    opacity.terminal = 1.0;
    base16Scheme = {
      #scheme: "Rosé Pine"
      #author: "Emilia Dunfelt <edun@dunfelt.se>"
      base00 = "191724";
      base01 = "1f1d2e";
      base02 = "26233a";
      base03 = "6e6a86";
      base04 = "908caa";
      base05 = "e0def4";
      base06 = "e0def4";
      base07 = "524f67";
      base08 = "eb6f92";
      base09 = "f6c177";
      base0A = "ebbcba";
      base0B = "31748f";
      base0C = "9ccfd8";
      base0D = "c4a7e7";
      base0E = "f6c177";
      base0F = "524f67";
    };
    cursor = {
      size = 28;
      package = pkgs.openzone-cursors;
      name = "OpenZone_White_Slim";
    };
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.lekton;
        name = "Lekton Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.nerd-fonts.lekton;
        name = "Lekton Nerd Font Mono";
      };
      serif = {
        package = pkgs.nerd-fonts.lekton;
        name = "Lekton Nerd Font Mono";
      };
      sizes = {
        applications = 12;
        terminal = 14;
        desktop = 12;
        popups = 12;
      };
    };
  };

  #stylix.image = ./
}
