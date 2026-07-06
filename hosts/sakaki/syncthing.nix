{ username, ... }: {
  # sakaki is headless: expose Syncthing over the tailnet, not localhost/LAN.
  services.syncthing = {
    guiAddress = "0.0.0.0:8384"; # binds on tailscale0; the firewall below gates reach
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      gui.insecureSkipHostcheck = true; # reach the GUI via tailnet IP/MagicDNS name

      # Step 2: After the first rebuild, visit the GUI on each device
      # (Actions -> Show ID) and paste real device IDs here, then rebuild again.
      devices = {
        # osaka.id = "AAAAAAA-BBBBBBB-...";
        # chiyo.id = "AAAAAAA-BBBBBBB-...";
        # phone.id = "AAAAAAA-BBBBBBB-...";
      };

      folders."Documents" = {
        path = "/home/${username}/Documents";
        devices = [ ]; # add "osaka" "chiyo" "phone" once IDs are filled in above
      };
    };
  };

  # Syncthing GUI + sync + discovery, reachable only over the tailnet.
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 8384 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
  };
}
