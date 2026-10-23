{ pkgs, ... }: {
  config = {
    nixpkgs.overlays = [
      (final: prev: {
        # upstream's wrapper never puts sleuthkit's libtsk.so.23 on LD_LIBRARY_PATH,
        # so the JNI bridge autopsy extracts to /tmp at launch can't dlopen it and
        # dies behind an easy-to-miss "Fatal Error!" dialog. etc/autopsy.conf also
        # ships with CRLF endings, spewing bash "$'\r': command not found" warnings
        # and corrupting --userdir/--cachedir with a trailing \r.
        #
        # The release ships no .desktop file and its only artwork is a Windows
        # .ico, which no launcher resolves. The home half below names `autopsy`
        # in the icon theme, so the .ico's 256x256 frame is cut out as a PNG and
        # installed where hicolor lookup finds it.
        autopsy = prev.autopsy.overrideAttrs (old: {
          postInstall = ''
            ${old.postInstall or ""}
            sed -i 's/\r$//' $out/etc/autopsy.conf
            wrapProgram $out/bin/autopsy --prefix LD_LIBRARY_PATH : "${prev.sleuthkit}/lib"
            install -d $out/share/icons/hicolor/256x256/apps
            ${prev.imagemagick}/bin/convert "$out/icon.ico[0]" \
              -resize 256x256 $out/share/icons/hicolor/256x256/apps/autopsy.png
          '';
        });
      })
    ];
    environment.systemPackages = [
      pkgs.autopsy
      # autopsy has no CLI mode: the package is the JavaFX GUI and nothing else.
      # The command line half of the same suite — fls, icat, mmls, blkcat,
      # tsk_recover — is the `sleuthkit` package line the forensic-tools
      # aggregation names, not this dendrite's.
    ];

    habit.home =
      { ... }:
      {
        xdg.desktopEntries.autopsy = {
          name = "Autopsy";
          genericName = "Digital forensics";
          comment = "Graphical interface to The Sleuth Kit";
          exec = "autopsy";
          icon = "autopsy";
          categories = [
            "Utility"
            "Security"
          ];
          terminal = false;
        };
      };
  };
}
