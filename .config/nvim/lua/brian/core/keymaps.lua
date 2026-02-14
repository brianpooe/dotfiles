-- Keymaps for better default experience
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- For conciseness
local opts = { noremap = true, silent = true }

-- Disable the spacebar key's default behavior in Normal and Visual modes
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Allow moving the cursor through wrapped lines with j, k
vim.keymap.set(
  'n',
  'k',
  "v:count == 0 ? 'gk' : 'k'",
  { expr = true, silent = true }
)
vim.keymap.set(
  'n',
  'j',
  "v:count == 0 ? 'gj' : 'j'",
  { expr = true, silent = true }
)

-- clear highlights
vim.keymap.set('n', '<Esc>', ':noh<CR>', opts)

-- save file
vim.keymap.set('n', '<C-s>', '<cmd> wa <CR>', opts)
vim.keymap.set('n', '<leader>sa', '<cmd> wa <CR>', opts)

-- save file without auto-formatting
vim.keymap.set('n', '<leader>sn', '<cmd>noautocmd w <CR>', opts)

-- quit file
vim.keymap.set('n', '<C-q>', '<cmd> q <CR>', opts)

-- delete single character without copying into register
vim.keymap.set('n', 'x', '"_x', opts)

-- Delete line without copying to clipboard
vim.keymap.set('n', 'dd', '"_dd', opts)

-- Vertical scroll and center
vim.keymap.set('n', '<C-d>', '<C-d>zz', opts)
vim.keymap.set('n', '<C-u>', '<C-u>zz', opts)

-- Find and center
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- Resize with arrows
vim.keymap.set('n', '<Up>', ':resize -2<CR>', opts)
vim.keymap.set('n', '<Down>', ':resize +2<CR>', opts)
vim.keymap.set('n', '<Left>', ':vertical resize -2<CR>', opts)
vim.keymap.set('n', '<Right>', ':vertical resize +2<CR>', opts)

-- Buffers
vim.keymap.set('n', '<Tab>', ':bnext<CR>', opts)
vim.keymap.set('n', '<S-Tab>', ':bprevious<CR>', opts)
vim.keymap.set('n', '<C-i>', '<C-i>', opts) -- to restore jump forward
vim.keymap.set('n', '<leader>x', ':Bdelete!<CR>', opts) -- close buffer
vim.keymap.set('n', '<leader>b', '<cmd> enew <CR>', opts) -- new buffer

-- Increment/decrement numbers
vim.keymap.set('n', '<leader>+', '<C-a>', opts) -- increment
vim.keymap.set('n', '<leader>-', '<C-x>', opts) -- decrement

-- Window management
vim.keymap.set('n', '<leader>v', '<C-w>v', opts) -- split window vertically
vim.keymap.set('n', '<leader>h', '<C-w>s', opts) -- split window horizontally
vim.keymap.set('n', '<leader>se', '<C-w>=', opts) -- make split windows equal width & height
vim.keymap.set('n', '<leader>xs', ':close<CR>', opts) -- close current split window

-- Navigate between splits
vim.keymap.set('n', '<C-k>', ':wincmd k<CR>', opts)
vim.keymap.set('n', '<C-j>', ':wincmd j<CR>', opts)
vim.keymap.set('n', '<C-h>', ':wincmd h<CR>', opts)
vim.keymap.set('n', '<C-l>', ':wincmd l<CR>', opts)

-- Buffers
vim.keymap.set('n', '<leader>qt', ':BufferLineCloseOthers<CR>', opts) -- close all buffers except current

-- Toggle line wrapping
vim.keymap.set('n', '<leader>lw', '<cmd>set wrap!<CR>', opts)

-- Line navigation (same motions as `0` and `$`)
vim.keymap.set({ 'n', 'v', 'o' }, '<leader>gh', '0', opts)
vim.keymap.set({ 'n', 'v', 'o' }, '<leader>gl', '$', opts)

-- Move text up and down
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', opts)
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', opts)
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", opts)
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", opts)

-- Keep last yanked when pasting
vim.keymap.set('v', 'p', '"_dP', opts)

-- Replace word under cursor
vim.keymap.set('n', '<leader>j', '*``cgn', opts)

-- Explicitly yank to system clipboard (highlighted and entire row)
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])
vim.keymap.set('n', '<leader>Y', [["+Y]])

-- Toggle diagnostics
local diagnostics_active = true

vim.keymap.set('n', '<leader>do', function()
  diagnostics_active = not diagnostics_active

  if diagnostics_active then
    vim.diagnostic.enable(true)
  else
    vim.diagnostic.enable(false)
  end
end)

-- Diagnostic keymaps
vim.keymap.set('n', '[d', function()
  vim.diagnostic.jump { count = -1, float = true }
end, { desc = 'Go to previous diagnostic message' })

vim.keymap.set('n', ']d', function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = 'Go to next diagnostic message' })

vim.keymap.set(
  'n',
  '<leader>d',
  vim.diagnostic.open_float,
  { desc = 'Open floating diagnostic message' }
)
vim.keymap.set(
  'n',
  '<leader>q',
  vim.diagnostic.setloclist,
  { desc = 'Open diagnostics list' }
)

-- Save and load session
vim.keymap.set(
  'n',
  '<leader>ss',
  ':mksession! .session.vim<CR>',
  { noremap = true, silent = false }
)
vim.keymap.set(
  'n',
  '<leader>sl',
  ':source .session.vim<CR>',
  { noremap = true, silent = false }
)
-- Sort
vim.keymap.set('v', '<leader>st', ':sort u<CR>', { noremap = true })
-- Toggle case
vim.keymap.set('v', '<leader>~', 'g~', { noremap = true })

-- Angular component file/section switching
-- For multi-file components: jump to the corresponding file
-- For inline components: jump to the template/styles/class section
local function angular_switch(section)
  local file = vim.fn.expand '%:p'
  local base = file:match '(.+)%.component%..+$'
  if not base then
    vim.notify('Not an Angular component file', vim.log.levels.WARN)
    return
  end

  local is_ts = file:match '%.component%.ts$'

  -- If we're in a .ts file, check for inline sections before switching files
  if is_ts and (section == 'template' or section == 'styles' or section == 'ts') then
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local pattern
    if section == 'template' then
      pattern = '^%s*template%s*:'
    elseif section == 'styles' then
      pattern = '^%s*styles%s*:'
    elseif section == 'ts' then
      pattern = '^export%s+class%s+'
    end

    for i, line in ipairs(lines) do
      if line:match(pattern) then
        vim.api.nvim_win_set_cursor(0, { i, 0 })
        vim.cmd 'normal! zz'
        return
      end
    end

    -- No inline section found, fall through to file switching
    if section == 'template' then
      vim.cmd('edit ' .. base .. '.component.html')
    elseif section == 'styles' then
      local scss = base .. '.component.scss'
      local target = vim.fn.filereadable(scss) == 1 and scss
        or base .. '.component.css'
      vim.cmd('edit ' .. target)
    end
    return
  end

  -- File switching for non-.ts files or spec
  local target
  if section == 'ts' then
    target = base .. '.component.ts'
  elseif section == 'template' then
    target = base .. '.component.html'
  elseif section == 'styles' then
    local scss = base .. '.component.scss'
    target = vim.fn.filereadable(scss) == 1 and scss
      or base .. '.component.css'
  elseif section == 'spec' then
    target = base .. '.component.spec.ts'
  end
  if target then
    vim.cmd('edit ' .. target)
  end
end

vim.keymap.set('n', '<leader>ot', function()
  angular_switch 'ts'
end, { desc = 'Angular: go to component class' })
vim.keymap.set('n', '<leader>oh', function()
  angular_switch 'template'
end, { desc = 'Angular: go to template' })
vim.keymap.set('n', '<leader>oc', function()
  angular_switch 'styles'
end, { desc = 'Angular: go to styles' })
vim.keymap.set('n', '<leader>os', function()
  angular_switch 'spec'
end, { desc = 'Angular: go to spec' })
