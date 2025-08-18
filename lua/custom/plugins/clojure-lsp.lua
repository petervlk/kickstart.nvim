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

  -- Define custom clojure-lsp actions (not available through standard LSP)
  local custom_actions = {
    -- Basic refactoring actions (uri, row, col only)
    {
      title = '🔀 Move to let',
      command = 'move-to-let',
      prompt = 'Binding name',
      description = 'Extract expression to let binding',
    },
    {
      title = '🔧 Expand let',
      command = 'expand-let',
      description = 'Expand nested let bindings into a single let',
    },
    {
      title = '🧵 Thread first (->)',
      command = 'thread-first',
      description = 'Convert expression to thread-first macro',
    },
    {
      title = '🧵 Thread first all (->)',
      command = 'thread-first-all',
      description = 'Convert expression to thread-first macro',
    },
    {
      title = '🧵 Thread last (->>)',
      command = 'thread-last',
      description = 'Convert expression to thread-last macro',
    },
    {
      title = '🧵 Thread last all (->>)',
      command = 'thread-last-all',
      description = 'Convert expression to thread-last macro',
    },
    {
      title = '🔄 Unwind thread',
      command = 'unwind-thread',
      description = 'Convert threading macro back to nested calls',
    },
    {
      title = '🔄 Unwind all',
      command = 'unwind-all',
      description = 'Convert threading macro back to nested calls',
    },
    {
      title = '📦 Add missing libspec',
      command = 'add-missing-libspec',
      description = 'Add missing require for unresolved symbol',
    },
    {
      title = '🧹 Clean namespace',
      command = 'clean-ns',
      description = 'Remove unused requires and refers',
    },
    {
      title = '📤 Extract function',
      command = 'extract-function',
      prompt = 'Function name',
      description = 'Extract selected code into a new function',
    },
    {
      title = '🏷️ Inline symbol',
      command = 'inline-symbol',
      description = 'Inline symbol definition at usage sites',
    },
    {
      title = '🔄 Cycle privacy',
      command = 'cycle-privacy',
      description = 'Toggle between public/private function',
    },
    {
      title = '📋 Cycle collection type',
      command = 'cycle-coll',
      description = 'Cycle between vector/list/set/map',
    },
    {
      title = '🏗️ Create test',
      command = 'create-test',
      description = 'Create test for current function',
    },
  }

  -- Create the custom code actions menu
  local function show_custom_code_actions()
    vim.ui.select(custom_actions, {
      prompt = 'Clojure Custom Actions:',
      format_item = function(action)
        return action.title .. ' - ' .. action.description
      end,
    }, function(selected)
      if not selected then
        return
      end

      -- Execute the selected action
      local executor = exec_clojure_cmd(selected.command, selected.prompt)
      executor()
    end)
  end

  -- Keymap for custom code actions
  vim.keymap.set('n', '<localleader>ca', show_custom_code_actions, {
    desc = 'Clojure: Custom code actions',
    buffer = bufnr,
  })

  -- Set up clojure-lsp specific keymaps
  vim.keymap.set('n', '<localleader>cel', exec_clojure_cmd 'expand-let', {
    desc = 'Expand let',
    buffer = bufnr,
  })

  vim.keymap.set('n', '<localleader>cil', exec_clojure_cmd('introduce-let', 'New binding'), {
    desc = 'Introduce let',
    buffer = bufnr,
  })

  vim.keymap.set('n', '<localleader>cth', exec_clojure_cmd 'thread-first', {
    desc = 'Thread first',
    buffer = bufnr,
  })

  vim.keymap.set('n', '<localleader>ctl', exec_clojure_cmd 'thread-last', {
    desc = 'Thread last',
    buffer = bufnr,
  })

  vim.keymap.set('n', '<localleader>cuw', exec_clojure_cmd 'unwind-thread', {
    desc = 'Unwind thread',
    buffer = bufnr,
  })
end

return M
