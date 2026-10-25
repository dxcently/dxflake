# Not in nixpkgs. See pkgs/limusic for the builder and bump instructions.
{ pkgs, ... }:
{
  config = {
    environment.systemPackages = [ (pkgs.callPackage ../../pkgs/limusic { }) ];
  };
}
