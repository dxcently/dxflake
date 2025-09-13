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
      #scheme: "Equilibrium Light"
      #author: "Carlo Abelli"
      base00 = "f5f0e7";
      base01 = "e7e2d9";
      base02 = "d8d4cb";
      base03 = "73777f";
      base04 = "5a5f66";
      base05 = "43474e";
      base06 = "2c3138";
      base07 = "181c22";
      base08 = "d02023";
      base09 = "bf3e05";
      base0A = "9d6f00";
      base0B = "637200";
      base0C = "007a72";
      base0D = "0073b5";
      base0E = "4e66b6";
      base0F = "c42775";
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
