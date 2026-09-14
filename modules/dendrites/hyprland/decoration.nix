# hyprland-decoration — how the desktop looks and moves.
#
# Gaps, borders, blur, shadows, animations, layout defaults. Split out because
# look is the axis most likely to be answered by something else: chiyo hands it
# to Aoide's compositor facet wholesale, and a host that wants dxflake's
# keybinds with someone else's paint says so by not selecting this.
#
# Border colour is the one place look reaches outside itself. When Aoide's
# stylix facet owns the palette the borders follow the resolved livery;
# otherwise they fall back to the flake's own plain white/black pair. Both
# branches were here before the split and neither changed.
{
  homeManager =
    {
      osConfig,
      lib,
      resolveAoideLivery,
      ...
    }:
    let
      ownsAoideStylix = osConfig.aoide.facets.stylix.enable;
      resolvedLivery = resolveAoideLivery osConfig.aoide.livery;
      liveryActiveBorder =
        if resolvedLivery.window.border != null then
          resolvedLivery.window.border
        else
          resolvedLivery.palette.accent;
      liveryInactiveBorder =
        if resolvedLivery.window.borderInactive != null then
          resolvedLivery.window.borderInactive
        else
          resolvedLivery.palette.bg;
      activeBorder =
        if ownsAoideStylix then "rgb(${lib.removePrefix "#" liveryActiveBorder})" else "rgba(ffffff99)";
      inactiveBorder =
        if ownsAoideStylix then "rgb(${lib.removePrefix "#" liveryInactiveBorder})" else "rgba(000000cc)";
    in
    {
      wayland.windowManager.hyprland.settings = {
        general = {
          gaps_in = 2;
          gaps_out = 4;
          border_size = 1;
          "col.active_border" = lib.mkForce activeBorder;
          "col.inactive_border" = lib.mkForce inactiveBorder;
          layout = "dwindle";
          allow_tearing = true;
        };

        decoration = {
          rounding = 0;
          blur = {
            enabled = true;
            size = 2;
            passes = 2;
            xray = true;
            vibrancy_darkness = 1.0;
            ignore_opacity = true;
            new_optimizations = true;
          };
          shadow = {
            enabled = false;
            range = 4;
            render_power = 3;
            scale = 1.0;
          };
        };

        # Hyprland's own blur is what layer surfaces sit on. The waybar rule is
        # this flake's own bar; the Aoide surfaces' rules ride hyprglass, which
        # refracts over the blur this produces.
        layerrule = [
          "blur on, match:namespace waybar"
        ];

        animations = {
          enabled = true;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        dwindle = {
          preserve_split = true;
        };

        master = {
          new_status = "master";
        };

        # HDMI-A-1 is a vertical monitor (transform 3). Its workspaces use the
        # scrolling layout below; the tape grows downward so windows stack
        # top-to-bottom and you scroll through them instead of shrink-to-fit.
        scrolling = {
          direction = "down";
        };

        misc = {
          force_default_wallpaper = -1;
        };

        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
      };
    };
}
