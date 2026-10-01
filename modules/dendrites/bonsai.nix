{
  nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ (pkgs.callPackage ../../pkgs/bonsai { }) ];
    };
}
