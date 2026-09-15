# dxflake's songbook — the rices, one directory each.
#
# A provider registry, the same shape as modules/dendrites/compositor/: it names
# paths and imports none of them, so the rice a host wears is the only one ever
# read. The name mirrors Aoide's song/songbook/ deliberately — a rice here is
# authored against the SAME livery schema, so `lyra livery lint` and
# `lyra livery emit` work on it unchanged — but this songbook is dxflake's and
# nothing in it is declared into Aoide.
#
# Adding a rice is a directory beside transience/ and one line below. The host
# that wants it says so on the shell aggregation:
#
#   users.<u>.aggregation.shell.rice.provider = "<name>";
{
  providers = {
    transience = ./transience/rice.nix;
  };
}
