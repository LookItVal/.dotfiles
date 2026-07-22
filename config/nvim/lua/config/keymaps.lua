vim.keymap.set('i', 'jk', '<Esc>', { desc = 'Exit insert mode' })

if vim.g.vscode then
  local ok, vscode = pcall(require, 'vscode')
  if ok then
    vim.keymap.set('n', '<leader>ff', function()
      vscode.action('workbench.action.quickOpen')
    end, { silent = true, desc = 'Quick Open' })
  end
end