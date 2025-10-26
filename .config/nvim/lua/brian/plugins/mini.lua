return {
  {
    'nvim-mini/mini.nvim',
    version = false,
    config = function()
      require('mini.ai').setup()
    end,
  },
  {
    'nvim-mini/mini.indentscope',
    version = false,
    config = function()
      require('mini.indentscope').setup()
    end,
  },
  {
    'nvim-mini/mini.pairs',
    version = false,
    config = function()
      require('mini.pairs').setup()
    end,
  },
  {
    'nvim-mini/mini.trailspace',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      local miniTrailspace = require 'mini.trailspace'

      miniTrailspace.setup {
        only_in_normal_buffers = true,
      }
      vim.keymap.set('n', '<leader>cw', function()
        miniTrailspace.trim()
      end, { desc = 'Erase Whitespace' })
    end,
  },
  {
    'nvim-mini/mini.surround',
    version = false,
    config = function()
      require('mini.surround').setup()
    end,
  },
}
