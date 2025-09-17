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
    ./otd.nix
    ./stylix.nix
    inputs.stylix.nixosModules.stylix
  ];
}
