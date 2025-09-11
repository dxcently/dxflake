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
      base00 = "000000";
      base01 = "121212";
      base02 = "222222";
      base03 = "333333";
      base04 = "999999";
      base05 = "c1c1c1";
      base06 = "999999";
      base07 = "c1c1c1";
      base08 = "5f8787";
      base09 = "aaaaaa";
      base0A = "99bbaa";
      base0B = "ddeecc";
      base0C = "aaaaaa";
      base0D = "888888";
      base0E = "999999";
      base0F = "444444";
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
        terminal = 16;
        desktop = 16;
        popups = 12;
      };
    };
  };

  #stylix.image = ./
}
