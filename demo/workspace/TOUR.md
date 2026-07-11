# 🛰️ orbit — a multi-repo workspace

Several git repos under one workspace (see
[`.workspace/workspace.json`](.workspace/workspace.json)), grouped like a
real monorepo. Toggle this preview with `<leader>mp`; follow links with `<CR>`.

> [!NOTE]
> The file tree shows each repo as its own root with its own git status. One
> repo is **active** at a time — Git, find, tasks and Claude all target it; the
> highlight follows the file you're in.

## Repos

| Group | Repo | Lang | Role |
|-------|------|------|------|
| services | [`vega`](services/vega/main.go) | Go | HTTP greeting service (pinned, active) |
| services | [`lyra`](services/lyra/lyra.go) | Go | averages scores |
| services | [`nova`](services/nova/src/main.rs) | Rust | formats notifications |
| packages | [`nebula`](packages/nebula/nebula.go) | Go | shared lib the Go services depend on |
| frontends | [`aurora`](frontends/aurora/src/main.rs) | Rust | renders the greeting |
| — | [`deploy`](deploy/docker-compose.yml) | yaml | wires it all together |

## Workspace — the set of repos

- [ ] `<leader>wp` — repos overview (branches, dirty state)
- [ ] `<leader>ws` / `<leader>wl` — switch / list workspaces
- [ ] `<leader>fR` — live grep scoped to the active repo
- [ ] `F` in the source-control panel — fast-forward-pull every repo at once

## Per repo

- [ ] `\` — file tree; jump between repo roots, watch the git status column
- [ ] `<leader>ru` — run the active repo's tests
- [ ] `gd` on `Greeter` — LSP across the Go modules (`go.work`)
- [ ] `<leader>cC` — run a `.claude/commands/*.md` in the background
- [ ] `<leader>gc` — a commit message for the active repo's staged diff

<details>
<summary>Why a workspace?</summary>

Real work spans services, shared packages, a frontend and deploy config.
workspace makes the *set* of repos the unit you operate on — switch the active
one, or fan a task out to all of them — without leaving the editor.

</details>

Repo: [github.com/kriuchkov/workspace.nvim](https://github.com/kriuchkov/workspace.nvim)
