{
  pkgs,
  config,
  ...
}: {
  stylix = {
    autoEnable = true;
    targets = {
      librewolf.enable = false;
      gtk.enable = true;
      kitty.enable = true;
      neovim.enable = false;
      nvf.enable = false;
      waybar.enable = false;
      qt = {
        enable = true;
        platform = "qtct";
      };
    };
  };
}
