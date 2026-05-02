return {
	enabled = false,
	"github/copilot.vim",
	config = function()
		vim.g.copilot_filetypes = {
			oil = false,
		}
		-- Diable inline compoletions.
		vim.cmd("Copilot disable")
	end,
}
