#!/usr/bin/env bash

################################################################################
# WARNING:
# This installer is designed solely for macOS and installs Neovim configured
# to the "RubenDguez" standards (LazyVim + Everforest + TypeScript LSP + Telescope + custom keymaps).
# No support will be provided for issues, errors, or unexpected behavior.
# Use this installer at your own discretion.
################################################################################

# 1️⃣ Remove existing Neovim installation and config
echo "Removing existing Neovim..."
brew uninstall --ignore-dependencies neovim &>/dev/null
rm -rf ~/.config/nvim &>/dev/null
rm -rf ~/.local/share/nvim &>/dev/null
rm -rf ~/.cache/nvim &>/dev/null

# 2️⃣ Update Homebrew
echo "Updating Homebrew..."
brew update &>/dev/null

# 3️⃣ Install Neovim and dependencies
echo "Installing Neovim and dependencies..."
brew install neovim tree-sitter-cli luarocks lazygit ripgrep fd &>/dev/null

# 4️⃣ Clone LazyVim starter
echo "Cloning LazyVim starter..."
git clone https://github.com/LazyVim/starter ~/.config/nvim -q

# 5️⃣ Overwrite lazy.lua to include Everforest, Telescope, and Mason LSP
echo "Configuring LazyVim plugins..."
mkdir -p ~/.config/nvim/lua/config
cat <<'EOF' >~/.config/nvim/lua/config/lazy.lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },

    -- Everforest colorscheme plugin
    {
      "sainnhe/everforest",
      lazy = false,
      priority = 1000,
      config = function()
        vim.cmd([[colorscheme everforest]])
      end,
    },

    -- Telescope fuzzy finder
    {
      "nvim-telescope/telescope.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      lazy = false,
      config = function()
        require("telescope").setup({
          defaults = {
            file_ignore_patterns = { "node_modules", ".git/" },
          },
        })
      end,
    },
  },
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "everforest" } },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = { disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
  },
})

-- Mason LSP configuration
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "ts_ls",
  },
})
EOF

# 6️⃣ Add custom keymaps
echo "Adding custom keymaps..."
cat <<'EOF' >~/.config/nvim/lua/config/keymaps.lua
-- Terminal toggle
vim.keymap.set("n", "<leader>tt", function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
      vim.api.nvim_buf_delete(buf, { force = true })
      return
    end
  end
  vim.cmd("split | terminal")
end, { noremap = true, silent = true })

-- Buffer navigation
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>bt", "gg", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>bb", "G", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>bh", "^", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>bl", "$", { noremap = true, silent = true})

-- Telescope keymaps
vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>fh", ":Telescope help_tags<CR>", { noremap = true, silent = true })
EOF

# 7️⃣ Headless plugin update & sync
echo "Updating and syncing plugins..."
nvim --headless \
  -c 'silent! lua require("lazy").setup()' \
  -c 'silent! Lazy! update' \
  -c 'silent! Lazy! sync' \
  -c 'qa!' &>/dev/null

echo "✅ Neovim + LazyVim installed, Everforest set as default, Telescope installed, custom keymaps added, TypeScript LSP configured."
