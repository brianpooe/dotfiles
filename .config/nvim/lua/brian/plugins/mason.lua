local offline = vim.g.offline_mode
local preparing = vim.env.NVIM_OFFLINE_PREPARE == '1'
local online = not offline
local auto_install = online and not preparing
local skip_prepare_packages = {}

do
  local raw = vim.env.PREPARE_SKIP_MASON_PACKAGES or ''
  for name in string.gmatch(raw, '([^,]+)') do
    local trimmed = vim.trim(name)
    if trimmed ~= '' then
      skip_prepare_packages[trimmed] = true
    end
  end
end

local lsp_servers = {
  'angularls',
  'bashls',
  'cssls',
  'docker_compose_language_service',
  'dockerls',
  'emmet_language_server',
  'eslint',
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
  'ast-grep',
  'cbfmt',
  'debugpy',
  'editorconfig-checker',
  'eslint_d',
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

local function dedupe(list)
  local seen = {}
  local out = {}
  for _, item in ipairs(list) do
    if not seen[item] then
      seen[item] = true
      table.insert(out, item)
    end
  end
  return out
end

local function filter_skips(list)
  if not preparing or vim.tbl_count(skip_prepare_packages) == 0 then
    return list
  end
  local out = {}
  for _, item in ipairs(list) do
    if not skip_prepare_packages[item] then
      table.insert(out, item)
    end
  end
  return out
end

local configured_mason_packages = dedupe(
  vim.list_extend(vim.deepcopy(tools), lsp_servers)
)
local prepare_tools = filter_skips(vim.deepcopy(configured_mason_packages))
local tool_installer_list = preparing and prepare_tools or configured_mason_packages

return {
  {
    'mason-org/mason-lspconfig.nvim',
    opts = {
      -- skip auto-install when offline; packages are pre-installed
      -- during offline prepare we install LSP packages via MasonToolsInstallSync
      ensure_installed = auto_install and lsp_servers or {},
      -- Only auto-enable the LSP servers we explicitly manage in this config.
      -- This avoids accidental multi-server attaches (e.g. ts_ls + vtsls),
      -- which can produce duplicate Telescope definition results.
      automatic_enable = lsp_servers,
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
      -- during offline prepare we install tools + lsp packages in one sync pass
      ensure_installed = tool_installer_list,
      integrations = {
        -- keep mapping enabled so lspconfig names (e.g. ts_ls) resolve to Mason packages
        ['mason-lspconfig'] = true,
      },
      run_on_start = auto_install,
      start_delay = 0,
    },
  },
}
