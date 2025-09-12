{
  inputs,
  nixpkgs,
  self,
  username,
  host,
  ...
}: {
  imports = [
    ./options.nix
    ./fonts.nix
    ./user.nix
    ./stylix.nix
  ];
}
