local keymap = vim.keymap -- for conciseness

-- Some servers (e.g. vscode-langservers-extracted/css-lsp) send this request.
-- Neovim may not provide a default handler in some setups, which causes noisy
-- "MethodNotFound" logs from the server side. Treat as a no-op.
vim.lsp.handlers['workspace/diagnostic/refresh'] = function()
  return nil
end

local function hover_if_supported()
  local bufnr = vim.api.nvim_get_current_buf()
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if client.server_capabilities and client.server_capabilities.hoverProvider then
      vim.lsp.buf.hover { border = 'rounded' }
      return
    end
  end
end

-- Avoid default `K` -> `man` behavior in buffers without LSP hover support.
keymap.set('n', 'K', hover_if_supported, { silent = true, desc = 'LSP hover' })

-- Disable semantic tokens for ts_ls so it does not override
-- treesitter injection highlighting in Angular inline templates
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('DisableTsLsSemanticTokens', {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name == 'ts_ls' then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf, silent = true }

    -- set keybinds
    opts.desc = 'Show LSP references'
    keymap.set('n', 'gR', '<cmd>Telescope lsp_references<CR>', opts) -- show definition, references

    opts.desc = 'Go to declaration'
    keymap.set('n', 'gD', vim.lsp.buf.declaration, opts) -- go to declaration

    opts.desc = 'Show LSP definition'
    keymap.set('n', 'gd', '<cmd>Telescope lsp_definitions<CR>', opts) -- show lsp definition

    opts.desc = 'Show LSP implementations'
    keymap.set('n', 'gi', '<cmd>Telescope lsp_implementations<CR>', opts) -- show lsp implementations

    opts.desc = 'Show LSP type definitions'
    keymap.set('n', 'gt', '<cmd>Telescope lsp_type_definitions<CR>', opts) -- show lsp type definitions

    opts.desc = 'See available code actions'
    keymap.set(
      { 'n', 'v' },
      '<leader>ca',
      vim.lsp.buf.code_action,
      opts
    ) -- see available code actions, in visual mode will apply to selection

    opts.desc = 'Smart rename'
    keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts) -- smart rename

    opts.desc = 'Show buffer diagnostics'
    keymap.set('n', '<leader>D', '<cmd>Telescope diagnostics bufnr=0<CR>', opts) -- show  diagnostics for file

    opts.desc = 'Show line diagnostics'
    keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts) -- show diagnostics for line

    opts.desc = 'Go to previous diagnostic'
    keymap.set('n', '[d', function()
      vim.diagnostic.jump { count = -1, float = true }
    end, opts) -- jump to previous diagnostic in buffer
    --
    opts.desc = 'Go to next diagnostic'
    keymap.set('n', ']d', function()
      vim.diagnostic.jump { count = 1, float = true }
    end, opts) -- jump to next diagnostic in buffer

    opts.desc = 'Scroll hover docs down'
    keymap.set('n', '<C-j>', function()
      if not require('noice.lsp').scroll(4) then
        return '<C-j>'
      end
    end, { buffer = ev.buf, silent = true, expr = true })

    opts.desc = 'Scroll hover docs up'
    keymap.set('n', '<C-k>', function()
      if not require('noice.lsp').scroll(-4) then
        return '<C-k>'
      end
    end, { buffer = ev.buf, silent = true, expr = true })
    opts.desc = 'Restart LSP'
    keymap.set('n', '<leader>rs', ':LspRestart<CR>', opts) -- mapping to restart lsp if necessary
  end,
})

vim.lsp.inlay_hint.enable(true)

local severity = vim.diagnostic.severity

vim.diagnostic.config {
  virtual_text = false, -- Disable inline diagnostics
  float = {
    border = 'rounded',
    source = true, -- Show diagnostic source
  },
  signs = {
    text = {
      [severity.ERROR] = ' ',
      [severity.WARN] = ' ',
      [severity.HINT] = '󰠠 ',
      [severity.INFO] = ' ',
    },
  },
}
