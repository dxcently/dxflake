{
  pkgs,
  config,
  ...
}: {
  stylix = {
    enable = true;
    polarity = "light";
    opacity.terminal = 1.0;
    base16Scheme = {
      #name: Atelier Seaside Light
      #author: Bram de Haan (http://atelierbramdehaan.nl)
      base00 = "f4fbf4";
      base01 = "cfe8cf";
      base02 = "8ca68c";
      base03 = "809980";
      base04 = "687d68";
      base05 = "5e6e5e";
      base06 = "242924";
      base07 = "131513";
      base08 = "e6193c";
      base09 = "87711d";
      base0A = "98981b";
      base0B = "29a329";
      base0C = "1999b3";
      base0D = "3d62f5";
      base0E = "ad2bee";
      base0F = "e619c3";
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
