{
  inputs,
  nixpkgs,
  self,
  username,
  host,
  ...
}: {
  imports = [
    ./default.nix
    ./gaming.nix
  ];
}
