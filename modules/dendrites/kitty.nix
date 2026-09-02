{username, config, lib, ...}: let
  # Conduct-by-default is CORE Aoide behaviour, not paint — a conducted shell is
  # a tracked, typeable-into session whether or not anything draws it, so this
  # keys on `aoide.enable` rather than on the Quickshell facet. The facet only
  # decides whether the dock's terminals gadget VISUALISES the graph. Concretely
  # that lands it on osaka and chiyo, skips sakaki (headless — this whole
  # dendrite is off there), and skips yomi-strix, which runs aoide.enable =
  # false and drives its own Aoide from a separate flake.
  conductShell = config.aoide.enable;

  # The aero glass keys on the FACET, not on aoide.enable: it is a look, and it
  # only pays off where something glosses it. hyprglass loads under the same
  # flag (modules/dendrites/hyprland/default.nix), and Hyprland's own blur pass
  # is what shows through the translucent cell background. On a facet-off host
  # this would just make terminals see-through with nothing behind them, so
  # yomi-strix keeps its opaque kitty untouched.
  aoideFace = config.aoide.facets.quickshell.enable;
in {
  config = lib.mkIf config.dx.aggregations.desktop {
    home-manager.users.${username} = {
      pkgs,
      config,
      lib,
      ...
    }: let
      # aoide-shell — kitty's login shell. Ported from Aoide's own kitty
      # dendrite; the ordering is the whole point, so it is kept intact rather
      # than tidied. Every branch ends in `exec`, so no failure mode can leave a
      # window without a shell:
      #   1. AOIDE_NO_CONDUCT set  → plain login shell (the escape hatch).
      #   2. no `aoide` on PATH    → plain login shell (never shell-less).
      #   3. otherwise             → conduct it, parented to AOIDE_SESSION_ID
      #      when one is already in the env, so a kitty opened from a conducted
      #      shell nests into the graph instead of starting a second root.
      #   4. conduct returned      → plain login shell anyway.
      #
      # Checked live on osaka before wiring rather than trusted: `aoide conduct`
      # runs the child, exports AOIDE_SESSION_ID, and registers/closes the
      # session — and with its root pointed at a nonexistent directory it STILL
      # runs the child instead of hanging, which is the failure mode that would
      # actually matter here (a wedged daemon must not wedge every terminal).
      aoide-shell = pkgs.writeShellScriptBin "aoide-shell" ''
        # Resolve the user's login shell robustly.
        login_shell="''${SHELL:-}"
        if [ -z "$login_shell" ] || [ ! -x "$login_shell" ]; then
          login_shell="$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f7)"
        fi
        if [ -z "$login_shell" ] || [ ! -x "$login_shell" ]; then
          login_shell=/bin/sh
        fi

        # (1) Escape hatch: never conduct when explicitly opted out.
        if [ -n "''${AOIDE_NO_CONDUCT:-}" ]; then
          exec "$login_shell" -l
        fi

        # (2) Never leave the user shell-less: only conduct if aoide is present.
        if ! command -v aoide >/dev/null 2>&1; then
          exec "$login_shell" -l
        fi

        # (3) Conduct this terminal as its own tracked, conductable session.
        if [ -n "''${AOIDE_SESSION_ID:-}" ]; then
          exec aoide conduct --agent shell --parent "$AOIDE_SESSION_ID" -- "$login_shell" -l
        else
          exec aoide conduct --agent shell -- "$login_shell" -l
        fi

        # (4) Belt-and-suspenders: conduct failed to exec — fall back cleanly.
        exec "$login_shell" -l
      '';
    in {
      # Configure Kitty
      programs.kitty = lib.mkForce {
        enable = true;
        package = pkgs.kitty;
        #set by stylix
        #font.name = "Lekton Nerd Font Mono";
        #font.size = 12;
        settings = lib.optionalAttrs conductShell {
          # Conduct-by-default: every kitty window's login shell is the wrapper
          # above. Opt a single window out with AOIDE_NO_CONDUCT=1 in its env.
          shell = "${aoide-shell}/bin/aoide-shell";
        } // {
          scrollback_lines = 2000;
          wheel_scroll_min_lines = 1;
          confirm_os_window_close = 0;
          window_padding_width = 5;
          window_border_width = 1.5;
          background_opacity = 1;
          background_blur = 1;
          enable_audio_bell = false;
          tab_bar_style = "powerline";
          tab_powerline_style = "slanted";
        }
        // lib.optionalAttrs aoideFace {
          # Aero-glass terminal, ported from Aoide's kitty dendrite. Only the
          # cell BACKGROUND goes translucent — glyphs stay fully opaque, so text
          # loses no contrast — and Hyprland blurs behind the resulting surface
          # for the frosted read. These two override the opaque defaults above,
          # which is why the merge order matters.
          background_opacity = "0.86";
          # OFF on purpose, not an oversight: kitty's own background_blur is a
          # macOS/KDE path and is inert under Hyprland. The compositor owns the
          # blur pass, so leaving this at dxflake's 1 would imply a second
          # blurrer that never runs.
          background_blur = 0;
        };
        keybindings = {
          "alt+j" = "next_window";
          "alt+k" = "previous_window";
          "alt+h" = "previous_tab";
          "alt+l" = "next_tab";
          "alt+enter" = "new_window_with_cwd";
          "alt+shift+t" = "new_tab_with_cwd";
          "alt+q" = "close_window";
          "ctrl+shift+U" = "none"; #for vim's page up
        };
        /*
        extraConfig = ''
          enabled_layouts fat:bias=80;full_size=1
          adjust_column_width -10
          foreground #${config.lib.stylix.colors.base01}
          background #${config.lib.stylix.colors.base00}
          color0  #${config.lib.stylix.colors.base00}
          color1  #${config.lib.stylix.colors.base01}
          color2  #${config.lib.stylix.colors.base02}
          color3  #${config.lib.stylix.colors.base03}
          color4  #${config.lib.stylix.colors.base04}
          color5  #${config.lib.stylix.colors.base05}
          color6  #${config.lib.stylix.colors.base06}
          color7  #${config.lib.stylix.colors.base07}
          color8  #${config.lib.stylix.colors.base08}
          color9  #${config.lib.stylix.colors.base09}
          color10 #${config.lib.stylix.colors.base0A}
          color11 #${config.lib.stylix.colors.base0B}
          color12 #${config.lib.stylix.colors.base0C}
          color13 #${config.lib.stylix.colors.base0D}
          color14 #${config.lib.stylix.colors.base0E}
          color15 #${config.lib.stylix.colors.base0F}
          cursor  #${config.lib.stylix.colors.base05}
          cursor_text_color #${config.lib.stylix.colors.base00}
          selection_foreground #${config.lib.stylix.colors.base01}
          selection_background #${config.lib.stylix.colors.base0D}
          url_color #${config.lib.stylix.colors.base0C}
          active_border_color #${config.lib.stylix.colors.base0A}
          inactive_border_color #${config.lib.stylix.colors.base09}
          bell_border_color #${config.lib.stylix.colors.base0A}
          active_tab_foreground   #${config.lib.stylix.colors.base01}
          active_tab_background   #${config.lib.stylix.colors.base00}
          inactive_tab_foreground #${config.lib.stylix.colors.base05}
          inactive_tab_background #${config.lib.stylix.colors.base04}
        '';
        */
      };
    };
  };
}
