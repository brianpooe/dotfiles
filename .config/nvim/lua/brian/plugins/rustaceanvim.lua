return {
  'mrcjkb/rustaceanvim',
  version = '^7',
  lazy = false,
  config = function()
    vim.g.rustaceanvim = {
      tools = {
        float_win_config = {
          border = 'rounded',
        },
      },
    }
  end,
}
