return {
  'wojciech-kulik/xcodebuild.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'MunifTanjim/nui.nvim',
    -- "nvim-tree/nvim-tree.lua", -- (optional) to manage project files
    'stevearc/oil.nvim', -- (optional) to manage project files
    'nvim-treesitter', -- (optional) for Quick tests support (required Swift parser)
  },
  ft = { 'swift' },
  config = function()
    require('xcodebuild').setup {
      -- put some options here or leave it empty to use default settings
    }

    local wk = require 'which-key'

    wk.add {
      {
        '<leader>xC',
        '<CMD>XcodebuildSetup<CR>',
        desc = '[X]code [C]onfigure',
      },
      {
        '<leader>X',
        '<CMD>XcodebuildPicker<CR>',
        desc = 'Show [X]codebuild Actions',
      },
      {
        '<leader>xf',
        '<CMD>XcodebuildProjectManager<CR>',
        desc = 'Show Project Manager Actions',
      },
      -- Build
      {
        '<leader>xb',
        '<CMD>XcodebuildBuild<CR>',
        desc = '[X]code [B]uild project',
      },
      {
        '<leader>xB',
        '<CMD>XcodebuildBuildForTesting<CR>',
        desc = '[X]code [B]uild project for Testing',
      },
      {
        '<leader>xr',
        '<CMD>XcodebuildBuildRun<CR>',
        desc = '[X]code [R]un project',
      },
      -- Tests
      { '<leader>xt', '<CMD>XcodebuildTest<CR>', desc = '[X]code Run [T]ests' },
      {
        '<leader>xT',
        '<CMD>XcodebuildTestClass<CR>',
        desc = '[X]code Run Current Class [T]ests',
      },
      {
        '<leader>x.',
        '<CMD>XcodebuildTestRepeat<CR>',
        desc = '[X]code Repeat Last Tests',
      },
      -- Selection
      {
        '<leader>xd',
        '<CMD>XcodebuildSelectDevice<CR>',
        desc = '[X]code Select [D]evice',
      },
      {
        '<leader>xp',
        '<CMD>XcodebuildSelectTestPlan<CR>',
        desc = '[X]code Select Test [P]lan',
      },
      -- Logs
      {
        '<leader>xl',
        '<CMD>XcodebuildToggleLogs<CR>',
        desc = '[X]code Toggle [L]ogs',
      },
    }
  end,
}
