# base — what every host carries beyond the nucleus.
#
# An aggregation body is DATA: the members it selects in each scope, the
# provider choices it exposes, and any preference that rides along. It declares
# no options and carries no gate; `lib/composition.nix` wraps it in one. Members
# are named by CATALOGUE NAME, so base's members stay where they are in
# modules/dendrites/*.nix rather than being moved under this directory.
#
# `base` is a membership, not a brand or a shrug: these are the capabilities
# every host gets, which is why it is the one aggregation every host selects.
{
  description = "Shell, editor and prompt tooling every host carries.";

  # stylix rides base on every host, including hosts that leave
  # `dx.stylix.enable` false: Aoide probes `options ? stylix`, so the option
  # tree has to exist even where nothing paints with it.
  system.members = [ "stylix" ];

  home.members = [
    "bash"
    "btop"
    "direnv"
    "git"
    "mcfly"
    "neovim"
    "nh"
    "starship"
    "yazi"
  ];
}
