local offline = vim.g.offline_mode

local lsp_servers = {
  'angularls',
  'bashls',
  'cssls',
  'denols',
  'docker_compose_language_service',
  'dockerls',
  'emmet_language_server',
  'eslint',
  'gopls',
  'graphql',
  'html',
  'jsonls',
  'lua_ls',
  'marksman',
  'pyright',
  'sqlls',
  'tailwindcss',
  'terraformls',
  'ts_ls',
  'vimls',
  'yamlls',
}

local tools = {
  'ast_grep',
  'cbfmt',
  'debugpy',
  'editorconfig-checker',
  'eslint_d',
  'goimports',
  'hadolint',
  'js-debug-adapter',
  'luacheck',
  'prettier',
  'prettierd',
  'ruff',
  'shellcheck',
  'shfmt',
  'stylua',
  'vint',
  'yamlfmt',
  'codelldb',
}

return {
  {
    'mason-org/mason-lspconfig.nvim',
    opts = {
      -- skip auto-install when offline; packages are pre-installed
      ensure_installed = not offline and lsp_servers or {},
      -- don't auto-enable rust_analyzer; rustaceanvim manages it
      automatic_enable = {
        exclude = { 'rust_analyzer' },
      },
    },
    dependencies = {
      {
        'mason-org/mason.nvim',
        opts = {
          ui = {
            icons = {
              package_installed = '✓',
              package_pending = '➜',
              package_uninstalled = '✗',
            },
          },
        },
      },
      'neovim/nvim-lspconfig',
    },
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = {
      'mason-org/mason.nvim',
    },
    opts = {
      -- skip auto-install when offline; packages are pre-installed
      ensure_installed = not offline and tools or {},
      integrations = {
        ['mason-lspconfig'] = true,
      },
    },
  },
}
