local function resolve_kanagawa_variant()
  local value = (vim.env.NVIM_THEME or ''):lower()
  local variants = {
    wave = 'wave',
    dragon = 'dragon',
    lotus = 'lotus',
    ['kanagawa-wave'] = 'wave',
    ['kanagawa-dragon'] = 'dragon',
    ['kanagawa-lotus'] = 'lotus',
  }
  return variants[value] or 'dragon'
end

local variant = resolve_kanagawa_variant()

return {
  'rebelot/kanagawa.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    compile = false,
    undercurl = true,
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = true },
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = true,
    dimInactive = false,
    terminalColors = true,
    colors = {
      palette = {},
      theme = {
        wave = {},
        lotus = {},
        dragon = {},
        all = {
          ui = {
            bg_gutter = 'none',
          },
        },
      },
    },
    overrides = function(colors)
      local theme = colors.theme
      return {
        NormalFloat = { bg = 'none' },
        FloatBorder = { bg = 'none' },
        FloatTitle = { bg = 'none' },
        NormalDark = { fg = theme.ui.fg_dim, bg = 'none' },
        LazyNormal = { bg = 'none', fg = theme.ui.fg_dim },
        MasonNormal = { bg = 'none', fg = theme.ui.fg_dim },
      }
    end,
    theme = variant,
    background = {
      dark = variant,
      light = 'lotus',
    },
  },
  config = function(_, opts)
    require('kanagawa').setup(opts)
    vim.cmd 'colorscheme kanagawa'
  end,
}
