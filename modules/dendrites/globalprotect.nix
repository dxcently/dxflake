# GlobalProtect VPN client (gpclient). Cal Poly SDC: sudo -E gpclient connect --browser default mgmt.sdc.cpp.edu
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.gpclient ];
}
