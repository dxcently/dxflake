{...}: {
  services.openssh = {
    enable = true;
    settings = {
      # Forbid root login through SSH.
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
    # A login that arrives from loopback is key-only. cloudflared hands every
    # tunnel-borne `sshHostnames` connection to sshd from localhost
    # (modules/dendrites/cloudflared.nix), so this is what keeps a public
    # tunnel hostname from being a password prompt on the internet; a LAN
    # login keeps the password fallback above.
    extraConfig = ''
      Match Address 127.0.0.1,::1
        PasswordAuthentication no
        KbdInteractiveAuthentication no
    '';
  };
}
