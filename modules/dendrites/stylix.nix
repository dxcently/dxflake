{
  nixos =
    {
      pkgs,
      config,
      inputs,
      username,
      lib,
      ...
    }:
    let
      aoideStylix = config.aoide.facets.stylix.enable;
      # dxflake ships one rice today, so the floor's fixed scheme is that
      # rice's palette. When a second rice lands this moves behind the `rice`
      # provider (song/songbook/default.nix).
      transiencePalette = import ../../song/songbook/transience/palette.nix;
    in
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      # The stylix option TREE stays imported unconditionally above (Aoide's own
      # stylix facet probes for its presence via `options ? stylix`, so the module
      # must always ride every host — this is the one dendrite that stays in the
      # floor). Whether THIS dendrite's dxflake scheme actually applies is a
      # separate question, gated on dx.stylix.enable, off by default: a host
      # names it explicitly. When Aoide's stylix facet is active, dx.stylix keeps
      # only personal defaults and stays out of color ownership for
      # `stylix.base16Scheme`/`stylix.polarity`.
      options.dx.stylix.enable = lib.mkEnableOption "dxflake's own Stylix theme (Rosé Pine)";
      config = lib.mkIf config.dx.stylix.enable {
        stylix =
          (
            {
              enable = true;
            }
            // lib.optionalAttrs (!aoideStylix) {
              polarity = "dark";
              base16Scheme = transiencePalette.base16;
            }
          )
          // {
            # Aoide's stylix facet pins polarity and owns the full resolved scheme
            # when active; only fixed-theme hosts keep the Rosé Pine dark contract.
            opacity.terminal = 1.0;
            icons = {
              enable = true;
              package = pkgs.windows10-icons;
              dark = "windows10";
              light = "windows10";
            };
            cursor = {
              size = 40;
              package = pkgs.maplestory-cursor;
              name = "Maple";
            };
            fonts = {
              # ucs-fonts: Markus Kuhn's X11 misc set, the Unicode-extended
              # sibling of the `font-misc-misc` faces the xserver closure
              # already puts on a desktop host. Every face is a pixel bitmap
              # (.pcf.gz / .otb, 4x6 … 18x18ja/ko), so a point size snaps to
              # the nearest authored pixel size rather than scaling, and the
              # family is declared once: all faces answer to `Fixed` — 12x13ja
              # for the bare family, 7x13 for `Fixed:style=Regular`.
              monospace = {
                package = pkgs.ucs-fonts;
                name = "Fixed";
              };
              sansSerif = {
                package = pkgs.ucs-fonts;
                name = "Fixed";
              };
              serif = {
                package = pkgs.ucs-fonts;
                name = "Fixed";
              };
              sizes = {
                applications = 14;
                terminal = 14;
                desktop = 14;
                popups = 12;
              };
            };
          };

        #stylix.image = ./

        home-manager.users.${username} = {
          stylix = {
            autoEnable = true;
            targets = {
              librewolf.enable = false;
              gtk.enable = true;
              kitty.enable = true;
              neovim.enable = false;
              nvf.enable = false;
              waybar.enable = false;
              vesktop.enable = false;
              qt = {
                enable = true;
                platform = "qtct";
              };
            };
          };
        };
      };
    };
}
