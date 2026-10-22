# modules/dendrites/wireshark.nix — packet analysis, with live capture for the
# `wireshark` group (a setcap dumpcap wrapper). The module's default package is
# wireshark-cli, which has no GUI.
{ pkgs, ... }:
{
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };
}
