-- Statusline component: claudecode.nvim connection status (a small ◉ when a
-- Claude Code client is connected over the local WebSocket).
local M = {}

function M.component()
  -- claudecode.nvim WebSocket connection indicator
  local ok_cc, cc = pcall(require, 'claudecode')
  if ok_cc and cc.is_claude_connected and cc.is_claude_connected() then
    return '◉'
  end
  return ''
end

return M
