return {
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		opts = {
			formatters_by_ft = {
				javascript = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				javascriptreact = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				json = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				jsonc = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				less = { "prettier" },
				lua = { "stylua" },
				markdown = { "prettier" },
				python = function(bufnr)
					if require("conform").get_formatter_info("ruff_format", bufnr).available then
						return { "ruff_format" }
					else
						return { "isort", "black" }
					end
				end,
				scala = { "scalafmt", lsp_format = "fallback" },
				scss = { "prettier" },
				typescript = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				typescriptreact = { "prettier", name = "dprint", timeout_ms = 500, lsp_format = "fallback" },
				yaml = { "prettier" },
				["_"] = { "trim_whitespace", "trim_newlines" },
			},
			format_on_save = function()
				return vim.g.autoformat and {
					lsp_format = "fallback",
					timeout_ms = 500,
				} or nil
			end,
			formatters = {
				-- Require a Prettier configuration file to format.
				prettier = { require_cwd = true },
			},
		},
		init = function()
			vim.api.nvim_create_user_command("ToggleFormat", function()
				vim.g.autoformat = not vim.g.autoformat
				vim.notify(
					string.format("%s autoformat", vim.g.autoformat and "Enabled" or "Disabled"),
					vim.log.levels.INFO
				)
			end, { desc = "Toggle conform.nvim auto-formatting", nargs = 0 })

			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
			vim.g.autoformat = true
		end,
	},
}
