{ ... }: {
  # sakaki is headless: expose Syncthing over the tailnet, not localhost/LAN.
  # Devices + the Magi folder come from modules/dendrites/syncthing.nix; here we
  # only make Nix authoritative (override* = true) and open the GUI on the tailnet.
  services.syncthing = {
    guiAddress = "0.0.0.0:8384"; # binds on tailscale0; the firewall below gates reach
    overrideDevices = true;
    overrideFolders = true;
    settings.gui.insecureSkipHostcheck = true; # reach the GUI via tailnet IP/MagicDNS name
  };

  # Syncthing GUI + sync + discovery, reachable only over the tailnet.
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [
      8384
      22000
    ];
    allowedUDPPorts = [
      22000
      21027
    ];
  };
}
