return {
  'catgoose/nvim-colorizer.lua',
  event = 'BufReadPre',
  opts = { lazy_load = true },
  config = function()
    require('colorizer').setup {
      user_default_options = {
        names = false,
        css = true,
      },
    }
  end,
}
