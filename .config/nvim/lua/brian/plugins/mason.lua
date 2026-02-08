return {
  {
    'mason-org/mason-lspconfig.nvim',
    opts = {
      -- list of servers for mason to install
      ensure_installed = {
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
        'omnisharp',
        'pyright',
        'sqlls',
        'svelte',
        'tailwindcss',
        'terraformls',
        'ts_ls',
        'vimls',
        'yamlls',
      },
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
      ensure_installed = {
        'ast_grep',
        'cbfmt',
        'csharpier',
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
      },
      integrations = {
        ['mason-lspconfig'] = true,
      },
    },
  },
}
