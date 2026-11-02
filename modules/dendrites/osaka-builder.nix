# osaka-builder — hand builds to osaka, the fast box. The daemon signs in as
# osaka's `nixremote` with this host's own SSH host key, so no new secret exists;
# osaka lists each client's host key (hosts/osaka/default.nix). When osaka is
# unreachable Nix builds locally.
#
# A client is trusted on osaka's store, so whatever it adds there reaches every
# host osaka builds for. sakaki faces the internet and builds for itself.
{
  nix = {
    distributedBuilds = true;
    settings.builders-use-substitutes = true;
    buildMachines = [
      {
        hostName = "100.102.235.52"; # osaka's tailscale address: reachable off the LAN too
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
    hostNames = [ "100.102.235.52" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqMuS6SKujGuBlEaJNOeyJPqN3uXUbiyi8BbHpVgkNS";
  };
}
