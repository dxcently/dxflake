# gaming — Steam, gamescope and the launchers.
#
# Every member is a system capability; the home half is absent, which is a real
# answer rather than an empty placeholder.
{
  description = "Steam, gamescope and the launchers.";

  system = {
    members = [
      "aagl"
      "steam"
    ];

    # The launchers that are nothing but a package. Their lines live once, in
    # modules/dendrites/packages.nix; this aggregation switches its own nine on
    # by name. An install is not a selectable capability, so it gets no
    # catalogue line.
    nixos =
      { lib, ... }:
      {
        dx.packages =
          lib.genAttrs
            [
              "osu-lazer-bin"
              "lutris"
              "wine"
              "protonup-qt"
              "bottles"
              "prismlauncher"
              "r2modman"
              "winetricks"
              "protontricks"
            ]
            (_: {
              enable = true;
            });
      };
  };
}
