local diagnostic_icons = require('icons').diagnostics
local misc_icons = require('icons').misc

vim.g.inlay_hints = false

local M = {}

local function floating_width()
    return math.floor(vim.o.columns * 0.4)
end

local function floating_height()
    return math.floor(vim.o.lines * 0.5)
end

--- Sets up LSP keymaps and autocommands for the given buffer.
---@param client vim.lsp.Client
---@param bufnr integer
local function on_attach(client, bufnr)
    ---@param lhs string
    ---@param rhs string|function
    ---@param opts string|vim.keymap.set.Opts
    ---@param mode? string|string[]
    local function keymap(lhs, rhs, opts, mode)
        mode = mode or 'n'
        ---@cast opts vim.keymap.set.Opts
        opts = type(opts) == 'string' and { desc = opts } or opts
        opts.buffer = bufnr
        vim.keymap.set(mode, lhs, rhs, opts)
    end

    -- diagnostics jumps
    keymap('[d', function()
        vim.diagnostic.jump { count = -1 }
        vim.cmd('normal zz')
    end, 'Previous diagnostic')
    keymap(']d', function()
        vim.diagnostic.jump { count = 1 }
        vim.cmd('normal zz')
    end, 'Next diagnostic')
    keymap('[e', function()
        vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR }
        vim.cmd('normal zz')
    end, 'Previous error')
    keymap(']e', function()
        vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.ERROR }
        vim.cmd('normal zz')
    end, 'Next error')

    -- Nvim native diagnostic list
    keymap("<leader>aa",
        vim.diagnostic.setqflist,
        'All workspace diagnostics')
    keymap("<leader>ae", function()
        vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR })
    end, 'All workspace errors')
    keymap("<leader>aw", function()
        vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.WARN })
    end, 'All workspace warnings')
    keymap("<leader>d",
        vim.diagnostic.setloclist,
        'Buffer diagnostics')

    if client:supports_method('textDocument/codeAction') then
        require('lightbulb').attach_lightbulb(bufnr, client)
    end

    -- Show diagnostics on cursor hold
    vim.api.nvim_create_autocmd({ "CursorHold" }, {
        pattern = "*",
        callback = function()
            vim.diagnostic.open_float({
                focusable = false,
                close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "InsertCharPre", "WinLeave" }
            })
        end
    })

    -- Don't check for the capability here to allow dynamic registration of the request.
    vim.lsp.document_color.enable(true, bufnr)
    if client:supports_method('textDocument/documentColor') then
        keymap('grc', function()
            vim.lsp.document_color.color_presentation()
        end, 'vim.lsp.document_color.color_presentation()', { 'n', 'x' })
    end

    if client:supports_method('textDocument/references') then
        keymap('grr', '<cmd>FzfLua lsp_references<cr>', 'vim.lsp.buf.references()')
    end

    if client:supports_method('textDocument/typeDefinition') then
        keymap('gy', '<cmd>FzfLua lsp_typedefs<cr>', 'Go to type definition')
    end

    if client:supports_method('textDocument/documentSymbol') then
        keymap('gs', '<cmd>FzfLua lsp_document_symbols<cr>', 'Document symbols')
    end

    if client:supports_method('workspace/symbol') then
        keymap('gws', '<cmd>FzfLua lsp_workplace_symbols<cr>', 'Workplace symbols')
    end

    if client:supports_method('textDocument/hover') then
        keymap('K', vim.lsp.buf.hover, 'Hover hint')
    end

    if client:supports_method('textDocument/rename') then
        keymap('<leader>rn', vim.lsp.buf.rename, 'Rename')
    end

    if client:supports_method('textDocument/definition') then
        keymap('gd', function()
            require('cinnamon').scroll(function()
                require('fzf-lua').lsp_definitions { jump1 = true }
            end)
        end, 'Go to definition')
        keymap('gD', function()
            require('fzf-lua').lsp_definitions { jump1 = false }
        end, 'Peek definition')
    end

    if client:supports_method('textDocument/signatureHelp') then
        keymap('<C-p>', function()
            -- Close the completion menu first (if open).
            if require('blink.cmp.completion.windows.menu').win:is_open() then
                require('blink.cmp').hide()
            end

            vim.lsp.buf.signature_help()
        end, 'Signature help', 'i')
    end

    if client:supports_method('textDocument/documentHighlight') then
        local under_cursor_highlights_group =
            vim.api.nvim_create_augroup('quincyjo/cursor_highlights', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'InsertLeave' }, {
            group = under_cursor_highlights_group,
            desc = 'Highlight references under the cursor',
            buffer = bufnr,
            callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave' }, {
            group = under_cursor_highlights_group,
            desc = 'Clear highlight references',
            buffer = bufnr,
            callback = vim.lsp.buf.clear_references,
        })
    end

    if client:supports_method('textDocument/formatting') then
        vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
    end

    -- TODO: Set this up as desired
    if client:supports_method('textDocument/inlayHint') then
        local inlay_hints_group = vim.api.nvim_create_augroup('quincyjo/toggle_inlay_hints', { clear = false })

        if vim.g.inlay_hints then
            -- Initial inlay hint display.
            -- Idk why but without the delay inlay hints aren't displayed at the very start.
            vim.defer_fn(function()
                local mode = vim.api.nvim_get_mode().mode
                vim.lsp.inlay_hint.enable(mode == 'n' or mode == 'v', { bufnr = bufnr })
            end, 500)
        end

        vim.api.nvim_create_autocmd('InsertEnter', {
            group = inlay_hints_group,
            desc = 'Disable inlay hints',
            buffer = bufnr,
            callback = function()
                if vim.g.inlay_hints then
                    vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
                end
            end,
        })

        vim.api.nvim_create_autocmd('InsertLeave', {
            group = inlay_hints_group,
            desc = 'Enable inlay hints',
            buffer = bufnr,
            callback = function()
                if vim.g.inlay_hints then
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                end
            end,
        })
    end

    -- Add "Fix all" command for linters.
    if client.name == 'eslint' or client.name == 'stylelint_lsp' then
        vim.keymap.set('n', '<leader>cl', function()
            if not client then
                return
            end

            client:request('workspace/executeCommand', {
                command = client.name == 'eslint' and 'eslint.applyAllFixes' or 'stylelint.applyAutoFixes',
                arguments = {
                    {
                        uri = vim.uri_from_bufnr(bufnr),
                        version = vim.lsp.util.buf_versions[bufnr],
                    },
                },
            }, nil, bufnr)
        end, {
            desc = string.format('Fix all %s errors', client.name == 'eslint' and 'ESLint' or 'Stylelint'),
            buffer = bufnr,
        })
    end
end

function M.setup()
    -- Define the diagnostic signs.
    for severity, icon in pairs(diagnostic_icons) do
        local hl = 'DiagnosticSign' .. severity:sub(1, 1) .. severity:sub(2):lower()
        vim.fn.sign_define(hl, { text = icon, texthl = hl })
    end

    --[[ Currently not used diagnostic jump display. Nice because it is sticky while editing.
    local virt_lines_ns = vim.api.nvim_create_namespace 'on_diagnostic_jump'
    --- @param diagnostic? vim.Diagnostic
    --- @param bufnr integer
    local function on_jump(diagnostic, bufnr)
        if not diagnostic then return end
        vim.diagnostic.show(
            virt_lines_ns,
            bufnr,
            { diagnostic },
            { virtual_lines = { current_line = true }, virtual_text = false }
        )
    end
    ]]

    -- Diagnostic configuration.
    vim.diagnostic.config {
        -- jump = { on_jump = on_jump },
        virtual_text = {
            source = false, --'if_many',
            spacing = 2,
            prefix = function(diagnostic, i, total)
                -- This will take the highlight group of the fist diagnostic.
                -- Highlighting each count appropriately would require fetching
                -- diagnostics each time to return from one of matching severity,
                -- and only do so on the first instance of each severity.
                -- Opting not to for performance.
                if total > 1 then
                    if i == 1 then
                        local prefix = {}
                        local all_diagnostics = vim.diagnostic.get(0, { lnum = diagnostic.lnum })
                        local severity_counts = {}
                        for _, d in pairs(all_diagnostics) do
                            severity_counts[d.severity] = (severity_counts[d.severity] or 0) + 1
                        end
                        for severity, count in pairs(severity_counts) do
                            table.insert(prefix, count .. diagnostic_icons[vim.diagnostic.severity[severity]])
                        end
                        return table.concat(prefix)
                    else
                        return ''
                    end
                end
                return diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]]
            end,
            format = function(diagnostic)
                -- Show code and source if available.
                if diagnostic.code then
                    if #diagnostic.message <= 30 then
                        return diagnostic.message
                    end
                    return string.format('[%s]', diagnostic.code)
                    -- Else show message truncated.
                else
                    -- Take the first line, reduce dot chains, and truncate length to a
                    -- reasonable length with ellipsis if needed.
                    local line_index = diagnostic.message:find('\n')
                    local first_line = line_index
                        and (diagnostic.message:sub(1, line_index - 1) .. misc_icons.ellipsis)
                        or diagnostic.message
                    local message = require('util').trim_dot_chains(first_line, 1):gsub('%s+', ' ')
                    local truncate_to = floating_width()
                    if #message < truncate_to then
                        return message
                    else
                        return string.sub(message, 0, truncate_to - 1) .. misc_icons.ellipsis
                    end
                end
            end,
        },
        float = {
            border = 'rounded',
            source = 'if_many',
            -- Show severity icons as prefixes.
            prefix = function(diag)
                local level = vim.diagnostic.severity[diag.severity]
                local prefix = string.format(' %s ', diagnostic_icons[level])
                return prefix, 'Diagnostic' .. level:gsub('^%l', string.upper)
            end,
            format = function(diagnostic)
                return diagnostic.message
            end,
        },
        -- Disable signs in the gutter.
        signs = false,
    }

    -- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first.
    local show_handler = vim.diagnostic.handlers.virtual_text.show
    assert(show_handler)
    local hide_handler = vim.diagnostic.handlers.virtual_text.hide
    vim.diagnostic.handlers.virtual_text = {
        show = function(ns, bufnr, diagnostics, opts)
            table.sort(diagnostics, function(diag1, diag2)
                return diag1.severity > diag2.severity
            end)
            return show_handler(ns, bufnr, diagnostics, opts)
        end,
        hide = hide_handler,
    }

    local hover = vim.lsp.buf.hover
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.lsp.buf.hover = function()
        return hover {
            max_height = floating_height(),
            max_width = floating_width(),
        }
    end

    local signature_help = vim.lsp.buf.signature_help
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.lsp.buf.signature_help = function()
        return signature_help {
            max_height = floating_height(),
            max_width = floating_width(),
        }
    end

    -- Update mappings when registering dynamic capabilities.
    local register_capability = vim.lsp.handlers['client/registerCapability']
    vim.lsp.handlers['client/registerCapability'] = function(err, res, ctx)
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if not client then
            return
        end

        on_attach(client, vim.api.nvim_get_current_buf())

        return register_capability(err, res, ctx)
    end

    vim.api.nvim_create_autocmd('LspAttach', {
        desc = 'Configure LSP keymaps',
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)

            -- I don't think this can happen but it's a wild world out there.
            if not client then
                return
            end

            on_attach(client, args.buf)
        end,
    })

    --[[ Set up LSP servers.
    -- This is the alternative loading custom lsp configuration from config.
    -- Instead, they are loaded via nvim-lspconfig and nvim-metals.
    vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
        once = true,
        callback = function()
            -- Extend neovim's client capabilities with the completion ones.
            vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities(nil, true) })

            local servers = vim.iter(vim.api.nvim_get_runtime_file('lsp/*.lua', true))
                :map(function(file)
                    return vim.fn.fnamemodify(file, ':t:r')
                end)
                :totable()
            vim.lsp.enable(servers)
        end,
    })
    ]]
end

return M
