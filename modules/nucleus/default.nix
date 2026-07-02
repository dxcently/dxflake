{...}: {
  imports = [
    ./system.nix
    ./networking.nix
    ./user.nix
    ./security.nix
    ./boot.nix
    ./packages.nix
    ./openssh.nix
    ./tailscale.nix
    ./postgresql.nix
    ./avahi.nix

    ../dendrites/bash.nix
    ../dendrites/mcfly.nix
    ../dendrites/starship.nix
    ../dendrites/git.nix
    ../dendrites/neovim.nix
    ../dendrites/yazi.nix
    ../dendrites/btop.nix
    ../dendrites/nh.nix
  ];
}
