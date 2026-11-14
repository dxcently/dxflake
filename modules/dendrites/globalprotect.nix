# GlobalProtect VPN client (gpclient). Cal Poly SDC, guest: sudo -E gpclient connect vpn.sdc.cpp.edu (organizer creds; students use mgmt.sdc.cpp.edu with SSO)
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.gpclient ];
}
