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

      # chrome/ is the one thing in the profile Nix states, because a look is
      # configuration and not browser state: the browser reads chrome/ and never
      # writes it. Three entries, and the shape is the point.
      #
      # The theme goes in whole as `theme/`, because its files speak to each
      # other in relative paths: userChrome.css imports `custom_*.css` beside
      # it, and those reach `images/` the same way. Firefox, however, reads
      # exactly one `userChrome.css` and one `userContent.css`, so those two are
      # the seam: they import the theme, and then say what this desktop wants on
      # top of it. A theme update replaces `theme/` and cannot overwrite a line
      # written here.
      home.file = {
        ".librewolf/default/chrome/theme".source = "${chromeTheme}/155-156";

        ".librewolf/default/chrome/userChrome.css".text = ''
          @import url("theme/userChrome.css");

          /* The compositor is the window manager. Hyprland closes, moves and
             resizes from its own binds, so the client-side buttons are three
             widgets of chrome with nothing behind them. This hides them; it does
             not take the drag region, which the strip keeps. */
          .titlebar-buttonbox-container,
          #titlebar .titlebar-button,
          .titlebar-button {
            display: none !important;
          }

          /* The app button is absolutely positioned over the start of the tab
             strip, and the theme only pads the strip to clear it on the paths
             where the Menu bar is enabled — with the menubar hidden the first
             tab slides under the word "Firefox". Pad the strip unconditionally,
             with the theme's own width, so the two cannot meet. The theme's own
             padded rules are more specific, so where they apply they win and
             this changes nothing. */
          #TabsToolbar {
            padding-inline-start: var(--appbutton_in_titlebar, 95px) !important;
          }

          /* The theme pulls the "List all tabs" button down into the toolbar
             with a 20px top margin (custom_bookmarks.css, which also swaps its
             icon for a bare dropdown arrow), so it reads as a stray button
             floating beside the tabs. What it lists is the tab strip itself, on
             a strip that no longer needs a dropdown for it. Zeroing the margin
             instead keeps the button and just puts it back in line. */
          #TabsToolbar #alltabs-button {
            display: none !important;
          }

          /* Would rather see no app button at all? Uncomment these two lines and
             the padding above can go with them.
          #PanelUI-button { display: none !important; }
          */
        '';

        # Imports from inside theme/ for the same reason: the about: and error
        # pages reference `images/`, which resolves beside the file that names it.
        ".librewolf/default/chrome/userContent.css".text = ''
          @import url("theme/userContent.css");
        '';
      };

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
