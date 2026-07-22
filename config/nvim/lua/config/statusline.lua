local M = {}

local mode_map = {
  n = { label = 'NORMAL', hl = 'NvimModeNormal' },
  i = { label = 'INSERT', hl = 'NvimModeInsert' },
  R = { label = 'REPLACE', hl = 'NvimModeReplace' },
  v = { label = 'VISUAL', hl = 'NvimModeVisual' },
  V = { label = 'VISUAL-L', hl = 'NvimModeVisual' },
  ['\22'] = { label = 'VISUAL-B', hl = 'NvimModeVisual' },
  c = { label = 'COMMAND', hl = 'NvimModeCommand' },
  t = { label = 'TERMINAL', hl = 'NvimModeCommand' },
}

function M.set_flash(active)
  vim.g.flash_active = active and true or false
  vim.cmd('redrawstatus')
end

local function set_highlights()
  local ok, palette_mod = pcall(require, 'catppuccin.palettes')
  if not ok then
    return
  end

  local palette = palette_mod.get_palette('macchiato')
  local set_hl = vim.api.nvim_set_hl

  set_hl(0, 'NvimModeNormal', { fg = palette.base, bg = palette.blue, bold = true })
  set_hl(0, 'NvimModeInsert', { fg = palette.base, bg = palette.green, bold = true })
  set_hl(0, 'NvimModeReplace', { fg = palette.base, bg = palette.red, bold = true })
  set_hl(0, 'NvimModeVisual', { fg = palette.base, bg = palette.mauve, bold = true })
  set_hl(0, 'NvimModeCommand', { fg = palette.base, bg = palette.yellow, bold = true })
  set_hl(0, 'NvimModeFlash', { fg = palette.base, bg = palette.peach, bold = true })
end

function _G.MinimalModeLabel()
  if vim.g.flash_active then
    return '%#NvimModeFlash# FLASH %*'
  end

  local mode = vim.api.nvim_get_mode().mode
  local resolved = mode_map[mode] or mode_map[mode:sub(1, 1)] or { label = mode, hl = 'NvimModeNormal' }
  return ('%%#%s# %s %%*'):format(resolved.hl, resolved.label)
end

function M.setup()
  set_highlights()

  vim.api.nvim_create_autocmd('ColorScheme', {
    callback = set_highlights,
  })

  vim.opt.statusline = '%{%v:lua.MinimalModeLabel()%} %f %= %l:%c '
end

return M