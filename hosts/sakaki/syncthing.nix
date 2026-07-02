{ username, ... }: {
  # sakaki is headless: expose Syncthing over the tailnet, not localhost/LAN.
  services.syncthing = {
    guiAddress = "0.0.0.0:8384"; # binds on tailscale0; the firewall below gates reach
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      gui.insecureSkipHostcheck = true; # reach the GUI via tailnet IP/MagicDNS name

      # Device IDs are generated on first launch — collect them from each device's
      # GUI (Actions -> Show ID) after the first rebuild, then replace the placeholders.
      devices = {
        osaka.id = "PASTE-OSAKA-DEVICE-ID";
        chiyo.id = "PASTE-CHIYO-DEVICE-ID";
        phone.id = "PASTE-PHONE-DEVICE-ID";
      };

      folders."Documents" = {
        path = "/home/${username}/Documents";
        devices = [ "osaka" "chiyo" "phone" ];
      };
    };
  };

  # Syncthing GUI + sync + discovery, reachable only over the tailnet.
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 8384 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
  };
}
