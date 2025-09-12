{
  pkgs,
  config,
  inputs,
  home-manager,
  ...
}: {
  imports = [
    ./default.nix #seperates hm for osaka
  ];
}
