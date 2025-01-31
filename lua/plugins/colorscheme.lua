return {
  'ellisonleao/gruvbox.nvim',
  priority = 1000, -- Make sure to load this before all the other start plugins.
  config = true,
  init = function()
    vim.cmd.colorscheme 'gruvbox'
  end,
  opts = {},
}
