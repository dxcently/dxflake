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
        enable = true;
        name = "rose-pine";
        style = "main";
        /*
        base16-colors = {
          base00 = "eeeeee"; # Default Background
              base01 = "af0000"; # Lighter Background (Used for status bars, line number and folding marks)
          base02 = "008700"; # Selection Background
          base03 = "5f8700"; # Comments, Invisibles, Line Highlighting
          base04 = "0087af"; # Dark Foreground (Used for status bars)
          base05 = "444444"; # Default Foreground, Caret, Delimiters, Operators
          base06 = "005f87"; # Light Foreground (Not often used)
          base07 = "878787"; # Light Background (Not often used)
          base08 = "bcbcbc"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
          base09 = "d70000"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url
          base0A = "d70087"; # Classes, Markup Bold, Search Text Background
          base0B = "8700af"; # Strings, Inherited Class, Markup Code, Diff Inserted
          base0C = "d75f00"; # Support, Regular Expressions, Escape Characters, Markup Quotes
          base0D = "d75f00"; # Functions, Methods, Attribute IDs, Headings
          base0E = "005faf"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
          base0F = "005f87"; # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?>
        };
        */
      };

      keymaps = [
        {
          key = "<leader>y";
          mode = ["v" "n"];
          action = ''"+y'';
          desc = "Yank into system clipboard";
        }
        {
          key = "<leader>d";
          mode = ["v" "n"];
          action = ''"+d'';
          desc = "Cut into system clipboard";
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
        termguicolors = true;
      };

      syntaxHighlighting = true;

      telescope.enable = true;
      spellcheck = {
        enable = false;
      };

      lsp = {
        enable = true;
        formatOnSave = true;
        lspkind.enable = true;
        trouble.enable = true;
        lspSignature.enable = true;
        nvim-docs-view.enable = false;
        inlayHints.enable = false;
      };

      languages = {
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
