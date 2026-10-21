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
          # Home Manager owns profiles.ini as a read-only symlink into the
          # store, so anything that would rewrite it (the profile manager,
          # `--createprofile`) fails with "Error creating profile." This is
          # the pairing home-manager documents for exactly that: the same
          # id its own 'Profile Groups/57e99883.sqlite' and
          # 'toolkit.profiles.storeID' already carry, so the old profile
          # entry and the new group store agree and nothing needs rewriting.
          storeId = "57e99883";
          userChrome = builtins.readFile ./userChrome.css;
          # DoH first, system resolver on failure: networks that throttle port
          # 53 stall every lookup otherwise. The tailnet stays on MagicDNS.
          # In user.js, so it outranks a trr.mode left in prefs.js.
          settings = {
            "network.trr.mode" = 2;
            "network.trr.excluded-domains" = "ts.net";
            # LibreWolf's own default sets this false (its mozilla.cfg, under
            # [SECTION] WEBGL). A user.js pref outranks a default, which is the
            # only reason it can be turned on from here at all.
            "dom.webgpu.enabled" = true;
          };
        };
        # Tabs do not come back after a close, and nothing else is cleared with
        # them. Two prefs: startup.page keeps a launch from restoring the
        # session, and closeWindowWithLastTab goes back to Firefox's own default
        # so the last tab closes its window and the process exits. With it false
        # the window outlived its last tab, LibreWolf ran for days, and every
        # "open" just re-showed a window that had never been closed — no clean
        # shutdown, so nothing that happens on shutdown ever happened either.
        # Cookies, history, logins and site settings are left alone; the session
        # is still written to disk, so crash recovery still works.
        settings = {
          "browser.startup.page" = 1;
          "privacy.sanitize.sanitizeOnShutdown" = false;
          "privacy.resistFingerprinting" = false;
          "privacy.fingerprintingProtection" = true;
          "browser.search.suggest.enabled" = true;
          "browser.urlbar.suggest.searches" = true;
          "browser.tabs.closeWindowWithLastTab" = true;
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
