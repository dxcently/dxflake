{
  username,
  ...
}: {
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
  ];

  home-manager.users.${username}.imports = [
    ../home/bash.nix
    ../home/git.nix
    ../home/neovim.nix
    ../home/yazi.nix
    ../home/btop.nix
    ../home/nh.nix
  ];
}
