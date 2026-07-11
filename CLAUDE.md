# workspace.nvim — Development Instructions

## Project Overview
A multi-repo **workspace** IDE built as a Neovim distribution: fixed region shell,
multi-repo manifests with an active repo, named workspace snapshots, and an
all-Lua UI (tabline, tree, statusline, theme). Optional, headless **Claude Code
helpers** shell out to the `claude` CLI on demand. Built on kickstart.nvim
patterns, using vim.pack (Neovim 0.12 built-in) as the plugin manager. No
lazy.nvim dependency.

## Architecture
- `init.lua` — bootstrap: loads options → keymaps → plugins → claude modules
- `lua/workspace/options.lua` — vim.opt settings
- `lua/workspace/keymaps.lua` — base keymaps (no plugin dependencies)
- `lua/workspace/plugins/` — plugin setup (one file per category)
- `lua/workspace/repos.lua` / `workspace.lua` — multi-repo manifest + workspace save/load
- `lua/workspace/shell.lua` — the single center content window (region layout)
- `lua/workspace/claude/` — optional, **headless** AI helpers (no interactive sessions)
- `lua/custom/` — machine-local overrides (gitignored)

## Plugin Manager
Use `vim.pack.add { 'https://github.com/...' }` to add plugins.
Lock file: `nvim-pack-lock.json`. Update: `:lua vim.pack.update()`.

## Key Conventions
- AI-helper keymaps use `<leader>c` prefix
- Git keymaps use `<leader>g` prefix; workspace keymaps use `<leader>w` prefix
- Internal filetypes / highlight groups / namespaces keep the `cs_` / `CS` prefix
- No comments explaining WHAT code does, only WHY if non-obvious

## Claude Helpers
The interactive terminal-session layer was removed (running a full-screen TUI
inside a `:terminal` fought Neovim — no scrollback, mouse capture, chrome leaks).
What remains under `lua/workspace/claude/` is headless only:
- each module is self-contained and registers its own keymaps
- all work goes through `workspace.claude.runner` (`claude --print --output-format
  stream-json`) and `workspace.claude.util` (`util.run`, `util.stream_float`) —
  cancelable, with live tool activity and cost/turn reporting
- do **not** add terminal-session / bottom-bar UI back; keep AI strictly optional

## Testing Changes
Run with: `NVIM_APPNAME=workspace nvim` (uses ~/.config/workspace as config dir,
or symlink this repo there for development). Headless checks:
`bash scripts/check.sh` and `:checkhealth workspace`.
