-- Command aliases for common shift-key typos
local typos = {
  ['W'] = 'w',
  ['Wq'] = 'wq',
  ['WQ'] = 'wq',
  ['Wqa'] = 'wqa',
  ['WQa'] = 'wqa',
  ['WQA'] = 'wqa',
  ['Wa'] = 'wa',
  ['WA'] = 'wa',
  ['Q'] = 'q',
  ['Qa'] = 'qa',
  ['QA'] = 'qa',
}

for typo, cmd in pairs(typos) do
  vim.api.nvim_create_user_command(typo, cmd, { bang = true })
end

-- Activate Angular treesitter parser for component HTML templates
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  desc = 'Set htmlangular filetype for Angular component templates',
  pattern = { '*.component.html', '*.container.html' },
  callback = function()
    vim.bo.filetype = 'htmlangular'
    vim.treesitter.start(nil, 'angular')
  end,
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup(
    'kickstart-highlight-yank',
    { clear = true }
  ),
  callback = function()
    vim.hl.on_yank()
  end,
})
