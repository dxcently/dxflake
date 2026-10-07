# hyprglass — the gloss on top of the glass.
#
# A Hyprland decoration PLUGIN: refraction, fresnel and adaptive brightness
# layered OVER Hyprland's own gaussian blur. It lives in the hyprland
# provider's folder under dendrites/compositor/, because a compositor plugin is
# compiled against one compositor — see the ABI note below. A host that picks
# another compositor must never select this, and never evaluates
# `pkgs.hyprglass` if it doesn't.
#
# It only ever paints TRANSLUCENT content, so it is inert on an opaque desktop.
# That is why every part of it rides `aoideQuickshell` rather than plain selection:
# the surfaces it is aimed at (aoide-dock, -launcher, -powermenu) exist only
# when Aoide's Quickshell draws them. Selected without that shell, this
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
      aoideQuickshell = osConfig.aoide.quickshell.enable;
      stylixPolarity =
        if (config ? stylix && config.stylix ? polarity) then config.stylix.polarity else "dark";
      hyprglassTheme = if stylixPolarity == "light" then "light" else "dark";
    in
    {
      wayland.windowManager.hyprland = {
        plugins = lib.optionals aoideQuickshell [ pkgs.hyprglass ];

        # hyprglass glosses; it does not blur. Hyprland's own `layerrule = blur
        # on` is what these surfaces sit on, and the plugin refracts over the
        # result — without this pair the plugin loads and shows nothing, which is
        # the usual "hyprglass isn't working" report. Ported verbatim from
        # Aoide's compositor lane, including its two deliberate exclusions:
        # aoide-bar takes `blur_popups` only (the strip's popouts frost, the
        # strip itself is the song's own ground), and aoide-calendar is pinned
        # blur OFF so its cut-out day grid shows the desktop crisply.
        #
        # The waybar rule is NOT here — it belongs to the desktop this flake
        # draws without Aoide's Quickshell, so hyprland-decoration owns it.
        settings.layerrule = lib.optionals aoideQuickshell [
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
        # fragments: a kitty whose song gives it a translucent background gains
        # refraction, while an opaque terminal is untouched, as is every other
        # opaque window.
        #
        # The namespace list is the three surfaces Aoide glasses. It is static
        # here on purpose: Aoide's compositor lane appends song-declared widget surfaces
        # too, but only `kind = "surface"` widgets ever get a layer surface of
        # their own, and nocturne's sole widget (`vigil`) is `kind = "dock"` —
        # it mounts as an Item inside aoide-dock and is already covered by the
        # dock's own entry. A song declaring a real surface widget would want
        # its namespace added here by hand.
        extraConfig = lib.optionalString aoideQuickshell ''
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

          # ── Terminal window rule (pairs with the kitty dendrite) ───────────
          # Terminals carry no opacity rule: the song's terminal opacity is the
          # whole say for kitty, focused or not. It reaches kitty as its own
          # `background_opacity` (declared fragment, then the stage), which
          # makes the default background translucent and leaves glyphs opaque;
          # a Hyprland `opacity` rule would multiply it and dim the glyphs too.
          # Behind a translucent terminal the compositor still blurs
          # (`decoration.blur.ignore_opacity`) and hyprglass refracts, so an
          # opaque song shows neither. No window is faded here either: nothing
          # sets `inactive_opacity`, and media and browser windows carry
          # arbitrary content that must never be faded.
          #
          # One-line `windowrule =` form, matching Aoide's own. The `settings`
          # block above uses hyprland 0.56's other spelling (`windowrule { … }`)
          # — both are current; this file now carries both because each was
          # copied from where it was proven.
          # Global decoration rounding is already 0; this pins kitty to match so
          # nothing rounds only the terminal.
          windowrule = rounding 0, match:class kitty
        '';
      };
    };
}
