# network — how the machine is reached: sshd, mDNS and the tailnet.
#
# Members are ordinary dendrites, deselected with
# `habit.dendrites.<name>.enable = false`. Deselected, sshd, mDNS or the tailnet
# is simply off. `openssh` is the only sshd: a host that routes ssh through
# `dx.cloudflared` needs it, since cloudflared hands tunnel connections to sshd
# on loopback.
{
  description = "How the machine is reached: sshd, mDNS, and the tailnet.";

  system.members = [
    "avahi"
    "openssh"
    "tailscale"
  ];
}
