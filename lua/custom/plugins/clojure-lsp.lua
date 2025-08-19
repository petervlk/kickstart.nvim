local M = {}

function M.clojure_lsp_on_attach(client, bufnr)
  if client.name ~= 'clojure_lsp' then
    vim.notify('clojure_lsp not active', vim.log.levels.ERROR)
    return
  end

  -- Helper function to execute clojure-lsp commands
  local function exec_clojure_cmd(command, prompt)
    return function()
      local pos = vim.api.nvim_win_get_cursor(0)
      local row = pos[1] - 1 -- Convert to 0-based
      local col = pos[2]
      local uri = vim.uri_from_bufnr(0)

      local args = { uri, row, col }

      -- If prompt is provided, ask user for input and add to arguments
      if prompt then
        local input = vim.fn.input(prompt .. ': ')
        if input == '' then
          return -- Cancel if no input provided
        end
        table.insert(args, input)
      end

      client:exec_cmd {
        command = command,
        arguments = args,
      }
    end
  end

  -- Set up clojure-lsp specific keymaps
  vim.keymap.set('n', '<localleader>lel', exec_clojure_cmd 'expand-let', {
    desc = 'Expand let',
    buffer = bufnr,
  })

  vim.keymap.set('n', '<localleader>lil', exec_clojure_cmd('introduce-let', 'New binding'), {
    desc = 'Introduce let',
    buffer = bufnr,
  })

  vim.keymap.set('n', '<localleader>lml', exec_clojure_cmd('move-to-let', 'New binding'), {
    desc = 'Introduce let',
    buffer = bufnr,
  })
end

return M
