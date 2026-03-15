return {
    'declancm/cinnamon.nvim',
    version = '*',
    ---@module 'cinnamon'
    ---@type CinnamonOptions
    opts = {
        keymaps = {
            basic = false,
            extra = false,
        },
        options = {
            mode = 'cursor',
            delay = 3,
            max_delta = {
                time = 100,
            },
            step_size = {
                vertical = 1,
            },
        },
    },
    keys = function()
        local keymaps = {}
        local centered_commands = {
            -- For some reason this makes it jump to nonexistent results in
            -- certain non-normal buffer types, EG help.
            'n', 'N',
            '<C-o>', '<C-i>',
            '<C-d>', '<C-u>',
            'G', 'gg',
            '}', '{',
            ')', '(',
            '*', '#',
            ']s', '[s',
        }
        local commands = {
            'zt', 'zb', 'zz',
            'z.', 'z<CR>', 'z-', 'z^', 'z+',
            'zH', 'zL', 'zs', 'ze', 'zh', 'zl',
            'j', 'k', 'h', 'l',
            '<C-e>', '<C-y>',
            '<C-f>', '<C-b>',
            '0', '^', '$',
            'w', 'W', 'b', 'B',
        }

        local function smart_scroll(cmd)
            return function()
                local ft = vim.bo.filetype
                if vim.tbl_contains({ "oil", "markdown", "codecompanion" }, ft) then
                    -- In oil or markview buffers, those plugins interrupt Cinnamon and motions don't complete.
                    local count = vim.v.count > 0 and vim.v.count or ""
                    local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
                    -- Alternative to use cinnamon via lua code execution.
                    -- Works on oil buffers, but not md with markview.
                    --[[
                    local foo = string.format(":lua require'cinnamon'.scroll'%s%s'", count, cmd)
                    local bar = foo .. vim.api.nvim_replace_termcodes('<cr>', true, false, true)
                    vim.api.nvim_feedkeys(bar, 'nv', false)
                    ]]
                    vim.api.nvim_feedkeys(count .. keys, 'nv', false)
                else
                    -- In regular buffers, use Cinnamon
                    require('cinnamon').scroll(cmd)
                end
            end
        end

        for _, cmd in ipairs(centered_commands) do
            table.insert(keymaps, {
                cmd,
                smart_scroll(cmd .. 'zz'),
                mode = { 'n', 'v' }
            })
        end
        for _, cmd in ipairs(commands) do
            table.insert(keymaps, {
                cmd,
                smart_scroll(cmd),
                mode = { 'n', 'v' }
            })
        end
        return keymaps
    end,
}
