return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  keys = {
    {
      '<leader>mk',
      '<cmd>RenderMarkdown toggle<CR>',
      desc = 'Toggle markdown render/raw',
      ft = 'markdown',
    },
  },
  opts = {
    -- Always keep markdown rendered in all modes.
    render_modes = true,
    -- Do not reveal raw syntax under cursor while moving/editing.
    anti_conceal = {
      enabled = false,
    },
  },
}
