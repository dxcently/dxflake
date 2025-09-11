{
  pkgs,
  config,
  ...
}: {
  stylix = {
    targets = {
      gtk.enable = false;
      kitty.enable = false;
      neovim.enable = false;
      nvf.enable = false;
      qt = {
        enable = true;
        platform = "qtct";
      };
    };
  };
}
