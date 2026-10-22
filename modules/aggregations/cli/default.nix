# cli — the command-line kit, with no desktop. A VM selects it, and a host can too.
# Off unless selected (`habit.aggregation.cli.enable = true`).
#
# Members are ordinary dendrites and packages, deselected with
# `habit.dendrites.<name>.enable = false`, the way network's are.
{
  description = "The command-line kit: git, starship, direnv, fzf, ripgrep and btop.";

  system.members = [
    "git"
    "starship"
    "direnv"
    "fzf"
    "ripgrep"
    "btop"
  ];
}
