# The agent's home in a snowglobe VM. The account is snowglobe's (its guest defines
# users.users.agent), so this file is the home half only: `habit.home`, which a VM
# gets wherever its `habit.users.agent.home.enable` is on.
{
  habit.home =
    { lib, ... }:
    {
      home.username = "agent";
      home.homeDirectory = "/home/agent";
      home.stateVersion = "26.05";
      programs.home-manager.enable = true;
      # A VM's nix sees the host's whole store but knows only its own closure, so the
      # store GC that `nh clean` runs would delete every other path through the VM's
      # RAM overlay. A restart empties the overlay instead.
      programs.nh.clean.enable = lib.mkForce false;
    };
}
