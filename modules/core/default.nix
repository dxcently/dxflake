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
    #./gaming.nix
  ];
}
