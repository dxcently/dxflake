{
  pkgs,
  config,
  ...
}: {
  services = {
    openssh = {
      enable = true;
      settings = {
        # Forbid root login through SSH.
        PermitRootLogin = "no";
        # Use keys only. Remove if you want to SSH using password (not recommended)
        PasswordAuthentication = true;
      };
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    tailscale.enable = true;
    devmon.enable = true;
    blueman.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
    flatpak.enable = true;
    printing.enable = true;
  };
}
