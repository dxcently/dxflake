# The agent's home in a snowglobe VM. The account is snowglobe's (its guest defines
# users.users.agent), so this file is the home half only: `habit.home`, which a VM
# gets wherever its `habit.users.agent.home.enable` is on.
{
  habit.home =
    { ... }:
    {
      home.username = "agent";
      home.homeDirectory = "/home/agent";
      home.stateVersion = "26.05";
      programs.home-manager.enable = true;
    };
}
