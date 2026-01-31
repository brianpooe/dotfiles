local keymap = vim.keymap -- for conciseness
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
    keymap.set('n', 'gD', '<cmd>Telescope lsp_definitions<CR>', opts) -- go to declaration

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
      '<cmd>Telescope lsp_type_definitions<CR>',
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

    opts.desc = 'Show documentation for what is under cursor'
    keymap.set('n', 'K', function()
      vim.lsp.buf.hover { border = 'rounded' }
    end, opts)

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
