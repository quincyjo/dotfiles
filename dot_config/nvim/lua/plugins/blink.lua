return {
	{
		"saghen/blink.cmp",
		-- optional: provides snippets for the snippet source
		-- dependencies = { 'rafamadriz/friendly-snippets' },
		dependencies = {
			"Exafunction/windsurf.nvim",
			"LuaSnip",
			"ribru17/blink-cmp-spell",
		},
		build = "cargo +nightly build --release",
		event = "InsertEnter",
		version = "1.*",
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = {
				["<CR>"] = { "accept", "fallback" },
				["<C-\\>"] = { "hide", "fallback" },
				["<C-n>"] = { "select_next", "show" },
				["<C-p>"] = { "select_prev" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
			},
			appearance = {
				kind_icons = require("icons").symbol_kinds,
				nerd_font_variant = "mono",
			},
			completion = {
				documentation = { auto_show = true },
				menu = {
					scrollbar = false,
					draw = {
						gap = 2,
						columns = {
							{ "kind_icon", "kind", gap = 1 },
							{ "label", "label_description", gap = 1 },
						},
					},
				},
			},
			snippets = { preset = "luasnip" },
			sources = {
				default = {
					"lsp",
					"path",
					"snippets",
					"buffer",
					--"codeium",
					"lazydev",
					"spell",
				},
				providers = {
					codeium = { name = "Codeium", module = "codeium.blink", async = true },
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
						score_offset = 100,
					},
					spell = {
						name = "Spell",
						module = "blink-cmp-spell",
						opts = {
							-- Only enable source in @spell captures, and disable it in @nospell captures.
							enable_in_context = function()
								local curpos = vim.api.nvim_win_get_cursor(0)
								local captures = vim.treesitter.get_captures_at_pos(0, curpos[1] - 1, curpos[2] - 1)
								local in_spell_capture = false
								for _, cap in ipairs(captures) do
									if cap.capture == "spell" then
										in_spell_capture = true
									elseif cap.capture == "nospell" then
										return false
									end
								end
								return in_spell_capture
							end,
						},
					},
				},
				per_filetype = {
					oil = { "path", "buffer" },
					codecompanion = { "codecompanion" },
				},
			},
			-- See :h blink-cmp-config-fuzzy for more information
			fuzzy = {
				implementation = "prefer_rust_with_warning",
				sorts = {
					function(a, b)
						local sort = require("blink.cmp.fuzzy.sort")
						if a.source_id == "spell" and b.source_id == "spell" then
							return sort.label(a, b)
						end
					end,
					-- This is the normal default order, which we fall back to
					"score",
					"kind",
					"label",
				},
			},
			signature = { enabled = true },
		},
	},
}
