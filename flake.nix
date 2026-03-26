{
  description = "Custom NVF configuration with Rust, Telescope, and Lualine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
  };

  outputs = { self, nixpkgs, nvf, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          myNvfConfig = nvf.lib.neovimConfiguration {
            inherit pkgs;
            modules = [
              {
                vim.viAlias = false;
                vim.vimAlias = false;

                vim = {
                  globals.mapleader = " ";
                  extraPackages = [ 
                    pkgs.lua-language-server 
                    pkgs.nodePackages.bash-language-server 
                  ];

                  # Lua Status Bar
                  statusline.lualine.enable = true;

                  # Telescope
                  telescope.enable = true;

                  # Rust Support
                  languages.rust = {
                    enable = true;
                    lsp.enable = true;
                    treesitter.enable = true;
                  };

                  # Nix Language Support
                  languages.nix = {
                    enable = true;
                    lsp.enable = true;
                    lsp.servers = ["nixd"];
                    treesitter.enable = true;
                    format.enable = true; 
                  };

                  # Lua Language Support
                  languages.lua = {
                    enable = true;
                    lsp.enable = true;
                    treesitter.enable = true;
                  };

                  # Nvim Tree
                  filetree.nvimTree = {
                    enable = true;
                    openOnSetup = false;
                  };

                  # Keybind Menu
                  binds.whichKey.enable = true;

                  # System Clipboard Integration
                  clipboard.registers = "unnamedplus";

                  # Indentation Detection
                  utility.sleuth.enable = true;

                  # Theme
                  theme = {
                    enable = true;
                    name = "gruvbox";
                    style = "dark";
                  };
                  
                  # Enables nvim-cmp
                  autocomplete.nvim-cmp = {
                    enable = true; 
                    mappings = {
                      next = "<A-j>";
                      previous = "<A-k>";
                      confirm = "<Tab>";
                    };
                  };

                  # Custom Keybindings
                  keymaps = [
                    {
                      key = ";";
                      mode = [ "n" "v" ];
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
