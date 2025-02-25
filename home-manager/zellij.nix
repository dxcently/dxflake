{
  pkgs,
  config,
  ...
}: {
  programs.zellij = {
    enable = true;
    enableBashIntegratin = true;
  };
}
