{
  config,
  lib,
  ...
}: {
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;

    settings = {
      manager = {
        ratio = [
          0
          1
          1
        ];
        sort_by = "mtime";
        sort_sensitive = false;
        sort_reverse = true;
        linemode = "size";
        show_hidden = false;
      };
    };

    theme = {
      manager = {
        preview_hovered = {
          underline = false;
        };
        folder_offset = [
          1
          0
          1
          0
        ];
        preview_offset = [
          1
          1
          1
          1
        ];
      };

      status.separator_style = {
        fg = "red";
        bg = "red";
      };
    };
  };

  home.shellAliases = {
    sy = "sudo yazi";
  };
}
