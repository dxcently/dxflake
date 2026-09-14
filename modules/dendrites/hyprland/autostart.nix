# hyprland-autostart — what the session launches once it is up.
#
# The compositor provider starts the session; this starts the things that live
# in it. Split out because "which programs come up with my desktop" is the most
# host-specific question in the whole Hyprland stack, and answering it
# differently should not mean forking the compositor.
#
# The guarded session handoff is NOT here. It is an `exec-once` too, but it is
# the compositor's own bootstrap and must run FIRST — see
# modules/dendrites/compositor/hyprland.nix, which pins it with `lib.mkBefore`
# ahead of everything in this list. tests/session-guard asserts that ordering
# against the rendered config, so it cannot drift back.
{
  homeManager =
    {
      pkgs,
      osConfig,
      lib,
      ...
    }:
    let
      # Aoide's Quickshell facet is a SURFACE owner: once it is on it draws the
      # bar, the wallpaper, the launcher, the OSD and the notification herald
      # itself. dxflake's own waybar + awww draw the same surfaces, so on a host
      # that flips the facet they must stand down or both stacks paint at once —
      # two bars layered, two wallpapers racing the same output.
      #
      # Keyed on the facet flag, never on a host name. Read through `osConfig`
      # because the flag is a NixOS option and this is a home lane.
      aoideFace = osConfig.aoide.facets.quickshell.enable;
    in
    {
      # This dendrite's own dependency, not free-floating membership: the
      # `systemctl --user start` below is its only caller, and the unit it
      # starts ships inside the package.
      home.packages = [ pkgs.hyprpolkitagent ];

      # The wallpaper + bar block is spliced in place (not appended) so that
      # with `aoideFace` off the list is character-for-character what it was
      # before the facet seam existed — order included. awww-daemon leaves with
      # its two `img` calls: nothing else drives it, and a daemon with no image
      # to hold is just a process sitting on the Quickshell wallpaper surface's
      # output.
      wayland.windowManager.hyprland.settings."exec-once" = [
        "systemctl --user start hyprpolkitagent"
        "nm-applet --indicator"
        "systemd"
        "hypridle"
      ]
      ++ lib.optionals (!aoideFace) [
        "awww-daemon"
        "awww img -o DP-1 ~/dxflake/assets/wallpapers/hero.webp"
        "awww img -o HDMI-A-1 ~/dxflake/assets/wallpapers/yuki-standing.png"
        "waybar"
      ]
      ++ [
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "fcitx5"
        "[workspace 1 silent] zen"
      ];
    };
}
