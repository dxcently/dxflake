# Both bodies throw. Nothing selects `homeonly` in the cases that force this
# set, so an unmatched record's functions are proved uncalled rather than
# assumed so. The metadata above the functions stays cheap on purpose: it is
# read on every host.
{
  dendrites = [ "homeonly" ];
  overlay = _final: _prev: throw "tripwire overlay was evaluated";
  nixos = _: throw "tripwire nixos module was evaluated";
}
