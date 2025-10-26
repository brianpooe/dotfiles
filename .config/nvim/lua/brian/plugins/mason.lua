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
        'emmet_ls',
        'eslint',
        'gopls',
        'graphql',
        'html',
        'jsonls',
        'lua_ls',
        'marksman',
        'omnisharp',
        'pyright',
        'rust_analyzer',
        'sqlls',
        'svelte',
        'tailwindcss',
        'terraformls',
        'ts_ls',
        'vimls',
        'yamlls',
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
        'editorconfig-checker',
        'eslint_d',
        'goimports',
        'hadolint',
        'luacheck',
        'prettier',
        'prettierd',
        'ruff',
        'shellcheck',
        'shfmt',
        'stylua',
        'vint',
        'yamlfmt',
      },
      integrations = {
        ['mason-lspconfig'] = true,
      },
    },
  },
}
