{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: {
  imports = [inputs.nvf.homeManagerModules.default];

  programs.neovim = lib.mkForce {
    enable = true;
    vimAlias = true;
  };

  programs.nvf = {
    enable = true;

    settings.vim = {
      vimAlias = false;
      viAlias = true;
      theme = {
        enable = false;
        name = "base16";
        base16-colors = {
          base00 = "f4fbf4";
          base01 = "cfe8cf";
          base02 = "8ca68c";
          base03 = "809980";
          base04 = "687d68";
          base05 = "5e6e5e";
          base06 = "242924";
          base07 = "131513";
          base08 = "e6193c";
          base09 = "87711d";
          base0A = "98981b";
          base0B = "29a329";
          base0C = "1999b3";
          base0D = "3d62f5";
          base0E = "ad2bee";
          base0F = "e619c3";
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
        termguicolors = false;
      };

      syntaxHighlighting = true;

      telescope.enable = true;
      spellcheck = {
        enable = false;
      };

      lsp = {
        formatOnSave = true;
        lspkind.enable = true;
        trouble.enable = true;
        lspSignature.enable = true;
        nvim-docs-view.enable = false;
        inlayHints.enable = false;
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
        ccc.enable = true;
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
