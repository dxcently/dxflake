{
  inputs,
  nixpkgs,
  self,
  username,
  host,
  ...
}: {
  imports = [
    ./pkgs.nix
    ./options.nix
    ./fonts.nix
    ./user.nix
    ./stylix.nix
    #./gaming.nix
  ];
}
