-- Workspace-level Claude features for multi-repo development:
--   #3 cross-repo context picker  — add files from any repo to the session
--   #5 broadcast prompt           — run one task across many repos (fleet)
--   #7 workspace-wide commit      — AI commit message per dirty repo
local M = {}

local api, fn = vim.api, vim.fn

local function repos()    return require('claudespace.repos') end
local function context()  return require('claudespace.claude.context') end
local function sessions() return require('claudespace.claude.sessions') end

-- ── #3 Cross-repo context picker ──────────────────────────────────────────────

function M.add_files()
  local members = repos().list()
  if #members == 0 then
    vim.notify('No repos in workspace', vim.log.levels.WARN); return
  end
  local ok, tb = pcall(require, 'telescope.builtin')
  if not ok then
    vim.notify('telescope required for the cross-repo picker', vim.log.levels.WARN); return
  end
  local actions      = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  local dirs = {}
  for _, m in ipairs(members) do dirs[#dirs + 1] = m.abspath end

  local function send(paths)
    if #paths == 0 then return end
    if not sessions().active() then
      vim.notify('Open a Claude session first (<leader>cc)', vim.log.levels.WARN); return
    end
    -- Cross-repo files live outside the session's cwd, so reference them by
    -- absolute path; Claude attaches each @mention.
    local text = '@' .. table.concat(paths, ' @') .. '\n'
    if context().send_to_active(text) then
      vim.notify(('Added %d file(s) to Claude context'):format(#paths), vim.log.levels.INFO)
    end
  end

  tb.find_files {
    prompt_title = 'Add to Claude context (Tab to mark, ⏎ to add)',
    search_dirs  = dirs,
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local multi  = picker:get_multi_selection()
        local paths  = {}
        if #multi > 0 then
          for _, e in ipairs(multi) do paths[#paths + 1] = e.path or e.value or e[1] end
        else
          local e = action_state.get_selected_entry()
          if e then paths[1] = e.path or e.value or e[1] end
        end
        actions.close(prompt_bufnr)
        send(paths)
      end)
      return true
    end,
  }
end

-- ── #5 Broadcast prompt (fleet) ───────────────────────────────────────────────

-- Multi-select repos (Tab to mark); falls back to all when telescope is absent.
local function pick_repos(cb)
  local list = repos().list()
  if not pcall(require, 'telescope') then cb(list); return end
  local pickers      = require('telescope.pickers')
  local finders      = require('telescope.finders')
  local conf         = require('telescope.config').values
  local actions      = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  pickers.new({}, {
    prompt_title = 'Broadcast to which repos? (Tab to mark, ⏎ to run)',
    finder = finders.new_table {
      results     = list,
      entry_maker = function(m) return { value = m, display = m.path, ordinal = m.path } end,
    },
    sorter = conf.generic_sorter {},
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local picker  = action_state.get_current_picker(prompt_bufnr)
        local multi   = picker:get_multi_selection()
        local targets = {}
        if #multi > 0 then
          for _, e in ipairs(multi) do targets[#targets + 1] = e.value end
        else
          local e = action_state.get_selected_entry()
          if e then targets[1] = e.value end
        end
        actions.close(prompt_bufnr)
        cb(targets)
      end)
      return true
    end,
  }):find()
end

local function show_broadcast(task, targets, results)
  local lines = { '# Broadcast results', '', '**Task:** ' .. task, '' }
  for _, m in ipairs(targets) do
    lines[#lines + 1] = '## ' .. m.path
    for _, l in ipairs(vim.split(results[m.path] or '(no output)', '\n')) do
      lines[#lines + 1] = l
    end
    lines[#lines + 1] = ''
  end
  vim.cmd 'botright vsplit'
  local buf = api.nvim_create_buf(false, true)
  api.nvim_win_set_buf(0, buf)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype   = 'markdown'
  vim.bo[buf].buftype    = 'nofile'
  vim.bo[buf].bufhidden  = 'wipe'
  vim.bo[buf].modifiable = false
  vim.keymap.set('n', 'q', '<cmd>bd<CR>', { buffer = buf, silent = true })
end

function M.broadcast()
  if #repos().list() == 0 then
    vim.notify('No repos in workspace', vim.log.levels.WARN); return
  end
  vim.ui.input({ prompt = 'Broadcast task: ' }, function(task)
    if not task or task == '' then return end
    pick_repos(function(targets)
      if #targets == 0 then return end
      vim.notify(('Broadcasting to %d repo(s)…'):format(#targets), vim.log.levels.INFO)
      local results, done = {}, 0
      for _, m in ipairs(targets) do
        vim.system({ 'claude', '--print', task }, { cwd = m.abspath, text = true },
          vim.schedule_wrap(function(res)
            results[m.path] = (res.code == 0 and vim.trim(res.stdout or ''))
              or ('ERROR: ' .. vim.trim((res.stderr or '') ~= '' and res.stderr or tostring(res.code)))
            done = done + 1
            if done == #targets then show_broadcast(task, targets, results) end
          end))
      end
    end)
  end)
end

-- ── #7 Workspace-wide commit ──────────────────────────────────────────────────

local function commit_next(dirty, i)
  if i > #dirty then vim.notify('Workspace commit complete', vim.log.levels.INFO); return end
  local m = dirty[i]
  fn.system({ 'git', '-C', m.abspath, 'add', '-A' })
  local diff = fn.system({ 'git', '-C', m.abspath, 'diff', '--staged' })

  local function ask(prefill)
    vim.ui.input(
      { prompt = ('[%d/%d] %s — message (empty skips): '):format(i, #dirty, m.label),
        default = prefill or '' },
      function(msg)
        if msg and msg ~= '' then
          local out = fn.system({ 'git', '-C', m.abspath, 'commit', '-m', msg })
          vim.notify(m.label .. ': ' .. vim.trim(out), vim.log.levels.INFO)
          repos().refresh_status(m)
        else
          vim.notify(m.label .. ': skipped (left staged)', vim.log.levels.INFO)
        end
        commit_next(dirty, i + 1)
      end)
  end

  if fn.executable('claude') == 0 or vim.trim(diff) == '' then ask(); return end
  vim.system(
    { 'claude', '--print',
      'Generate a concise conventional-commits message for this staged diff. '
      .. 'Imperative mood, ≤72 chars, no quotes or fences — output ONLY the message.\n\n' .. diff },
    { cwd = m.abspath, text = true },
    vim.schedule_wrap(function(res)
      ask(res.code == 0 and vim.trim(res.stdout or '') or nil)
    end))
end

function M.commit_all()
  local dirty = {}
  for _, m in ipairs(repos().list()) do
    local out = fn.systemlist({ 'git', '-C', m.abspath, 'status', '--porcelain' })
    if vim.v.shell_error == 0 and #out > 0 then dirty[#dirty + 1] = m end
  end
  if #dirty == 0 then
    vim.notify('Workspace clean — nothing to commit', vim.log.levels.INFO); return
  end
  vim.notify(('%d repo(s) with changes — generating messages…'):format(#dirty), vim.log.levels.INFO)
  commit_next(dirty, 1)
end

-- ── Setup ─────────────────────────────────────────────────────────────────────

function M.setup()
  local map = vim.keymap.set
  map('n', '<leader>cF', M.add_files,  { silent = true, desc = 'Claude: add cross-repo files to context' })
  map('n', '<leader>cB', M.broadcast,  { silent = true, desc = 'Claude: broadcast prompt to repos' })
  map('n', '<leader>cC', M.commit_all, { silent = true, desc = 'Claude: workspace-wide commit' })

  api.nvim_create_user_command('ClaudeBroadcast', M.broadcast, { desc = 'Broadcast a Claude task across repos' })
  api.nvim_create_user_command('ClaudeCommitAll', M.commit_all, { desc = 'Workspace-wide AI commit' })
end

return M
