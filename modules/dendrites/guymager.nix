# modules/dendrites/guymager.nix — guymager, the disk imaging front end.
#
# guymager's packaging upstream is Debian-shaped: everything it installs lands
# under share/guymager/ — the .desktop file, the icon, the polkit action, and
# guymager.cfg — because Debian's rules place them from there. nixpkgs copies
# that tree verbatim, so the files are present but where no daemon or launcher
# looks. Only bin/guymager (a makeWrapper'd Qt5 binary) is outside it.
#
# The overlay re-installs the three files that have a search path of their own,
# by copying rather than moving: the program reads guymager.cfg from
# share/guymager/, so that directory has to stay as upstream ships it.
#
#   share/applications/   where desktop environments enumerate launchers
#   share/icons/hicolor/  where the icon theme resolves the name in Icon=
#   share/polkit-1/actions/  where polkitd reads actions, out of XDG_DATA_DIRS
#
# The .desktop file's Exec is `pkexec guymager`, so the polkit action is not
# optional: without it the launcher's click cannot authenticate and nothing
# starts. Its Icon names the PNG file itself, `guymager_128.png`, which is not a
# theme name and resolves nowhere; the copy is named `guymager` and the
# installed line is rewritten to match.
{ pkgs, ... }: {
  config = {
    nixpkgs.overlays = [
      (final: prev: {
        guymager = prev.guymager.overrideAttrs (old: {
          postInstall = ''
            ${old.postInstall or ""}
            install -Dm644 $out/share/guymager/guymager.desktop \
              $out/share/applications/guymager.desktop
            sed -i 's|^Icon=guymager_128\.png$|Icon=guymager|' \
              $out/share/applications/guymager.desktop
            install -Dm644 $out/share/guymager/guymager_128.png \
              $out/share/icons/hicolor/128x128/apps/guymager.png
            install -Dm644 $out/share/guymager/org.freedesktop.guymager.policy \
              $out/share/polkit-1/actions/org.freedesktop.guymager.policy
          '';
        });
      })
    ];
    environment.systemPackages = [ pkgs.guymager ];
  };
}
