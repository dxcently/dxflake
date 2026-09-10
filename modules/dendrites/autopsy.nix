{
  pkgs,
  config,
  lib,
  ...
}: {
  options.dx.autopsy.enable = lib.mkEnableOption "Autopsy digital forensics suite";
  config = lib.mkIf config.dx.autopsy.enable {
    nixpkgs.overlays = [
      (final: prev: {
        # upstream's wrapper never puts sleuthkit's libtsk.so.23 on LD_LIBRARY_PATH,
        # so the JNI bridge autopsy extracts to /tmp at launch can't dlopen it and
        # dies behind an easy-to-miss "Fatal Error!" dialog. etc/autopsy.conf also
        # ships with CRLF endings, spewing bash "$'\r': command not found" warnings
        # and corrupting --userdir/--cachedir with a trailing \r.
        autopsy = prev.autopsy.overrideAttrs (old: {
          postInstall = ''
            ${old.postInstall or ""}
            sed -i 's/\r$//' $out/etc/autopsy.conf
            wrapProgram $out/bin/autopsy --prefix LD_LIBRARY_PATH : "${prev.sleuthkit}/lib"
          '';
        });
      })
    ];
    environment.systemPackages = [pkgs.autopsy];
  };
}
