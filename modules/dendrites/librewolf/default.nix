# LibreWolf, and the default web browser for every user who takes the home half.
#
# No extension is declared here on purpose, neither as a policy nor as an
# installed add-on: they come from the Firefox Account sync, so adding or
# removing one is a browser action that needs no rebuild and no host edit.
# Declaring `policies.ExtensionSettings` would pin each one to a policy's idea
# of its version instead of letting the account keep it current.
{
  habit.home =
    { lib, pkgs, ... }:
    {
      programs.librewolf = {
        enable = true;
        profiles.default = {
          isDefault = true;
          userChrome = builtins.readFile ./userChrome.css;
          # DoH first, system resolver on failure: networks that throttle port
          # 53 stall every lookup otherwise. The tailnet stays on MagicDNS.
          # In user.js, so it outranks a trr.mode left in prefs.js.
          settings = {
            "network.trr.mode" = 2;
            "network.trr.excluded-domains" = "ts.net";
          };
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
