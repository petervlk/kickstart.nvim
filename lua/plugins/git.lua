return {
  -- TODO: remove in favor of Neogit?
  {
    'tpope/vim-fugitive', -- git integration plugin
    -- keys = {
    --   {
    --     '<leader>gs',
    --     '<cmd>0G<cr>',
    --     mode = { 'n' },
    --     desc = '[S]tatus',
    --   },
    -- },
    event = 'VeryLazy',
  },

  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim', -- required
      'sindrets/diffview.nvim', -- optional - Diff integration
      'nvim-telescope/telescope.nvim', -- optional
    },
    config = true,
    keys = {
      {
        '<leader>gg',
        '<cmd>Neogit<cr>',
        mode = { 'n' },
        desc = 'Status',
      },
    },
  },

  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
}
