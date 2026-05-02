local diagnostics = require("icons").diagnostics

return {
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				always_show_bufferline = false,
				mode = "tabs",
				offsets = {
					{
						filetype = "neo-tree",
						text = "Explorer",
						text_align = "center",
						highlight = "Directory",
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
		config = function(_, opts)
			require("bufferline").setup(opts)

			-- Set all active highlights groups bg the same as BufferLineBufferSelected
			local ok, all_groups = pcall(vim.api.nvim_get_hl, 0, {})
			local base_hl = vim.api.nvim_get_hl(0, { name = "BufferLineBufferSelected" })
			if ok then
				for group_name, hl in pairs(all_groups) do
					if group_name:match("^BufferLine.*Selected") then
						hl.bg = base_hl.bg
						hl.default = nil
						vim.api.nvim_set_hl(0, group_name, hl)
					end
				end
			end
		end,
	},
}
