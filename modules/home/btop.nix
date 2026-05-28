{
  pkgs,
  config,
  ...
}: {
  programs.btop = {
    enable = true;
    settings = {
      theme_background = false;
      rounded_corners = false;
    };
  };
}
