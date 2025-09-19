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
    ./networking.nix
    ./system.nix
    ./security.nix
    ./portals.nix
    ./virtualisation.nix
    ./syncthing.nix
    inputs.stylix.nixosModules.stylix
  ];
}
