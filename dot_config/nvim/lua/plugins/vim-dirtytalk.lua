return {
	{
		"psliwka/vim-dirtytalk",
		build = ":DirtytalkUpdate",
		config = function()
			vim.opt.spelllang:append("programming")
		end,
	},
}
