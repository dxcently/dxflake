# waybar — the bar runs. What it LOOKS like is the rice's.
#
# This dendrite is wiring only: the program, and the deliberate choice not to
# let home-manager start it. The stylesheet and the bar's composition live in
# the selected rice (songbook/<rice>/rice.nix), so a host can change how the
# desktop looks without touching whether the bar exists.
{
  homeManager = _: {
    programs.waybar = {
      enable = true;
      # Started from hyprland's `exec-once`, not by home-manager: the bar has to
      # come up after the compositor has a session to draw on, and the autostart
      # dendrite is where that ordering already lives.
      systemd = {
        enable = false;
        targets = [ "graphical-session.target" ];
      };
    };
  };
}
