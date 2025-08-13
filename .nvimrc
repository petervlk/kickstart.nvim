local nvim_lsp = require('lspconfig')

nvim_lsp.clojure_lsp.setup {
  root_dir = function()
    return vim.fn.getcwd()
  end
}
