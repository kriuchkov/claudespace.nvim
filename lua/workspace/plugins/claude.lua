-- claudecode.nvim: official Anthropic plugin — gives Claude Code awareness of
-- cursor position, visual selection, LSP diagnostics, and open files via a
-- local WebSocket server.
vim.pack.add { 'https://github.com/coder/claudecode.nvim' }
if pcall(require, 'claudecode') then
  require('claudecode').setup {
    log_level    = 'warn',
    track_selection = true,
    focus_after_send = false,
    terminal = { provider = 'native' },
    diff_opts = {
      layout              = 'vertical',
      open_in_new_tab     = false,
      auto_resize_terminal = true,
    },
  }

  local map = vim.keymap.set
  -- @mention / tree-add are reachable from the <leader>cA context picker;
  -- keep a visual-mode @mention for sending a selection.
  map('v', '<leader>cA', '<cmd>ClaudeCodeSend<cr>',
    { desc = 'Claude: send selection as @mention', silent = true })
  -- Accept / reject inline diff proposed by Claude Code
  map('n', '<leader>cy', '<cmd>ClaudeCodeDiffAccept<cr>',
    { desc = 'Claude: accept diff',                silent = true })
  map('n', '<leader>cY', '<cmd>ClaudeCodeDiffDeny<cr>',
    { desc = 'Claude: reject diff',                silent = true })
end
