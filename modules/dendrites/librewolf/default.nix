# LibreWolf, and the default web browser for every user who takes the home half.
#
# The browser owns its profile. Nothing under ~/.librewolf is a home-manager
# file, so the profile manager, `--createprofile`, the settings panes and
# `about:config` all write where they like; a rebuild never fights a change
# made in the UI, and ~/.librewolf can be the same profile on two machines.
# That is also why `profiles.<name>` is gone: it wrote profiles.ini, user.js
# and chrome/userChrome.css as read-only store symlinks, which made the file
# unwritable (the profile manager answered "Error creating profile.") and
# would have carried a /nix/store path into the other machine's profile.
#
# What remains here is defaults, never settings: `settings` below becomes
# ~/.librewolf/librewolf.overrides.cfg, which LibreWolf reads as `defaultPref`,
# so any value chosen in the UI outranks it. The two seeds cover a machine with
# no profile yet and are skipped the moment the browser has an answer of its
# own.
#
# No extension is declared: they come from the Firefox Account sync.
{
  habit.home =
    { lib, pkgs, ... }:
    {
      programs.librewolf = {
        enable = true;
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
          # LibreWolf's own default is false (mozilla.cfg), and a profile with
          # no account syncs nothing — which would quietly cost the extensions
          # and the bookmarks that are now expected to arrive that way. A
          # default, so signing out in the UI still sticks.
          "identity.fxaccounts.enabled" = true;
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
          # DoH first, system resolver on failure: networks that throttle port
          # 53 stall every lookup otherwise. The tailnet stays on MagicDNS.
          "network.trr.mode" = 2;
          "network.trr.excluded-domains" = "ts.net";
          # LibreWolf's own default is false (its mozilla.cfg, under
          # [SECTION] WEBGL), so WebGPU is off unless something says otherwise.
          "dom.webgpu.enabled" = true;
          # DRM: Widevine is off and LibreWolf stops the plugin manager from
          # fetching it, so all three are needed for playback.
          "media.eme.enabled" = true;
          "media.gmp-widevinecdm.enabled" = true;
          "media.gmp-manager.updateEnabled" = true;
        };
      };

      # Two seeds, each only when the browser has nothing there yet: profiles.ini
      # so the profile is called `default` instead of a fresh random name, and
      # the stylesheet. Both are copies, not links, so the browser and the
      # account own them from then on. Ordered after linkGeneration, because that
      # is the step that drops the symlinks this generation no longer manages —
      # seeding before it would see the old link, skip, and lose the file.
      # The seed carries no StoreID: that is the browser's to write, and a
      # hardcoded one would disagree with the Profile Groups database on a
      # machine that has its own.
      home.activation.librewolfSeedProfile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        profileDir="$HOME/.librewolf/default"
        run mkdir -p "$profileDir/chrome"
        if [ ! -e "$HOME/.librewolf/profiles.ini" ]; then
          run ${pkgs.coreutils}/bin/install -m644 ${./profiles.ini} "$HOME/.librewolf/profiles.ini"
        fi
        if [ ! -e "$profileDir/chrome/userChrome.css" ]; then
          run ${pkgs.coreutils}/bin/install -m644 ${./userChrome.css} "$profileDir/chrome/userChrome.css"
        fi
      '';

      # mimeapps.list stays app-writable (the Claude app registers claude:// in
      # it), so the default is re-asserted on each switch instead of owned.
      # Every web document type, not just http/https/html: xhtml and the
      # x-extension-* aliases were still pointing at zen.desktop, so a saved
      # .xhtml or .shtml file opened in another browser from the file manager.
      home.activation.librewolfDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.xdg-utils}/bin/xdg-mime default librewolf.desktop \
          x-scheme-handler/http \
          x-scheme-handler/https \
          x-scheme-handler/ftp \
          x-scheme-handler/chrome \
          text/html \
          application/xhtml+xml \
          application/x-extension-htm \
          application/x-extension-html \
          application/x-extension-shtml \
          application/x-extension-xhtml \
          application/x-extension-xht
      '';
    };
}
