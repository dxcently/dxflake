# example-user.nix — one person, shared across machines.
#
# Copy to:  users/<name>.nix
# Then:     attach it from each host that wants it:
#             users.<name> = {
#               definition = ../../users/<name>.nix;
#               homeManager.enable = true;
#             };
# Replace:  <name>, the groups, the shell, and the home floor.
#           `hashedPassword` below is a PLACEHOLDER. Generate your own with
#           `mkpasswd -m yescrypt`, or drop the line and use sops-nix
#           (`hashedPasswordFile`) — never commit a real hash you care about.
#
# One definition, many hosts. There are no per-host copies of a person.
{
  # The account. Required: a user with no nixos lane cannot be created, and the
  # constructor says so by name rather than producing a host without them.
  nixos =
    { pkgs, ... }:
    {
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
    };

  # Optional: the home floor this person carries on every host that turns their
  # Home Manager lane on. Selected home capabilities are imported ALONGSIDE it,
  # and the host's own `users.<name>.homeManager.config` lands on top.
  homeManager = {
    home.stateVersion = "25.05";
    programs.git = {
      enable = true;
      userName = "Example User";
      userEmail = "example@example.invalid";
    };
  };
}
