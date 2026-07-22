return {
  'folke/flash.nvim',
  event = 'VeryLazy',
  opts = {},
  keys = {
    {
      '<Space>',
      mode = { 'n', 'x', 'o' },
      function()
        local statusline = require('config.statusline')
        statusline.set_flash(true)
        pcall(function()
          require('flash').jump()
        end)
        vim.defer_fn(function()
          statusline.set_flash(false)
        end, 350)
      end,
      desc = 'Flash Jump',
    },
    {
      'S',
      mode = { 'n', 'x', 'o' },
      function()
        local statusline = require('config.statusline')
        statusline.set_flash(true)
        pcall(function()
          require('flash').treesitter()
        end)
        vim.defer_fn(function()
          statusline.set_flash(false)
        end, 350)
      end,
      desc = 'Flash Treesitter',
    },
  },
}