# dev — a preset: a whole habit host, not picks. `snowglobe summon <vm> --preset dev`
# composes this file as the VM's host. snowglobe sets the hostname; there is no
# bootloader, hardware or desktop here.
#
# claude-code stays out on purpose: snowglobe's agents profile installs claude and
# seeds ~/.claude, and the dendrite would fight it.
{
  habit.aggregation.cli.enable = true;

  habit.dendrites = {
    neovim.enable = true;
    yazi.enable = true;
    bash.enable = true;
    fastfetch.enable = true;
  };

  habit.users.agent = {
    definition = ../users/agent.nix;
    home.enable = true;
  };
}
