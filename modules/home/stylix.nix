{
  pkgs,
  config,
  ...
}: {
  stylix = {
    targets = {
      gtk.enable = false;
      kitty.enable = true;
      neovim.enable = true;
      nvf.enable = false;
      waybar.enable = false;
      qt = {
        enable = true;
        platform = "qtct";
      };
    };
  };
}
