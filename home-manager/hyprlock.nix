{
  pkgs,
  config,
  inputs,
  ...
}: {
  programs.hyprlock = {
    enable = true;
  };
}
