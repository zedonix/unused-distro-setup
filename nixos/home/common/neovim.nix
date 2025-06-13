{
  pkgs,
  ...
}:

{
  programs.neovim = 
    let
    toLua = str: "lua << EOF\n${str}\nEOF\n";
  in
 {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraPackages = with pkgs; [
      lua-language-server
      stylua
      nixd
      nixfmt-rfc-style
      pyright
      black
      ruff
    ];
    plugins = with pkgs.vimPlugins; [
      {
        plugin = gruvbox-material-nvim;
      }
      {
        plugin = nvim-lspconfig;
        config = toLua ''
          require("lspconfig").lua_ls.setup({
              settings = {
                  Lua = {
                      diagnostics = {
                          globals = { "vim" },
                      },
                  },
              },
          })
          require("lspconfig").pyright.setup({})
          require("lspconfig").nixd.setup({})
          require("lspconfig").clangd.setup({})
          vim.api.nvim_create_autocmd("LspAttach", {
              callback = function(args)
                  local bufnr = args.buf
                  vim.keymap.set("n", "<Leader>r", vim.lsp.buf.rename, { buffer = bufnr })
              end,
          })
        '';
      }
      {
        plugin = (
          nvim-treesitter.withPlugins (p: [
            p.tree-sitter-nix
            p.tree-sitter-bash
            p.tree-sitter-lua
            p.tree-sitter-python
            p.tree-sitter-c
          ])
        );
        config = toLua ''
          require("nvim-treesitter.configs").setup({
              ensure_installed = {},
              auto_install = false,
              highlight = { enable = true },
              indent = { enable = true },
          })
        '';
      }
      {
        plugin = vimwiki;
        config = toLua ''
          vim.g.vimwiki_list = {
              {
                  path = "~/vimwiki/",
                  syntax = "markdown",
                  ext = ".md",
              },
          }
        '';
      }
      {
        plugin = vimtex;
        config = toLua ''
          vim.g.vimtex_view_method = "zathura"
          vim.g.vimtex_mappings_prefix = "\\"
        '';
      }
    ];

    extraLuaConfig = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      vim.g.netrw_banner = 0
      vim.g.netrw_browse_split = 4
      vim.g.netrw_altv = 1
      vim.g.netrw_liststyle = 3

      vim.g.have_nerd_font = true
      vim.o.termguicolors = true
      vim.o.background = "dark"
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_transparent_background = 1
      vim.cmd("colorscheme gruvbox-material")
      -- Set Normal background to transparent
      vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })

      -- Set other relevant highlight groups
      -- vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })     -- Sign column (gutter)
      vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE" }) -- End of buffer
      vim.api.nvim_set_hl(0, "NonText", { bg = "NONE" }) -- Non-text characters (e.g., whitespace)
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" }) -- Normal background for non-current windows
      -- vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })    -- Status line
      -- vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })  -- Non-current status line

      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.mouse = "a"

      vim.opt.breakindent = true
      vim.opt.undofile = true
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.signcolumn = "yes"
      -- vim.opt.wrap = false

      vim.opt.updatetime = 250
      vim.opt.timeoutlen = 500
      vim.opt.splitright = true
      vim.opt.splitbelow = true

      vim.opt.list = true
      vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
      vim.opt.inccommand = "split"
      vim.opt.cursorline = false
      vim.opt.scrolloff = 18
      -- vim.opt.sidescrolloff = 18

      vim.opt.expandtab = true
      vim.opt.tabstop = 4
      vim.opt.shiftwidth = 4

      -- Clipboard Functionality
      vim.schedule(function()
          vim.opt.clipboard = "unnamedplus"
      end)

      -- Highlight on Yank
      vim.api.nvim_create_autocmd("TextYankPost", {
          desc = "Highlight when yanking (copying) text",
          group = vim.api.nvim_create_augroup("yank", { clear = true }),
          callback = function()
              vim.highlight.on_yank()
          end,
      })

      function Map(mode, lhs, rhs, opts)
          local options = { noremap = true, silent = true }
          if opts then
              options = vim.tbl_extend("force", options, opts)
          end
          vim.api.nvim_set_keymap(mode, lhs, rhs, options)
      end

      function Format()
          local extension = vim.bo.filetype
          if extension == "lua" then
              Formatter = "stylua"
          elseif extension == "python" then
              Formatter = "ruff format"
          elseif extension == "nix" then
              Formatter = "nixfmt"
          elseif extension == "c" or extension == "cpp" then
              Formatter = "clang-format"
          else
              Formatter = "echo"
          end
          return string.format("!%s %%", Formatter)
      end

      -- Tree & Buffer Keybindings
      Map("n", "<Leader>b", "<cmd>ls<CR>")
      Map("n", "<Leader>f", "<cmd>:18Lex<CR>")

      vim.api.nvim_create_user_command("FormatFile", function()
          local command = Format()
          vim.cmd(command)
      end, { desc = "Format the current file" })

      -- Misc Keybindings
      Map("n", "<Esc>", "<cmd>nohlsearch<CR>")
      Map("n", "<Leader>s", "<cmd>:FormatFile<CR>")
      Map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

      Map("n", "j", "gj")
      Map("n", "k", "gk")
    '';
  };
}
