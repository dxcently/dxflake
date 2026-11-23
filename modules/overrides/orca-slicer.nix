# OrcaSlicer renders plate thumbnails outside render(), where another library's
# GL context (WebKitGTK's) can be current; the draw then has no element buffer
# in scope and Mesa reads the index pointer as a client array and faults.
# nixpkgs master carries the upstream fix as pr-15873-fix-slice-crash.patch and
# this pin does not. Remove once the pin has it.
{
  dendrites = [ "orca-slicer" ];

  overlay = final: prev: {
    orca-slicer = prev.orca-slicer.overrideAttrs (old: {
      patches = old.patches ++ [
        (final.fetchurl {
          name = "pr-15873-fix-slice-crash.patch";
          url = "https://github.com/OrcaSlicer/OrcaSlicer/commit/42009cf385381216d86b724c2c8532a497463b61.patch";
          hash = "sha256-208aL4gDyH2/SpIV7QmqTrNaMDU10DkYtXmWZt7MpN8=";
        })
      ];
    });
  };
}
