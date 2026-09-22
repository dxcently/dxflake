# No `hosts`: every host that selected the target gets it.
{
  dendrites = [ "systemonly" ];
  overlay = _final: _prev: { fixture-allhosts = "patched"; };
  nixos = _: { fixture.marks = [ "allhosts" ]; };
}
