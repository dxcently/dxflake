# song/songbook/transience/palette.nix — the one source of the transience palette.
# Rosé Pine, dark, the sixteen this desktop has always worn.
#
# Bare hex is canonical, because that is what modules/dendrites/stylix.nix's
# `base16Scheme` wants untouched. Aoide's v0 livery schema wants `#rrggbb`;
# `withHash` adds the character back so no hex is ever written twice. Both
# consumers import this file directly:
#   * stylix.nix reads `.base16` for `stylix.base16Scheme`.
#   * regen-livery.sh reads `.livery` and writes it out as livery.json.
let
  base16 = {
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

  # The five livery anchors, each naming the base16 slot it is.
  anchors = {
    bg = base16.base00;
    fg = base16.base05;
    accent = base16.base0A;
    urgent = base16.base08;
    hot = base16.base0C;
  };

  withHash = builtins.mapAttrs (_: v: "#${v}");
in
{
  inherit base16;

  # Aoide's v0 livery schema, hash-prefixed. livery.json is generated from
  # exactly this attrset by regen-livery.sh.
  livery = {
    schemaVersion = "0";
    palette = withHash anchors;
    base16 = withHash base16;
    bar = withHash {
      bg = anchors.bg;
      fg = anchors.fg;
      accent = anchors.accent;
    };
    notif = withHash {
      bg = anchors.bg;
      fg = anchors.fg;
      urgent = anchors.urgent;
    };
    window = withHash {
      border = anchors.accent;
      borderInactive = anchors.bg;
    };
  };
}
