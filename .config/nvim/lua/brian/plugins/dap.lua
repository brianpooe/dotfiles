return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- UI
    {
      'rcarriga/nvim-dap-ui',
      dependencies = { 'nvim-neotest/nvim-nio' },
      keys = {
        {
          '<leader>du',
          function()
            require('dapui').toggle {}
          end,
          desc = 'Toggle DAP UI',
        },
        {
          '<leader>de',
          function()
            require('dapui').eval()
          end,
          mode = { 'n', 'v' },
          desc = 'Eval expression',
        },
      },
      opts = {},
      config = function(_, opts)
        local dap = require 'dap'
        local dapui = require 'dapui'
        dapui.setup(opts)
        dap.listeners.after.event_initialized['dapui_config'] = function()
          dapui.open {}
        end
        dap.listeners.before.event_terminated['dapui_config'] = function()
          dapui.close {}
        end
        dap.listeners.before.event_exited['dapui_config'] = function()
          dapui.close {}
        end
      end,
    },
    -- Virtual text for variable values
    {
      'theHamsta/nvim-dap-virtual-text',
      opts = {},
    },
    -- Mason integration for installing debug adapters
    {
      'jay-babu/mason-nvim-dap.nvim',
      dependencies = 'mason.nvim',
      cmd = { 'DapInstall', 'DapUninstall' },
      opts = {
        automatic_installation = not vim.g.offline_mode,
        handlers = {},
        ensure_installed = not vim.g.offline_mode and {
          'python',
          'js',
          'codelldb',
        } or {},
      },
    },
  },
  keys = {
    {
      '<leader>dB',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Conditional breakpoint',
    },
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Toggle breakpoint',
    },
    {
      '<leader>dc',
      function()
        require('dap').continue()
      end,
      desc = 'Continue',
    },
    {
      '<leader>dC',
      function()
        require('dap').run_to_cursor()
      end,
      desc = 'Run to cursor',
    },
    {
      '<leader>dg',
      function()
        require('dap').goto_()
      end,
      desc = 'Go to line (no execute)',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = 'Step into',
    },
    {
      '<leader>dj',
      function()
        require('dap').down()
      end,
      desc = 'Down in stack',
    },
    {
      '<leader>dk',
      function()
        require('dap').up()
      end,
      desc = 'Up in stack',
    },
    {
      '<leader>dl',
      function()
        require('dap').run_last()
      end,
      desc = 'Run last',
    },
    {
      '<leader>do',
      function()
        require('dap').step_out()
      end,
      desc = 'Step out',
    },
    {
      '<leader>dO',
      function()
        require('dap').step_over()
      end,
      desc = 'Step over',
    },
    {
      '<leader>dp',
      function()
        require('dap').pause()
      end,
      desc = 'Pause',
    },
    {
      '<leader>dr',
      function()
        require('dap').repl.toggle()
      end,
      desc = 'Toggle REPL',
    },
    {
      '<leader>ds',
      function()
        require('dap').session()
      end,
      desc = 'Session',
    },
    {
      '<leader>dt',
      function()
        require('dap').terminate()
      end,
      desc = 'Terminate',
    },
    {
      '<leader>dw',
      function()
        require('dap.ui.widgets').hover()
      end,
      desc = 'Widgets',
    },
  },
  config = function()
    local dap = require 'dap'

    -- Signs
    vim.fn.sign_define(
      'DapBreakpoint',
      { text = '', texthl = 'DiagnosticError', linehl = '', numhl = '' }
    )
    vim.fn.sign_define(
      'DapBreakpointCondition',
      { text = '', texthl = 'DiagnosticWarn', linehl = '', numhl = '' }
    )
    vim.fn.sign_define(
      'DapLogPoint',
      { text = '', texthl = 'DiagnosticInfo', linehl = '', numhl = '' }
    )
    vim.fn.sign_define(
      'DapStopped',
      {
        text = '',
        texthl = 'DiagnosticOk',
        linehl = 'DapStoppedLine',
        numhl = '',
      }
    )
    vim.fn.sign_define(
      'DapBreakpointRejected',
      { text = '', texthl = 'DiagnosticError', linehl = '', numhl = '' }
    )

    -- Highlight for stopped line
    vim.api.nvim_set_hl(
      0,
      'DapStoppedLine',
      { default = true, link = 'Visual' }
    )

    -- Python configuration
    dap.adapters.python = function(cb, config)
      if config.request == 'attach' then
        local port = (config.connect or config).port
        local host = (config.connect or config).host or '127.0.0.1'
        cb {
          type = 'server',
          port = assert(
            port,
            '`connect.port` is required for a python `attach` configuration'
          ),
          host = host,
          options = {
            source_filetype = 'python',
          },
        }
      else
        cb {
          type = 'executable',
          command = vim.fn.exepath 'python3',
          args = { '-m', 'debugpy.adapter' },
          options = {
            source_filetype = 'python',
          },
        }
      end
    end

    dap.configurations.python = {
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        pythonPath = function()
          local cwd = vim.fn.getcwd()
          if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
            return cwd .. '/venv/bin/python'
          elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
            return cwd .. '/.venv/bin/python'
          else
            return vim.fn.exepath 'python3'
          end
        end,
      },
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file with arguments',
        program = '${file}',
        args = function()
          local args_string = vim.fn.input 'Arguments: '
          return vim.split(args_string, ' +')
        end,
        pythonPath = function()
          local cwd = vim.fn.getcwd()
          if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
            return cwd .. '/venv/bin/python'
          elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
            return cwd .. '/.venv/bin/python'
          else
            return vim.fn.exepath 'python3'
          end
        end,
      },
    }

    -- JavaScript/TypeScript configuration
    local js_debug_path = vim.fn.stdpath 'data'
      .. '/mason/packages/js-debug-adapter'

    dap.adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'node',
        args = { js_debug_path .. '/js-debug/src/dapDebugServer.js', '${port}' },
      },
    }

    dap.adapters['pwa-chrome'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'node',
        args = { js_debug_path .. '/js-debug/src/dapDebugServer.js', '${port}' },
      },
    }

    local js_config = {
      {
        type = 'pwa-node',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        cwd = '${workspaceFolder}',
      },
      {
        type = 'pwa-node',
        request = 'attach',
        name = 'Attach to process',
        processId = require('dap.utils').pick_process,
        cwd = '${workspaceFolder}',
      },
      {
        type = 'pwa-chrome',
        request = 'launch',
        name = 'Launch Chrome',
        url = 'http://localhost:4200', -- Angular default port
        webRoot = '${workspaceFolder}',
      },
    }

    dap.configurations.javascript = js_config
    dap.configurations.typescript = js_config
    dap.configurations.javascriptreact = js_config
    dap.configurations.typescriptreact = js_config

    -- Rust/C/C++ uses codelldb (configured via rustaceanvim)
  end,
}
