# modules/dendrites/ffmpeg.nix — ffmpeg, a member of `core`.
#
# Not a line in packages.nix: a package line installs at order 1400, behind any
# dendrite's own packages, and jellyfin's ffmpeg (the jellyfin dendrite, default
# order) would then own bin/ffmpeg on sakaki. `lib.mkBefore` puts this one first
# in system.path, so its bin/ffmpeg and bin/ffprobe win the collision.
{ lib, pkgs, ... }:
{
  environment.systemPackages = lib.mkBefore [ pkgs.ffmpeg ];
}
