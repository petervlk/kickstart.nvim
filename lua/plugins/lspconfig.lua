return {
  -- LSP Plugins
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by nvim-cmp
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Jump to the definition of the word under your cursor.
          --  This is where a variable was first declared, or where a function is defined, etc.
          --  To jump back, press <C-t>.
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          -- Find references for the word under your cursor.
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          map('K', vim.lsp.buf.hover, 'Doc symbol under cursor')

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- Change diagnostic symbols in the sign column (gutter)
      if vim.g.have_nerd_font then
        local signs = { ERROR = '', WARN = '', INFO = '', HINT = '' }
        local diagnostic_signs = {}
        for type, icon in pairs(signs) do
          diagnostic_signs[vim.diagnostic.severity[type]] = icon
        end
        vim.diagnostic.config { signs = { text = diagnostic_signs } }
      end

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local servers = {
        -- clangd = {},
        gopls = {},
        -- pyright = {},
        -- rust_analyzer = {},
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`ts_ls`) will work just fine
        -- ts_ls = {},
        --

        lua_ls = {
          -- cmd = { ... },
          -- filetypes = { ... },
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      -- Ensure the servers and tools above are installed
      --  To check the current status of installed tools and/or manually install
      --  other tools, you can run
      --    :Mason
      --
      --  You can press `g?` for help in this menu.
      require('mason').setup()

      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }

      require('lspconfig').clojure_lsp.setup {
        on_attach = function(client, bufnr)
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
        end,
      }
    end,
  },
}

-- vim: ts=2 sts=2 sw=2 et
