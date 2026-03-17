return {
	"nvim-zh/colorful-winsep.nvim",
	event = { "WinLeave" },
	opts = {
		---@type "single"|"rounded"|"bold"|"double"
		border = "rounded",
		animate = {
			---@type "shift"|"progressive"|false
			enabled = false,
		},
	},
}
