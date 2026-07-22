local uv = vim.uv or vim.loop

require('config.options')
require('config.keymaps')
require('config.statusline').setup()

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not uv.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  require('plugins.catppuccin'),
  require('plugins.flash'),
}

if not vim.g.vscode then
  local terminal_only_plugins = {
    -- Add terminal-only plugins here.
  }
  vim.list_extend(plugins, terminal_only_plugins)
end

require('lazy').setup(plugins)
