{
  pkgs,
  config,
  ...
}: {
  programs.obsidian = {
    enable = true;
    vaults.obsidian-vaults = {
      enable = true;
      target = "Documents/Magi";
    };
    defaultSettings = {
      app = {
        vimMode = true;
      };
    };
    corePlugins = [
      "file-explorer"
      "command-palette"
      "graph-view"
      "daily-notes"
      "canvas"
      "bases"
      "backlinks"
      "bookmarks"
      "file-recovery"
      "files"
      "note-composer"
      "outgoing-links"
      "outline"
      "page-preview"
      "quick-switcher"
      "search"
      "slash-commands"
      "slides"
      "tags-view"
      "word-count"
    ];
  };
}
