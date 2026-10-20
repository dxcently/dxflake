# NetBird, the WireGuard mesh client; the tray UI rides along on graphical hosts.
{
  services.netbird = {
    enable = true;
    # The peer SSH server is off: no inbound shell over the mesh, and the
    # daemon treats an unset value as on, which gates `netbird up -m` behind root.
    clients.default.config.ServerSSHAllowed = false;
  };
}
