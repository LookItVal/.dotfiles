# Minimal Neovim Config

This Neovim config is intentionally minimal and shared across:
- Terminal Neovim
- VS Code (asvetliakov.vscode-neovim)
- Cursor (asvetliakov.vscode-neovim)

## Included
- Base options and keymaps
- folke/flash.nvim motion plugin

## Structure
- init.lua
- lua/config/options.lua
- lua/config/keymaps.lua
- lua/plugins/flash.lua

## Notes
- `vim.g.vscode` is used to conditionally load VS Code and Cursor specific mappings.
- Terminal-only plugins can be added in `init.lua` under `terminal_only_plugins`.
