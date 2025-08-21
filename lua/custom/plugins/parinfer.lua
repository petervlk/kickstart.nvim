return {
  'eraserhd/parinfer-rust',
  build = 'cargo build --release',
  init = function()
    vim.g.parinfer_rust_enabled = 1
    vim.g.parinfer_rust_mode = 'smart' -- Options: "indent", "paren", "smart"
    vim.g.parinfer_rust_dim_parens = 1 -- Dim parens in Smart mode

    -- Optional: Set filetypes where parinfer should be active
    vim.g.parinfer_rust_filetypes = { 'clojure', 'lisp', 'scheme', 'racket' }
  end,
}
