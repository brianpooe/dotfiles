return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  keys = {
    { '<leader>e', '<cmd>NvimTreeToggle<cr>' },
  },
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    local nvimtree = require 'nvim-tree'
    -- disable netrw at the very start of your init.lua
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- optionally enable 24-bit colour
    vim.opt.termguicolors = true

    -- OR setup with some options
    nvimtree.setup {
      sort = {
        sorter = 'case_sensitive',
      },
      view = {
        width = 50,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = false,
        custom = { '^.git$' },
      },
      git = {
        enable = true,
        ignore = false,
      },
    }
  end,
}
