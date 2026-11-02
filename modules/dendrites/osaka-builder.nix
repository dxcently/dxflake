# osaka-builder — hand builds to osaka, the fast box. The daemon signs in as
# osaka's `nixremote` with this host's own SSH host key, so no new secret exists;
# osaka lists each client's host key (hosts/osaka/default.nix). When osaka is
# unreachable Nix builds locally.
#
# osaka is reached on the LAN: it sits on a different tailnet from its clients.
# Off the LAN the connect gives up after five seconds and the build runs here.
#
# A client is trusted on osaka's store, so whatever it adds there reaches every
# host osaka builds for. sakaki faces the internet and builds for itself.
{
  nix = {
    distributedBuilds = true;
    settings.builders-use-substitutes = true;
    buildMachines = [
      {
        hostName = "192.168.1.201";
        sshUser = "nixremote";
        sshKey = "/etc/ssh/ssh_host_ed25519_key";
        protocol = "ssh-ng";
        system = "x86_64-linux";
        maxJobs = 8;
        speedFactor = 10;
        supportedFeatures = [
          "big-parallel"
          "kvm"
          "nixos-test"
          "benchmark"
        ];
      }
    ];
  };
  programs.ssh.knownHosts.osaka = {
    hostNames = [ "192.168.1.201" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqMuS6SKujGuBlEaJNOeyJPqN3uXUbiyi8BbHpVgkNS";
  };
  programs.ssh.extraConfig = ''
    Host 192.168.1.201
      ConnectTimeout 5
  '';
}
