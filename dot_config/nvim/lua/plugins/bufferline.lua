local diagnostics = require('icons').diagnostics

return {
    {
        'akinsho/bufferline.nvim',
        version = "*",
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        opts = {
            options = {
                always_show_bufferline = false,
                mode = 'tabs',
                offsets = {
                    {
                        filetype = 'neo-tree',
                        text = 'Explorer',
                        text_align = 'center',
                        highlight = 'Directory',
                        separator = true,
                    },
                },
                diagnostics = "nvim_lsp",
                diagnostics_indicator = function(_, _, diagnostics_dict, _)
                    local s = " "
                    for e, n in pairs(diagnostics_dict) do
                        local sym = e == "error" and diagnostics.ERROR
                            or (e == "warning" and diagnostics.WARN or diagnostics.HINT)
                        s = s .. n .. sym
                    end
                    return s
                end,
            },
        },
    },

}
