# hyprglass — the gloss on top of the glass.
#
# A Hyprland decoration PLUGIN: refraction, fresnel and adaptive brightness
# layered OVER Hyprland's own gaussian blur. It lives here, under
# dendrites/hyprland/, because a compositor plugin is compiled against one
# compositor — see the ABI note below. A host that picks another compositor
# must never select this, and never evaluates `pkgs.hyprglass` if it doesn't.
#
# It only ever paints TRANSLUCENT content, so it is inert on an opaque desktop.
# That is why every part of it rides `aoideFace` rather than plain selection:
# the surfaces it is aimed at (aoide-dock, -launcher, -powermenu) exist only
# when Aoide's Quickshell facet draws them. Selected with the facet off, this
# dendrite is a no-op by construction — which is what lets the shell
# aggregation name it unconditionally.
#
# ABI: a Hyprland plugin is locked to the compositor commit it was compiled
# against, and hyprglass's own pin table (hyprpm.toml) vets v0.7.0 against
# hyprland 0.56.0 — while this flake is on 0.56.2. That gap was CHECKED, not
# assumed: the plugin builds clean against the 0.56.2 in our nixpkgs, and
# because the same nixpkgs provides both the plugin's build input and
# `programs.hyprland.package`, the running compositor and the .so can never
# drift apart in a rebuild.
#
# The package BUILD is not ours: pkgs/hyprglass lives in the Aoide input and
# reaches us through the packages-walker overlay flake.nix installs.
{
  homeManager =
    {
      pkgs,
      osConfig,
      lib,
      config,
      ...
    }:
    let
      aoideFace = osConfig.aoide.facets.quickshell.enable;
      stylixPolarity =
        if (config ? stylix && config.stylix ? polarity) then config.stylix.polarity else "dark";
      hyprglassTheme = if stylixPolarity == "light" then "light" else "dark";
    in
    {
      wayland.windowManager.hyprland = {
        plugins = lib.optionals aoideFace [ pkgs.hyprglass ];

        # hyprglass glosses; it does not blur. Hyprland's own `layerrule = blur
        # on` is what these surfaces sit on, and the plugin refracts over the
        # result — without this pair the plugin loads and shows nothing, which is
        # the usual "hyprglass isn't working" report. Ported verbatim from
        # Aoide's compositor facet, including its two deliberate exclusions:
        # aoide-bar takes `blur_popups` only (the strip's popouts frost, the
        # strip itself is the song's own ground), and aoide-calendar is pinned
        # blur OFF so its cut-out day grid shows the desktop crisply.
        #
        # The waybar rule is NOT here — it belongs to the desktop this flake
        # draws with the facet off, so hyprland-decoration owns it.
        settings.layerrule = lib.optionals aoideFace [
          "blur on, match:namespace aoide-dock"
          "blur on, match:namespace aoide-launcher"
          "blur on, match:namespace aoide-powermenu"
          "ignore_alpha 0.05, match:namespace aoide-dock"
          "ignore_alpha 0.05, match:namespace aoide-launcher"
          "ignore_alpha 0.05, match:namespace aoide-powermenu"
          "blur_popups on, match:namespace aoide-bar"
          "blur off, match:namespace aoide-calendar"
        ];

        # Written through the top-level `extraConfig` (a sibling of `settings`,
        # emitted at the END of hyprland.conf) rather than through `settings`:
        # `plugin:hyprglass { … }` is a plugin keyword block, and hyprlang wants
        # it verbatim.
        #
        # Preserve Aoide's gloss tuning, but align the active preset with the
        # active Stylix polarity. The plugin validates this at runtime, so it
        # must not be hardcoded across both dark and light livery selections.
        #
        # manage_window_blur is a GLOBAL toggle in v0.7.0 — there is no
        # per-class targeting (confirmed against the built plugin's key table).
        # It stays on because the shader only paints visible translucent
        # fragments: an unfocused kitty gains refraction as it fades, while a
        # focused (hovered) one is fully opaque and untouched, as is every
        # other opaque window.
        #
        # The namespace list is the three surfaces Aoide glasses. It is static
        # here on purpose: Aoide's facet appends song-declared widget surfaces
        # too, but only `kind = "surface"` widgets ever get a layer surface of
        # their own, and nocturne's sole widget (`vigil`) is `kind = "dock"` —
        # it mounts as an Item inside aoide-dock and is already covered by the
        # dock's own entry. A song declaring a real surface widget would want
        # its namespace added here by hand.
        extraConfig = lib.optionalString aoideFace ''
          plugin:hyprglass {
              manage_window_blur = 1
              default_theme = ${hyprglassTheme}
              ${hyprglassTheme} {
                  glass_opacity = 0.82
              }
              layers {
                  enabled = 1
                  namespaces = aoide-dock, aoide-launcher, aoide-powermenu
                  preset = glass
              }
          }

          # ── Aero-glass terminal (pairs with the kitty dendrite) ────────────
          # This rule is the ONLY source of terminal translucency: kitty runs
          # background_opacity 1 (see the kitty dendrite for why), so 1.0 here
          # really is 100% opaque rather than a ceiling over kitty's own baked
          # alpha. `follow_mouse = 1` above makes focused == hovered, so the
          # crisp state is the hovered one; an unfocused terminal fades to 0.80
          # and visibly recedes, still blurred because
          # `decoration.blur.ignore_opacity` blurs behind opacity-faded windows.
          # Terminals only, deliberately — this is not a global
          # inactive_opacity, because media and browser windows carry arbitrary
          # content that must never be faded.
          #
          # 0.80 is Aoide's documented legibility FLOOR-plus: it keeps unfocused
          # terminal text near 3.7:1, and their note marks 0.75 as the hard
          # floor with 0.70 breaking readability outright. Raise toward 0.85 if
          # it reads badly against nocturne's navy — never drop below 0.75.
          #
          # One-line `windowrule =` form, matching Aoide's own. The `settings`
          # block above uses hyprland 0.56's other spelling (`windowrule { … }`)
          # — both are current; this file now carries both because each was
          # copied from where it was proven.
          windowrule = opacity 1.0 0.80, match:class kitty
          # Global decoration rounding is already 0; this pins kitty to match so
          # nothing rounds only the terminal.
          windowrule = rounding 0, match:class kitty
        '';
      };
    };
}
