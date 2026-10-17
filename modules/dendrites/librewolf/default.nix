# LibreWolf, and the default web browser for every user who takes the home half.
let
  # Installed from AMO by the browser itself and kept current there, the way
  # LibreWolf ships uBlock Origin; only adding or removing one needs a rebuild.
  extensions = [
    "78272b6fa58f4a1abaac99321d503a20@proton.me" # Proton Pass
    "{8927f234-4dd9-48b1-bf76-44a9e153eee0}" # BetterCampus (Better Canvas)
    "{60f82f00-9ad5-4de5-b31c-b16a47c51558}" # Cookie Quick Manager
    "savewebpas@jeffersonscher.com" # Save webP as PNG or JPEG
    "clipper@obsidian.md" # Obsidian Web Clipper
    "{3c078156-979c-498b-8990-85f7987dd929}" # Sidebery
  ];
in
{
  habit.home =
    { lib, pkgs, ... }:
    {
      programs.librewolf = {
        enable = true;
        policies.ExtensionSettings = lib.genAttrs extensions (id: {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";
          installation_mode = "normal_installed";
        });
        profiles.default = {
          isDefault = true;
          userChrome = builtins.readFile ./userChrome.css;
        };
        # Tabs close on exit (startup.page stays at Firefox's default); pinned
        # tabs are still restored, which is Firefox's deferred-session behaviour.
        settings = {
          "privacy.sanitize.sanitizeOnShutdown" = false;
          "privacy.resistFingerprinting" = false;
          "privacy.fingerprintingProtection" = true;
          "browser.search.suggest.enabled" = true;
          "browser.urlbar.suggest.searches" = true;
          "browser.tabs.closeWindowWithLastTab" = false;
          "general.autoScroll" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          # DRM: Widevine is off and LibreWolf stops the plugin manager from
          # fetching it, so all three are needed for playback.
          "media.eme.enabled" = true;
          "media.gmp-widevinecdm.enabled" = true;
          "media.gmp-manager.updateEnabled" = true;
        };
      };

      # mimeapps.list stays app-writable (the Claude app registers claude:// in
      # it), so the default is re-asserted on each switch instead of owned.
      home.activation.librewolfDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.xdg-utils}/bin/xdg-mime default librewolf.desktop \
          x-scheme-handler/http x-scheme-handler/https text/html
      '';
    };
}
