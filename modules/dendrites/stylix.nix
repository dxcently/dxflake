{
  pkgs,
  config,
  lib,
  ...
}:
let
  aoideStylix = config.strillix.stylix.enable;
  # dxflake's floor scheme is transience's palette, the look the shell wears.
  # When a second look lands this moves behind a provider.
  transiencePalette = import ../aggregations/shell/transience/palette.nix;
in
{
  # The stylix option TREE comes from Aoide's nucleus on every host; a
  # second import here would be a second copy that does not deduplicate.
  # Selecting this dendrite is what applies dxflake's scheme. When Aoide's
  # stylix lane is active, this keeps only personal defaults and stays out of
  # color ownership for `stylix.base16Scheme`/`stylix.polarity`.
  config = {
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
        # Aoide's stylix lane pins polarity and owns the full resolved scheme
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

    habit.home = {
      stylix = {
        autoEnable = true;
        targets = {
          librewolf.enable = false;
          # Both write ~/.Xresources unconditionally; nothing here reads it, and its xrdb merge fails on Xwayland.
          xresources.enable = false;
          sxiv.enable = false;
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
}
