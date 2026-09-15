# Hyprland, as a compositor — and nothing else.
#
# This file is the `compositor` dendrite's hyprland provider. Its whole job is
# to make a Hyprland session RUN: the compositor package, the Wayland
# environment, the monitors, and the guarded handoff that hands this instance's
# environment to the systemd and D-Bus user managers. A host that selects it
# gets a working, navigable desktop and no opinions.
#
# Everything opinionated is an ecosystem dendrite selected by name. What is
# written against Hyprland itself — keybinds, decoration, autostart, hyprglass —
# lives under modules/dendrites/hyprland/ and is named by the compositor
# aggregation; the compositor-agnostic surfaces (waybar, rofi, satty, wlogout)
# sit at the dendrite root and are named by shell. docs/HYPRLAND-SPLIT.md maps
# every old block to its owner.
#
# Nothing here installs a package. Package membership is the shell
# aggregation's, and each ecosystem dendrite carries only what it itself calls.
{
  nixos =
    {
      username,
      ...
    }:
    {
      config = {
        programs.hyprland = {
          enable = true;
          withUWSM = true;
        };

        home-manager.users.${username} =
          {
            pkgs,
            lib,
            ...
          }:
          let
            # The guarded session handoff. See session-import.nix, and
            # hypr-session-import.sh for why it exists at all.
            sessionImport = import ./session-import.nix { inherit pkgs; };
          in
          {
            home.sessionVariables.NIXOS_OZONE_WL = "1";

            wayland.windowManager.hyprland = {
              enable = true;
              # ── Session handoff: guarded, not home-manager's ─────────────────────
              # `systemd.enable = false` switches OFF the two lines the HM module
              # would write at the top of hyprland.conf — and ONLY those two lines.
              # Everything they did still happens, from `exec-once`/`exec-shutdown`
              # below, through hypr-session-import: the environment import, the
              # target restart, the stop on exit. What changes is that each one now
              # asks Hyprland whether this instance owns the login session first.
              #
              # It has to be done here rather than through an HM option because the
              # generated line is `dbus-update-activation-environment … && systemctl
              # …` — `systemd.variables` and `systemd.extraCommands` are spliced into
              # the middle of that command, so neither can put a condition in front
              # of the part that does the damage.
              #
              # hyprland-session.target is re-declared below, identically, because it
              # is the other thing `systemd.enable` produced and waybar (through
              # graphical-session.target) and the portals are wantedBy it.
              systemd.enable = false;
              xwayland.enable = true;

              settings = {
                # Monitors
                #
                # osaka runs a sideways-T: the horizontal AOC meets the middle of the
                # rotated Samsung. The Samsung is 1080x1920 after transform 3 and stays
                # anchored at 1920x0, so the AOC (1080 tall) is dropped by
                # (1920-1080)/2 = 420 to center its full right edge inside the tall
                # panel — otherwise only the top ~half of the shared edge is crossable.
                # Panels are pinned by description so geometry survives a DP/HDMI port
                # swap. The scrolling rule in hyprland-keybinds still keys off the
                # HDMI-A-1 connector (m[] selectors can't hold a spaced description).
                monitor = [
                  ", preferred, auto, 1"
                  "eDP-1, 1920x1080@60, auto, 1.25"
                  "desc:AOC 24G1WG4 0x000391EC, 1920x1080@144, 0x420, 1"
                  "desc:Samsung Electric Company C24F390 HCNN907588, 1920x1080@60, 1920x0, 1, transform, 3"
                ];

                # Environment Variables
                env = [
                  "XCURSOR_SIZE, 40"
                  "QT_QPA_PLATFORMTHEME, qt5ct"
                  "WLR_NO_HARDWARE_CURSORS, 1"
                  "HYPRLAND_NO_START_WRAPPERS, 1"
                ];

                # FIRST, ahead of everything that needs a session: the environment
                # import and hyprland-session.target, guarded so a nested Hyprland
                # cannot move the real desktop into its own window.
                #
                # `mkBefore` is load-bearing now that hyprland-autostart contributes
                # to this same list from another file: list definitions concatenate
                # in module order, and nothing else fixes which file lands first.
                # tests/session-guard asserts the rendered ordering.
                "exec-once" = lib.mkBefore [
                  "${sessionImport}/bin/hypr-session-import start"
                ];

                # The other half of the handoff, and the sharper edge: unguarded,
                # closing a NESTED Hyprland stops the real session's target and takes
                # the desktop down with it.
                exec-shutdown = "${sessionImport}/bin/hypr-session-import stop";
              };
            };

            # ── hyprland-session.target ──────────────────────────────────────────
            # The other half of what `wayland.windowManager.hyprland.systemd.enable`
            # produced, kept verbatim from the home-manager module so that turning
            # its exec-once off changes nothing else. This target is the whole
            # session graph on these hosts: it BindsTo graphical-session.target, and
            # waybar, the portals and the Aoide user services all hang off that.
            # Deleting it — not guarding the exec-once — would be the change that
            # "disables the HM integration".
            systemd.user.targets.hyprland-session = {
              Unit = {
                Description = "Hyprland compositor session";
                Documentation = [ "man:systemd.special(7)" ];
                BindsTo = [ "graphical-session.target" ];
                Wants = [
                  "graphical-session-pre.target"
                  # `systemd.enableXdgAutostart = true` was the other setting this
                  # dendrite carried; these two lines are what it did.
                  "xdg-desktop-autostart.target"
                ];
                After = [ "graphical-session-pre.target" ];
                Before = [ "xdg-desktop-autostart.target" ];
                PropagatesStopTo = [ "graphical-session.target" ];
              };
            };
          };
      };
    };
}
