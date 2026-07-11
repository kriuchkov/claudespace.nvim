require 'workspace.claude.git_ops'
require 'workspace.claude.codegen'
require 'workspace.claude.fix'
require 'workspace.claude.assist'
require('workspace.claude.runner').setup()

-- Custom-command runner (.claude/commands/*.md, run headless via the runner)
vim.keymap.set('n', '<leader>cC', function()
  require('workspace.claude.commands').pick()
end, { desc = 'Claude: run a command (.claude/commands)' })

-- CLAUDE.md management
vim.keymap.set('n', '<leader>cm', function()
  local repos = require('workspace.repos')
  local project_md = repos.active_cwd() .. '/CLAUDE.md'
  -- In a multi-repo workspace, also offer the root CLAUDE.md as a fallback.
  local root_md   = repos.is_multi() and (repos.root() .. '/CLAUDE.md') or nil
  local global_md = vim.fn.expand '~/.claude/CLAUDE.md'
  if vim.fn.filereadable(project_md) == 1 then
    vim.cmd('edit ' .. project_md)
  elseif root_md and vim.fn.filereadable(root_md) == 1 then
    vim.cmd('edit ' .. root_md)
  elseif vim.fn.filereadable(global_md) == 1 then
    vim.cmd('edit ' .. global_md)
  else
    vim.cmd('edit ' .. project_md)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      '# Project Instructions for Claude',
      '',
      '## Project Overview',
      '',
      '## Code Style',
      '',
      '## Key Conventions',
      '',
    })
  end
end, { desc = 'Claude: open CLAUDE.md' })
