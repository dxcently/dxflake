{
  inputs,
  nixpkgs,
  self,
  username,
  host,
  ...
}: {
  imports = [
    ./aagl.nix
    ./jellyfin.nix
    ./solaar.nix
  ];
}
