# Two targets and a host filter. Selecting both targets must still apply it
# once, and alpha must not see it at all.
{
  dendrites = [
    "systemonly"
    "notifications"
  ];
  hosts = [ "beta" ];
  overlay = _final: _prev: { fixture-confined = "patched"; };
}
