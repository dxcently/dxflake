{ pkgs, configs, ... }:
{
  programs.fastfetch = {
    enable = true;
    package = pkgs.fastfetch;
    settings = {
      logo = {
        type = "auto";
        source = "/home/khoa/Downloads/80765d18c18a259c47a175f6578fba42.jpg";
        width = 44;
        height = 15;
      };
      display = {
        separator = "";
      };
      modules = [
        {
          type = "custom";
          format = "╭=─=─=─=─=─=─=─=─=─=─=─=─  ୨୧  ─=─=─=─=─=─=─=─=─=─=─=─=╮";
        }
        {
          type = "title";
          key = "  ⚘ user..................................";
          format = "{1}@{2}";
        }
        {
          type = "os";
          key = "  𖹭 os .. ";
        }
        { type = "break"; }
        {
          type = "custom";
          format = "  hardware -------------------------------------------";
        }
        {
          type = "gpu";
          key = "  𖤣 gpu ";
        }
        {
          type = "host";
          key = "  ┰ host ..................";
        }
        {
          type = "cpu";
          key = "  ☘︎ cpu .....";
        }
        {
          type = "memory";
          key = "  𖥧 ram ....................";
        }
        { type = "break"; }
        {
          type = "custom";
          format = "  software -------------------------------------------";
        }
        {
          type = "wm";
          key = "  ♱ window manager .................";
        }
        {
          type = "terminalfont";
          key = "  a font ............................";
        }
        {
          type = "editor";
          key = "  ⭑ editor .......................................";
        }
        {
          type = "terminal";
          key = "  > terminal .............................";
        }
        {
          type = "shell";
          key = "  ꩜ shell .................................";
        }
        {
          type = "theme";
          key = "  𐙚 color scheme ....................";
        }
        {
          type = "colors";
          symbol = "square";
          paddingLeft = 21;
        }
        {
          type = "custom";
          format = "╰=─=─=─=─=─=─=─=─=─=─=─=─  ୨୧  ─=─=─=─=─=─=─=─=─=─=─=─=╯";
        }
      ];
    };
  };
}
