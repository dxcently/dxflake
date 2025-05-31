{
  pkgs,
  config,
  inputs,
  ...
}: let
  palette = config.colorScheme.palette;
in {
  imports = [inputs.nvf.homeManagerModules.default];

  programs.neovim = {
    enable = true;
    vimAlias = true;
  };

  programs.nvf = {
    enable = true;

    settings.vim = {
      vimAlias = false;
      viAlias = true;
      theme = {
        enable = true;
        name = "base16";
        base16-colors = {
          base00 = "000000";
          base01 = "2a2a2a";
          base02 = "555555";
          base03 = "808080";
          base04 = "a1a1a1";
          base05 = "c0c0c0";
          base06 = "e0e0e0";
          base07 = "ffffff";
          base08 = "ff0000";
          base09 = "808000";
          base0A = "ffff00";
          base0B = "00ff00";
          base0C = "00ffff";
          base0D = "0000ff";
          base0E = "ff00ff";
          base0F = "008000";
          /*
           base00 = "${palette.base00}";
          base01 = "${palette.base01}";
          base02 = "${palette.base02}";
          base03 = "${palette.base03}";
          base04 = "${palette.base04}";
          base05 = "${palette.base05}";
          base06 = "${palette.base06}";
          base07 = "${palette.base07}";
          base08 = "${palette.base08}";
          base09 = "${palette.base09}";
          base0A = "${palette.base0A}";
          base0B = "${palette.base0B}";
          base0C = "${palette.base0C}";
          base0D = "${palette.base0D}";
          base0E = "${palette.base0E}";
          base0F = "4D4D4D"; #0F too dark
          */
        };
      };

      keymaps = [
        {
          key = "<leader>y";
          mode = ["v" "n"];
          action = ''"+y'';
          desc = "Yank into system clipboard";
        }
        {
          key = "<leader>Y";
          mode = ["v" "n"];
          action = ''"+yg_'';
          desc = "Yank to the right of cursor into system clipboard";
        }
        {
          key = "<leader>p";
          mode = ["v" "n"];
          action = ''"+p'';
          desc = "Paste from system clipboard";
        }
        {
          key = "<leader>P";
          mode = ["v" "n"];
          action = ''"+P'';
          desc = "Paste to the left of cursor from system clipboard";
        }
        {
          key = "<C-h>";
          mode = ["i"];
          action = "<Left>";
          desc = "Move left in insert mode";
        }
        {
          key = "<C-j>";
          mode = ["i"];
          action = "<Down>";
          desc = "Move down in insert mode";
        }
        {
          key = "<C-k>";
          mode = ["i"];
          action = "<Up>";
          desc = "Move up in insert mode";
        }
        {
          key = "<C-l>";
          mode = ["i"];
          action = "<Right>";
          desc = "Move right in insert mode";
        }
        {
          key = "<leader>nt";
          mode = ["n"];
          action = "<cmd>Neotree toggle<cr>";
          desc = "File browser toggle";
        }
        {
          key = "<leader>nh";
          mode = ["n"];
          action = ":nohl<CR>";
          desc = "Clear search highlights";
        }
        {
          key = "<leader>?";
          mode = ["n"];
          action = "<cmd>Cheatsheet<cr>";
          desc = "Opens cheatsheet.nvim";
        }
      ];

      options = {
        autoindent = true;
        wrap = false;
        tabstop = 4;
        shiftwidth = 4;
      };

      syntaxHighlighting = true;

      telescope.enable = true;
      spellcheck = {
        enable = true;
      };

      lsp = {
        formatOnSave = true;
        lspkind.enable = false;
        lightbulb.enable = false;
        trouble.enable = true;
        lspSignature.enable = true;
        nvim-docs-view.enable = false;
        inlayHints.enable = true;
      };

      languages = {
        enableLSP = true;
        enableFormat = true;
        enableTreesitter = true;
        enableExtraDiagnostics = true;

        python.enable = true;
        ts.enable = true;
        markdown.enable = true;
        rust.enable = true;
        clang.enable = true;
        bash.enable = true;
        tailwind.enable = true;
        html.enable = true;
        lua.enable = true;
        nix = {
          enable = true;
          format = {
            enable = true;
            type = "alejandra";
          };
        };
        typst = {
          enable = true;
          extensions.typst-preview-nvim.enable = true;
          format = {
            enable = true;
            type = "typstfmt";
          };
        };
        css = {
          enable = true;
          format.enable = true;
        };
      };

      visuals = {
        nvim-cursorline.enable = true;
        cinnamon-nvim = {
          enable = false;
          setupOpts.keymaps.basic = true;
        };
        fidget-nvim.enable = true;

        highlight-undo.enable = true;
        indent-blankline.enable = true;
      };

      statusline = {
        lualine = {
          enable = true;
          theme = "auto";
        };
      };

      autopairs.nvim-autopairs.enable = true;

      autocomplete.nvim-cmp.enable = true;
      snippets.luasnip.enable = true;

      tabline = {
        nvimBufferline.enable = true;
      };

      treesitter = {
        context.enable = false; #annoying
        indent.enable = false; #annoying indenter
      };

      binds = {
        whichKey.enable = true;
        cheatsheet.enable = true;
      };

      git = {
        enable = true;
        gitsigns.enable = true;
        gitsigns.codeActions.enable = false; # throws an annoying debug message
      };

      filetree.neo-tree = {
        enable = true;
      };

      dashboard = {
        dashboard-nvim.enable = true;
        alpha.enable = true;
      };

      notify = {
        nvim-notify.enable = true;
      };

      utility = {
        ccc.enable = false;
        vim-wakatime.enable = false;
        icon-picker.enable = false;
        surround.enable = true;
        diffview-nvim.enable = true;
        nix-develop.enable = true;
        motion = {
          precognition.enable = true;
        };

        images = {
          image-nvim.enable = false;
        };
      };

      ui = {
        borders.enable = true;
        noice.enable = true;
        colorizer.enable = true;
        illuminate.enable = true;
        breadcrumbs = {
          enable = false;
          navbuddy.enable = false;
        };
        smartcolumn = {
          enable = true;
        };
        fastaction.enable = true;
      };

      session = {
        nvim-session-manager.enable = false;
      };

      comments = {
        comment-nvim.enable = true;
      };
    };
  };
}
