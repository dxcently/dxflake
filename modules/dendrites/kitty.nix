{
  nixos =
    {
      username,
      config,
      lib,
      ...
    }:
    let
      # Conduct-by-default is CORE Aoide behaviour, not paint — a conducted shell is
      # a tracked, typeable-into session whether or not anything draws it, so this
      # keys on `aoide.enable` rather than on `aoide.quickshell.enable`. The shell only
      # decides whether the dock's terminals gadget VISUALISES the graph. Concretely
      # that lands it on osaka and chiyo, skips sakaki (headless — this whole
      # dendrite is off there), and skips yomi-strix, which runs aoide.enable =
      # false and drives its own Aoide from a separate flake.
      conductShell = config.aoide.enable;

      # `aoide.quickshell.enable` gates one thing here: zeroing kitty's own
      # background_blur, where the compositor does the blurring (hyprglass loads
      # under the same flag, modules/dendrites/compositor/hyprland/hyprglass.nix).
      # It does not gate translucency. Whether a terminal is translucent is the
      # song's call, and it reaches kitty through the stage files `followsStage`
      # includes.
      aoideQuickshell = config.aoide.quickshell.enable;

      # The terminals follow a stage. The lyra lane is the only writer of the two
      # files included below (its seed the declared fragment, `rice stage` the
      # staged colours), so a host without lyra opens no control socket and
      # includes nothing. Read here, not in the home-manager
      # lane, which shadows `config` with its own.
      followsStage = config.aoide.lyra.enable;
      aoideRoot = config.aoide.root;
    in
    {
      config = {
        home-manager.users.${username} =
          {
            pkgs,
            config,
            lib,
            ...
          }:
          let
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
          in
          {
            # Configure Kitty
            programs.kitty = lib.mkMerge [
              (lib.mkForce {
                enable = true;
                package = pkgs.kitty;
                #set by stylix
                #font.name = "Lekton Nerd Font Mono";
                #font.size = 12;
                settings =
                  lib.optionalAttrs conductShell {
                    # Conduct-by-default: every kitty window's login shell is the wrapper
                    # above. Opt a single window out with AOIDE_NO_CONDUCT=1 in its env.
                    shell = "${aoide-shell}/bin/aoide-shell";
                  }
                  // {
                    scrollback_lines = 2000;
                    wheel_scroll_min_lines = 1;
                    confirm_os_window_close = 0;
                    window_padding_width = 5;
                    window_border_width = 1.5;
                    remember_window_size = "no";
                    background_opacity = 1;
                    background_blur = 1;
                    enable_audio_bell = false;
                    tab_bar_style = "powerline";
                    tab_powerline_style = "slanted";
                  }
                  // lib.optionalAttrs aoideQuickshell {
                    # Aero-glass terminal, ported from Aoide's kitty dendrite. The blur is
                    # the compositor's: kitty's own background_blur is a macOS/KDE path,
                    # inert under Hyprland, so it is off on purpose and not left at the
                    # 1 above, which would imply a second blurrer that never runs.
                    #
                    # The opacity is the song's. A host with lyra includes the declared
                    # and the staged terminal files below, the staged one last and always
                    # carrying a `background_opacity`, and the control socket with
                    # `dynamic_background_opacity` lets `rice stage` move the open windows
                    # to it. Where hyprland.conf comes from dxflake's own Hyprland lane,
                    # terminals carry no opacity rule (compositor/hyprland/hyprglass.nix),
                    # so the song's value is the whole say, focused or not. Where it comes
                    # from Aoide's compositor lane, that lane's
                    # `windowrule = opacity 1.0 0.80, match:class kitty` still multiplies
                    # the song's value by 0.80 when the window is unfocused, glyphs
                    # included. Without lyra the opaque base above stands.
                    background_blur = 0;
                  }
                  // lib.optionalAttrs followsStage {
                    # One control socket per instance: `rice stage` finds `kitty-<pid>`
                    # in the runtime dir and recolours the windows already open.
                    # socket-only keeps remote control off every pty.
                    allow_remote_control = "socket-only";
                    listen_on = "unix:\${XDG_RUNTIME_DIR}/kitty-{kitty_pid}";
                    dynamic_background_opacity = true;
                  };
                keybindings = {
                  "alt+j" = "next_window";
                  "alt+k" = "previous_window";
                  "alt+h" = "previous_tab";
                  "alt+l" = "next_tab";
                  "alt+enter" = "new_window_with_cwd";
                  "alt+shift+t" = "new_tab_with_cwd";
                  "alt+q" = "close_window";
                  "ctrl+shift+U" = "none"; # for vim's page up
                };
              })
              # Outside the `mkForce`, which would drop Stylix's include. kitty takes the
              # LAST value of a repeated key, so the order is the contract: the declared
              # opacity fragment, then the staged colours, so a live stage wins. A staged
              # file carries every colour slot, so a host orders its own kitty overrides
              # after this block, never before it. kitty skips a missing include with one
              # log line, so a host that has never staged keeps its baked colours.
              (lib.mkIf followsStage {
                extraConfig = lib.mkAfter ''
                  include ${aoideRoot}/song/declared/terminal-opacity.conf
                  include ${aoideRoot}/song/stage/terminal-colors.conf
                '';
              })
            ];
          };
      };
    };
}
