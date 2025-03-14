{
  pkgs,
  options,
  inputs,
  ...
}: {
  programs.wlogout = {
    enable = true;
  };
}
