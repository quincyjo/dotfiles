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
            -- For some reason this makes it jump to nonexistent results.
            'n', 'N',
            '<C-o>', '<C-i>',
            '<C-d>', '<C-u>',
            'G', 'gg',
            '}', '{',
            ')', '(',
            '*', '#',
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

        for _, cmd in ipairs(centered_commands) do
            table.insert(keymaps, {
                cmd,
                function() require('cinnamon').scroll(cmd .. 'zz') end,
                mode = { 'n', 'v' }
            })
        end
        for _, cmd in ipairs(commands) do
            table.insert(keymaps, {
                cmd,
                function() require('cinnamon').scroll(cmd) end,
                mode = { 'n', 'v' }
            })
        end
        return keymaps
    end,
}

