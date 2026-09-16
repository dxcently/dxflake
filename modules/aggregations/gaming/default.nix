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

    # The launchers that are nothing but a package. Launchers are the group's own
    # install, so they are switched on by name right here rather than through the
    # fleet-wide list in modules/dendrites/packages.nix — either way it is the
    # aggregation's own installation membership, not a selectable capability.
    nixos =
      { pkgs, lib, ... }:
      {
        # Ordered last into system.path, like the other aggregation lists.
        environment.systemPackages = lib.mkAfter (
          with pkgs;
          [
            osu-lazer-bin # osu! lazer rhythm game
            lutris # open gaming platform
            wine # run Windows applications on Linux
            protonup-qt # GUI manager for Proton-GE/Wine-GE
            bottles # manage Wine prefixes with a GTK4 UI
            prismlauncher # Minecraft launcher
            r2modman # mod manager
            winetricks # helper for Wine prefixes
            protontricks # winetricks for Proton/Steam
          ]
        );
      };
  };
}
