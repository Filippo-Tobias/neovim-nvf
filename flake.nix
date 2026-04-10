{
  description = "Custom NVF configuration with Rust, Telescope, and Lualine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
  };

  outputs =
    {
      self,
      nixpkgs,
      nvf,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          myNvfConfig = nvf.lib.neovimConfiguration {
            inherit pkgs;
            modules = [
              {
                vim.viAlias = false;
                vim.vimAlias = false;

                vim.luaConfigRC.yankSync = /* lua */ ''
                  vim.api.nvim_create_autocmd("TextYankPost", {
                    group = vim.api.nvim_create_augroup("YankToSystem", { clear = true }),
                    callback = function()
                      if vim.v.event.operator == "y" then
                        vim.fn.setreg("+", vim.fn.getreg('"'))
                      end
                    end,
                  })
                '';

                vim.luaConfigRC.pasteWithNewline # lua
                  = ''
                    vim.keymap.set('x', 'P', function()
                      vim.cmd('normal! gvp`]')
                      vim.api.nvim_put({""}, "c", true, true)
                    end, { desc = 'Reliably paste then newline' })
                  '';
                vim.luaConfigRC.smartBlockAlign # lua
                  = ''

                    _G.AlignBlockIndent = function(align_to)

                      local start_line = vim.fn.line("'<")
                      local end_line = vim.fn.line("'>")

                      if start_line == end_line then return end

                      local ref_line, target_line, shift_start, shift_end

                      if align_to == "top" then
                        ref_line = start_line
                        target_line = end_line
                        shift_start = start_line + 1
                        shift_end = end_line
                      else
                        ref_line = end_line
                        target_line = start_line
                        shift_start = start_line
                        shift_end = end_line - 1
                      end

                      local ref_indent = vim.fn.indent(ref_line)
                      local target_indent = vim.fn.indent(target_line)
                      local diff = ref_indent - target_indent

                      if diff == 0 then return end

                      for i = shift_start, shift_end do
                        local line_str = vim.fn.getline(i)
                        
                        if line_str:match("%S") then 
                          local current_ws = line_str:match("^%s*")
                          local content = line_str:gsub("^%s*", "")
                          
                          local expanded_ws_len = vim.fn.strdisplaywidth(current_ws)
                          local new_ws_len = math.max(0, expanded_ws_len + diff)
                          
                          vim.fn.setline(i, string.rep(" ", new_ws_len) .. content)
                        end
                      end
                    end
                  '';

                vim.luaConfigRC.autoBracketAlign = /* lua */ ''
                  _G.AutoAlignBracket = function()
                    local start_line = vim.fn.line('.')
                    local start_col = vim.fn.col('.')
                    local line_str = vim.fn.getline('.')
                    local current_char = line_str:sub(start_col, start_col)

                    if current_char ~= "{" and current_char ~= "}" then
                      vim.notify("Cursor must be exactly on a '{' or '}'", vim.log.levels.WARN)
                      return
                    end

                    local win_view = vim.fn.winsaveview()

                    vim.cmd("normal! %")
                    local match_line = vim.fn.line('.')

                    vim.fn.winrestview(win_view)

                    if start_line == match_line then return end

                    if current_char == "{" then
                      vim.fn.setpos("'<", {0, start_line, 1, 0})
                      vim.fn.setpos("'>", {0, match_line, 1, 0})
                      _G.AlignBlockIndent("top")
                    else
                      vim.fn.setpos("'<", {0, match_line, 1, 0})
                      vim.fn.setpos("'>", {0, start_line, 1, 0})
                      _G.AlignBlockIndent("bottom")
                    end
                  end
                '';

                vim = {
                  globals.mapleader = " ";
                  lineNumberMode = "number";

                  extraPackages = [
                    pkgs.lua-language-server
                    pkgs.nodePackages.bash-language-server
                    pkgs.typescript-language-server
                    pkgs.vtsls
                    pkgs.typescript
                    pkgs.nixfmt
                    pkgs.jdk25
                    pkgs.netcat
                  ];

                  lsp.enable = true;
                  lsp.formatOnSave = true;
                  lsp.otter-nvim.enable = true;
                  statusline.lualine.enable = true;
                  telescope.enable = true;

                  lsp.servers.gdscript = {
                    enable = true;
                    cmd = [
                      "nc"
                      "127.0.0.1"
                      "6005"
                    ];
                    filetypes = [
                      "gdscript"
                      "gd"
                    ];
                    root_markers = [
                      "project.godot"
                      ".git"
                    ];
                  };

                  lsp.servers.tsgo = {
                    enable = true;
                    root_markers = [
                      "tsconfig.json"
                      "package.json"
                      ".git"
                    ];
                  };

                  languages.rust.enable = true;
                  languages.rust.lsp.enable = true;
                  languages.rust.treesitter.enable = true;

                  languages.python.enable = true;
                  languages.python.lsp.enable = true;
                  languages.python.treesitter.enable = true;

                  languages.java = {
                    enable = true;
                    lsp.enable = true;
                    treesitter.enable = true;
                  };

                  languages.ts = {
                    enable = true;
                    lsp.enable = true;
                    lsp.servers = [ "tsgo" ];
                    treesitter.enable = true;
                  };

                  languages.nix = {
                    enable = true;
                    lsp.enable = true;
                    lsp.servers = [ "nixd" ];
                    treesitter.enable = true;
                    format.enable = true;
                    format.type = [ "nixfmt" ];
                  };

                  languages.lua.enable = true;
                  languages.lua.lsp.enable = true;
                  languages.lua.treesitter.enable = true;
                  languages.markdown.enable = true;

                  tabline.nvimBufferline = {
                    enable = true;
                    setupOpts = {
                      options = {
                        separator_style = "thick";
                        offsets = [
                          {
                            filetype = "NvimTree";
                            text = "File Explorer";
                            highlight = "Directory";
                            text_align = "left";
                          }
                        ];
                      };
                    };
                  };

                  treesitter.grammars = [ pkgs.vimPlugins.nvim-treesitter.builtGrammars.gdscript ];

                  filetree.nvimTree = {
                    enable = true;
                    openOnSetup = false;
                  };
                  binds.whichKey.enable = true;
                  utility.sleuth.enable = true;

                  theme = {
                    enable = true;
                    name = "gruvbox";
                    style = "dark";
                  };

                  autopairs.nvim-autopairs.enable = true;

                  snippets.luasnip.enable = true;

                  autocomplete.blink-cmp = {
                    enable = true;
                    setupOpts.keymap = {
                      preset = "default";
                      "<Tab>" = pkgs.lib.mkForce [
                        "snippet_forward"
                        "select_and_accept"
                        "fallback"
                      ];
                      "<A-j>" = pkgs.lib.mkForce [
                        "select_next"
                        "fallback"
                      ];
                      "<A-k>" = pkgs.lib.mkForce [
                        "select_prev"
                        "fallback"
                      ];
                    };
                  };
                  keymaps = [
                    {
                      mode = "n";
                      key = "<leader><Tab>b";
                      action = ":lua _G.AutoAlignBracket()<CR>";
                      desc = "Align entire {} block to the current bracket";
                    }
                    {
                      mode = [
                        "n"
                        "x"
                      ];
                      key = "p";
                      action = "P";
                      desc = "Paste without copying overwritten text";
                    }
                    {
                      mode = "x";
                      key = "<leader><Tab>k";
                      action = ":<C-u>lua _G.AlignBlockIndent('top')<CR>";
                      desc = "Align block indentation to TOP line";
                    }
                    {
                      mode = "x";
                      key = "<leader><Tab>j";
                      action = ":<C-u>lua _G.AlignBlockIndent('bottom')<CR>";
                      desc = "Align block indentation to BOTTOM line";
                    }
                    {
                      key = "<Esc>";
                      mode = "n";
                      action = ":nohlsearch<CR>";
                      desc = "Clear search highlights on Escape";
                    }
                    {
                      mode = "i";
                      key = "<C-v>";
                      action = "<C-r><C-o>+";
                      desc = "Literal paste from system clipboard";
                    }
                    {
                      mode = "n";
                      key = "<C-v>";
                      action = "\"+p";
                      desc = "Paste from system clipboard";
                    }
                    {
                      key = "<leader>ca";
                      mode = "n";
                      action = ":lua vim.lsp.buf.code_action()<CR>";
                      desc = "LSP Code Actions";
                    }
                    {
                      key = "<C-Space>";
                      mode = "n";
                      action = ":lua vim.diagnostic.open_float()<CR>";
                      desc = "Open diagnostic popup";
                    }
                    {
                      key = ";";
                      mode = [
                        "n"
                        "v"
                      ];
                      action = ":";
                      desc = "Enter command mode";
                    }
                    {
                      key = "<C-n>";
                      mode = "n";
                      action = ":NvimTreeToggle<CR>";
                      desc = "Toggle NvimTree";
                    }
                    {
                      key = "<C-h>";
                      mode = "n";
                      action = "<C-w>h";
                      desc = "Move to left window";
                    }
                    {
                      key = "<C-j>";
                      mode = "n";
                      action = "<C-w>j";
                      desc = "Move to bottom window";
                    }
                    {
                      key = "<C-k>";
                      mode = "n";
                      action = "<C-w>k";
                      desc = "Move to top window";
                    }
                    {
                      key = "<C-l>";
                      mode = "n";
                      action = "<C-w>l";
                      desc = "Move to right window";
                    }
                    {
                      key = "<A-,>";
                      mode = "n";
                      action = ":BufferLineCyclePrev<CR>";
                      desc = "Cycle to previous buffer";
                    }
                    {
                      key = "<A-.>";
                      mode = "n";
                      action = ":BufferLineCycleNext<CR>";
                      desc = "Cycle to next buffer";
                    }
                    {
                      key = "<Tab>";
                      mode = "n";
                      action = ":Telescope buffers<CR>";
                      desc = "Search Buffers (Telescope)";
                    }
                    {
                      key = "<leader>ff";
                      mode = "n";
                      action = ":Telescope find_files<CR>";
                      desc = "Find Files";
                    }
                    {
                      key = "<leader>fg";
                      mode = "n";
                      action = ":Telescope live_grep<CR>";
                      desc = "Live Grep (Project)";
                    }
                    {
                      key = "<leader>fb";
                      mode = "n";
                      action = ":Telescope current_buffer_fuzzy_find<CR>";
                      desc = "Fuzzy Find in Current Buffer";
                    }
                  ];
                };
              }
            ];
          };
        in
        {
          default = myNvfConfig.neovim;
        }
      );
    };
}
