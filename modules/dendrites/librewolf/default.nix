# LibreWolf, and the default web browser for every user who takes the home half.
#
# The browser owns its profile. Apart from the stylesheet below, nothing under
# ~/.librewolf is a home-manager file, so the profile manager, `--createprofile`,
# the settings panes and `about:config` all write where they like; a rebuild
# never fights a change made in the UI, and ~/.librewolf can be the same profile
# on two machines. That is also why `profiles.<name>` is gone: it wrote
# profiles.ini, user.js and chrome/userChrome.css as read-only store symlinks,
# which made the file unwritable (the profile manager answered "Error creating
# profile.") and would have carried a /nix/store path into the other machine's
# profile. chrome/ is the one exception and a narrow one: it is a look, the
# browser only ever reads it, and a look belongs in the repo.
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
    let
      # The classic Firefox chrome: github.com/DiegoSainzPardoLaso
      # /Firefox-Classic-Theme-155-158, main at cf5e772. Its `155-156` set is the
      # one this browser is (LibreWolf 156.0); the `157` set is the same theme
      # moved to the next chrome, for whenever the pin does.
      #
      # Its User.js asks for two prefs, and both are in `settings` below:
      # legacyUserProfileCustomizations.stylesheets (already true, which is what
      # makes the browser read chrome/ at all) and hoverPreview off, so a tab
      # shows the classic tooltip instead of a thumbnail card.
      chromeTheme = pkgs.fetchFromGitHub {
        owner = "DiegoSainzPardoLaso";
        repo = "Firefox-Classic-Theme-155-158";
        rev = "cf5e772b9cc68e0c66b78d25e871355cc2ccaaf2";
        hash = "sha256-IaCFRvkHrJbGHwFWsl2gtvmECyapOddbnHnKeGpBiXY=";
      };
      chromeFiles = builtins.readDir "${chromeTheme}/155-156";
    in
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
          # The librewolf bridge (modules/dendrites/eidolon.nix) is a local XPI
          # nobody has signed, and LibreWolf refuses to policy-install an
          # unsigned add-on: about:policies#errors answers
          # `Download failed - ERROR_SIGNSTATE_REQUIRED` for it. This pref is
          # what lets it in, and it is browser-wide — the honest cost is that
          # any unsigned XPI can now be installed from a file, not just this
          # one. Remove this line and the bridge goes back to being a temporary
          # add-on loaded by hand each session.
          "xpinstall.signatures.required" = false;
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
          # The classic chrome's own User.js asks for this: a tab shows the old
          # tooltip instead of the thumbnail preview card.
          "browser.tabs.hoverPreview.enabled" = false;
          # DRM: Widevine is off and LibreWolf stops the plugin manager from
          # fetching it, so all three are needed for playback.
          "media.eme.enabled" = true;
          "media.gmp-widevinecdm.enabled" = true;
          "media.gmp-manager.updateEnabled" = true;
        };
      };

      # The stylesheet, and the only files in the profile Nix states: everything
      # the theme ships except its User.js (whose two prefs are in `settings`
      # above) is linked in by name, so `@import` lines inside userChrome.css
      # resolve against the same directory and an update to the theme lands on
      # the next switch. `userContent.css` rides along — the about: and error
      # pages are part of the look. chrome/ is a look, not browser state: the
      # browser reads it and never writes it.
      home.file = lib.mapAttrs' (
        name: _:
        lib.nameValuePair ".librewolf/default/chrome/${name}" {
          source = "${chromeTheme}/155-156/${name}";
        }
      ) (lib.filterAttrs (name: _: name != "User.js") chromeFiles);

      # One seed, only when the browser has nothing there yet: profiles.ini, so
      # the profile is called `default` instead of a fresh random name. A copy,
      # not a link, so the browser owns it — the profile manager and
      # `--createprofile` have to be able to write it. Ordered after
      # linkGeneration, because that is the step that drops the symlinks this
      # generation no longer manages: seeding before it would see the old link,
      # skip, and lose the file. It carries no StoreID: that is the browser's to
      # write, and a hardcoded one would disagree with the Profile Groups
      # database on a machine that has its own.
      home.activation.librewolfSeedProfile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [ ! -e "$HOME/.librewolf/profiles.ini" ]; then
          run ${pkgs.coreutils}/bin/install -m644 ${./profiles.ini} "$HOME/.librewolf/profiles.ini"
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
