return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    -- Adapters
    'nvim-neotest/neotest-jest',
    'nvim-neotest/neotest-python',
    -- Rust uses rustaceanvim's built-in neotest adapter
  },
  keys = {
    {
      '<leader>tt',
      function()
        require('neotest').run.run()
      end,
      desc = 'Run nearest test',
    },
    {
      '<leader>tf',
      function()
        require('neotest').run.run(vim.fn.expand '%')
      end,
      desc = 'Run current file tests',
    },
    {
      '<leader>ta',
      function()
        require('neotest').run.run(vim.uv.cwd())
      end,
      desc = 'Run all tests',
    },
    {
      '<leader>ts',
      function()
        require('neotest').summary.toggle()
      end,
      desc = 'Toggle test summary',
    },
    {
      '<leader>to',
      function()
        require('neotest').output.open { enter = true, auto_close = true }
      end,
      desc = 'Show test output',
    },
    {
      '<leader>tO',
      function()
        require('neotest').output_panel.toggle()
      end,
      desc = 'Toggle output panel',
    },
    {
      '<leader>tS',
      function()
        require('neotest').run.stop()
      end,
      desc = 'Stop test run',
    },
    {
      '<leader>tw',
      function()
        require('neotest').watch.toggle(vim.fn.expand '%')
      end,
      desc = 'Toggle test watch',
    },
    {
      '<leader>td',
      function()
        require('neotest').run.run { strategy = 'dap' }
      end,
      desc = 'Debug nearest test',
    },
    {
      '[t',
      function()
        require('neotest').jump.prev { status = 'failed' }
      end,
      desc = 'Previous failed test',
    },
    {
      ']t',
      function()
        require('neotest').jump.next { status = 'failed' }
      end,
      desc = 'Next failed test',
    },
  },
  config = function()
    require('neotest').setup {
      adapters = {
        require 'neotest-jest' {
          jestCommand = 'npm test --',
          jestConfigFile = 'jest.config.js',
          env = { CI = true },
          cwd = function()
            return vim.fn.getcwd()
          end,
        },
        require 'neotest-python' {
          dap = { justMyCode = false },
          args = { '--log-level', 'DEBUG' },
          runner = 'pytest',
        },
        require 'rustaceanvim.neotest',
      },
      status = {
        virtual_text = true,
      },
      output = {
        open_on_run = true,
      },
      quickfix = {
        open = function()
          vim.cmd 'copen'
        end,
      },
    }
  end,
}
