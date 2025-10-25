return {
  {
    'mason-org/mason-lspconfig.nvim',
    opts = {
      -- list of servers for mason to install
      ensure_installed = {
        'gopls',
        'ts_ls',
        'angularls',
        'cssls',
        'lua_ls',
        'emmet_ls',
        'emmet_language_server',
        'dockerls',
        'denols',
        'jsonls',
        'sqlls',
        'bashls',
        'vimls',
        'html',
        'tailwindcss',
        'svelte',
        'graphql',
        'pyright',
        'eslint',
        'rust_analyzer',
        'yamlls',
        'docker_compose_language_service',
        'terraformls',
        'omnisharp',
        'marksman',
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
        'prettierd',
        'prettier',
        'stylua',
        'eslint_d',
        'stylua',
        'shellcheck',
        'editorconfig-checker',
        'luacheck',
        'shellcheck',
        'shfmt',
        'vint',
        'ruff',
        'goimports',
        'ast_grep',
        'yamlfmt',
        'csharpier',
        'cbfmt',
      },
      integrations = {
        ['mason-lspconfig'] = true,
      },
    },
  },
}
