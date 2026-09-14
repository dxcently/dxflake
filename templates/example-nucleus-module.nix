# example-nucleus-module.nix — an ordinary platform module, with no gate.
#
# Copy to:  modules/nucleus/<topic>.nix
# Then:     add `./<topic>.nix` to modules/nucleus/default.nix's imports.
# Replace:  <topic> and the settings.
#
# The nucleus is the floor: imported unconditionally on every host, not in the
# catalogue, and it declares no toggle. Ungated is what makes it the nucleus —
# if a host might not want it, it is a dendrite, not nucleus.
#
# This is a plain NixOS module. It is evaluated in the platform pass like any
# other, so `config`, `pkgs` and `lib` mean exactly what they always mean, and
# nothing here can read or influence selection.
#
# The same shape, with a `dx.<name>` option block, is how a capability exposes a
# real knob a host varies — put that file in the catalogue instead, and keep the
# option surface to what genuinely differs between machines.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    curl
    git
  ];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
}
