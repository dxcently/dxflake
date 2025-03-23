{
  pkgs,
  configs,
  ...
}: {
  programs.fastfetch = {
    enable = true;
    package = pkgs.fastfetch;
    settings = {
      logo = {
        type = "auto";
        source = ./fastfetch.png;
        width = 39;
        height = 15;
      };
      display = {
        separator = "";
      };
      modules = [
        {
          type = "custom";
          format = "=─=─=─=─=─=─=─=─=─=─=─=─  𓏲𝄢  ─=─=─=─=─=─=─=─=─=─=─=─=";
        }
        {
          type = "title";
          key = "  𝅝 user: ";
          format = "{1}@{2}";
        }
        {
          type = "os";
          key = "  𝄞 os: ";
        }
        {type = "break";}
        {
          type = "custom";
          format = "  hardware -------------------------------------------";
        }
        {
          type = "gpu";
          key = "  𝅘𝅥𝅯 gpu: ";
        }
        {
          type = "host";
          key = "  ♬ host: ";
        }
        {
          type = "cpu";
          key = "  ♭ cpu: ";
        }
        {
          type = "memory";
          key = "  𝄌 ram: ";
        }
        {type = "break";}
        {
          type = "custom";
          format = "  software -------------------------------------------";
        }
        {
          type = "wm";
          key = "  𝄡 window manager:  ";
        }
        {
          type = "terminalfont";
          key = "  𝆑 font: ";
        }
        {
          type = "editor";
          key = "  ♯ editor: ";
        }
        {
          type = "terminal";
          key = "  𝅘𝅥 terminal: ";
        }
        {
          type = "shell";
          key = "  𝅗𝅥 shell: ";
        }
        {
          type = "theme";
          key = "  𝄇 color scheme: ";
        }
        {
          type = "colors";
          symbol = "square";
          paddingLeft = 21;
        }
        {
          type = "custom";
          format = "=─=─=─=─=─=─=─=─=─=─=─=─  𓏲𝄢  ─=─=─=─=─=─=─=─=─=─=─=─=";
        }
      ];
    };
  };
}
