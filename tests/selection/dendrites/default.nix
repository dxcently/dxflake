# Fixture group declarations — the same layout modules/dendrites/default.nix
# uses. Only group directories are imported here; the catalogue-named
# implementations beside them (landmine throws on import) are reached in pass
# two or not at all, which is what makes that throw a test rather than a claim.
{
  imports = [
    ./desk
    ./kiosk
    ./workstation
  ];
}
