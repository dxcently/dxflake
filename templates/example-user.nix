# example-user.nix — one person, shared across machines.
#
# Copy to:  users/<name>.nix
# Then:     attach it from each host that wants it:
#             habit.users.<name> = {
#               definition = ../../users/<name>.nix;
#               home.enable = true;
#             };
# Replace:  <name>, the groups, the shell, and the home floor.
#           `hashedPassword` below is a PLACEHOLDER. Generate your own with
#           `mkpasswd -m yescrypt`, or drop the line and use sops-nix
#           (`hashedPasswordFile`) — never commit a real hash you care about.
#
# One definition, many hosts. There are no per-host copies of a person.
#
# A user definition is a plain module wrapped like a dendrite: its own settings
# are the account, applied on every host that attaches the user, and its
# `habit.home` is the home floor that user alone receives.
{ pkgs, ... }:
{
  # The account.
  users.users.exampleuser = {
    isNormalUser = true;
    description = "Example User";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
    hashedPassword = "!"; # REPLACE — "!" means no password login
  };
  programs.zsh.enable = true;

  # Optional: the home floor this person carries on every host that turns their
  # Home Manager on. Selected home capabilities are imported ALONGSIDE it, and
  # the host's own `habit.users.<name>.home.config` lands on top.
  habit.home = {
    home.stateVersion = "25.05";
    programs.git = {
      enable = true;
      userName = "Example User";
      userEmail = "example@example.invalid";
    };
  };
}
