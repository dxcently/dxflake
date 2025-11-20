{
  pkgs,
  config,
  ...
}: {
  programs.obsidian = {
    enable = true;
    /*
      vaults.obsidian-vaults = {
      enable = true;
      target = "Documents/Magi";
    };
    defaultSettings = {
      app = {
        vimMode = true;
      };
    };
    */
  };
}
