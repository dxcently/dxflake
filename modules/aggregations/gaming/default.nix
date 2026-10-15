# gaming — Steam, gamescope and the launchers.
#
# Every member is a system capability; the home half is absent, which is a real
# answer rather than an empty placeholder.
{
  description = "Steam, gamescope and the launchers.";

  system.members = [
    "steam"

    # The launchers that are nothing but a package, one catalogue entry each.
    "osu-lazer-bin"
    "lutris"
    "wine"
    "protonup-qt"
    "bottles"
    "prismlauncher"
    "r2modman"
    "winetricks"
    "protontricks"
  ];
}
