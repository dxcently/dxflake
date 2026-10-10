{
  pkgs,
  ...
}:
{
  config = {
    # gio is glib's command line onto gvfs: what lists, restores and empties
    # trash:/// for anything that is not a GTK program, the shell's Trash among them.
    environment.systemPackages = [ pkgs.glib.bin ];

    programs = {
      thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
          thunar-volman
          thunar-media-tags-plugin
        ];
      };
    };

    services = {
      tumbler.enable = true;
      # file-manager substrate — automount, mount-without-root, trash/mtp/network
      gvfs.enable = true;
      udisks2.enable = true;
      devmon.enable = true;
    };
  };
}
