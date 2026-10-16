# A mneme instance as a NixOS container on sakaki, composed by habit like a host.
{
  habit.dendrites.mneme.enable = true;
  boot.isContainer = true;
  system.stateVersion = "26.05";
}
