local map = vim.keymap.set

-- Rust
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ['rust-analyzer'] = {
        cargo = { allFeatures = true },
        -- rust-analyzer schema: checkOnSave is a boolean toggle; the command
        -- (clippy vs check) moved to `check.command`. The old nested-map form
        -- (`checkOnSave = { command = … }`) now errors "expected a boolean".
        checkOnSave = true,
        check = { command = 'clippy' },
      },
    },
  },
}
vim.pack.add {
  'https://github.com/mrcjkb/rustaceanvim',
  'https://github.com/saecki/crates.nvim',
}
if pcall(require, 'crates') then
  require('crates').setup { completion = { crates = { enabled = true } } }
end

