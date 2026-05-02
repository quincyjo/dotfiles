---@diagnostic disable: unused-local, unused-function
local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local markup = require("lain.util.markup")
local pager = require("frames.pager")

require("continuity.tools.find")

---@alias Date string Date string in the format YYYY-mm-dd.
---@alias Time string Time string in the format HH:MM:SS
---@alias Level "E"|"W"

---@class Log
---@field message string
---@field date Date
---@field time Time
---@field level Level

---@class State
---@field logs Log[]
---@field errors Log[]
---@field warnings Log[]

---@enum HealthStatus
local HealthStatus = {
	OK = "ok",
	WARNING = "warning",
	ERROR = "error",
}

---@class HealthItem
---@field status?  HealthStatus
---@field details? string

---@class HealthSection
---@field label    string
---@field items    HealthItem[]

---@class ModuleHealth
---@field name     string
---@field sections HealthSection[]

---@class PopupHandle
---@field show_overview fun(self)
---@field show_logs     fun(self)
---@field show_errors   fun(self)
---@field show_warnings fun(self)
---@field close         fun(self)

---@class Action
---@field label string|fun(state: State): string
---@field key   string
---@field func  fun(handle: PopupHandle)
---@field cb?   fun(state: State, widget: AwesomeWidget)

local checkhealth = {}

checkhealth.status = HealthStatus

local startup = os.time()
local startup_date = os.date("%Y-%m-%d %H:%M:%S")

---@type AwesomePopup|nil
local popup

local keygrabber

local function quit()
	if popup and popup.visible then
		popup.visible = false
		popup = nil
	end
	if keygrabber then
		keygrabber:stop()
		keygrabber = nil
	end
end

---@type Action[]
local popup_actions = {
	{
		label = "Overview",
		key = "o",
		func = function(handle)
			handle:show_overview()
		end,
	},
	{
		label = function(state)
			return string.format("Logs %s", markup.italic("(" .. #state.logs .. ")"))
		end,
		key = "l",
		func = function(handle)
			handle:show_logs()
		end,
	},
	{
		label = function(state)
			return string.format("Errors %s", markup.italic("(" .. #state.errors .. ")"))
		end,
		key = "e",
		func = function(handle)
			handle:show_errors()
		end,
		cb = function(state, widget)
			if #state.errors > 0 then
				widget.bg = "#990000"
			end
		end,
	},
	{
		label = function(state)
			return string.format("Warnings %s", markup.italic("(" .. #state.warnings .. ")"))
		end,
		key = "w",
		func = function(handle)
			handle:show_warnings()
		end,
		cb = function(state, widget)
			if #state.warnings > 0 then
				widget.bg = "#aa7700"
			end
		end,
	},
	{
		label = "Quit",
		key = "q",
		func = function(handle)
			quit()
		end,
	},
}

---@param cb fun(logs: Log[])
local function parse_journal(cb)
	local cmd = string.format('journalctl --user --since "%s" | grep "[EW]: awesome:"', startup_date)
	awful.spawn.easy_async("sh -c '" .. cmd .. "'", function(stdout, stderr, exitreason, exitcode)
		if exitcode ~= 0 then
			gears.debug.print_error(stderr)
		end
		local logs = {}

		-- Pattern Breakdown:
		-- (%d%d%d%d%-%d%d%-%d%d) -> Date (YYYY-MM-DD)
		-- (%d%d:%d%d:%d%d)       -> Time (HH:MM:SS)
		-- ([WE]): awesome:%s*   -> Level (W or E) + literal "awesome:" + space
		-- (.*)                  -> Remainder of line (Message)
		local pattern = "(%d%d%d%d%-%d%d%-%d%d) (%d%d:%d%d:%d%d) ([WE]): awesome:%s*([^\n]+)"

		-- TODO: Handle stack tracebacks
		for d, t, l, m in stdout:gmatch(pattern) do
			logs[#logs + 1] = {
				date = d,
				time = t,
				level = l,
				message = m,
			}
		end

		cb(logs)
	end)
end

---@param module_health ModuleHealth
---@param module_name   string
---@return string
local function check_module_health(module_health, module_name)
	local lines = { "<b>" .. module_health.name .. "</b> <i>[" .. module_name .. "]</i>:" }
	for _, section in ipairs(module_health.sections or {}) do
		lines[#lines + 1] = section.label .. ":"
		for _, item in ipairs(section.items or {}) do
			lines[#lines + 1] = string.format(
				"- %s %s",
				item.status == HealthStatus.OK and "✅ OK"
					or item.status == HealthStatus.WARNING and "⚠️ WARNING"
					or item.status == HealthStatus.ERROR and "❌ ERROR"
					or "",
				item.details
			)
		end
	end
	return table.concat(lines, "\n")
end

function checkhealth:popup()
	if popup then
		if not popup.visible then
			popup.visible = true
		end
		return
	end

	---@type AwesomeScreen
	local screen = awful.screen.focused()

	popup = awful.popup({
		widget = wibox.widget({
			text = "Running checkhealth...",
			forced_width = screen.geometry.width * 0.8,
			forced_height = screen.geometry.height * 0.8,
			halign = "center",
			valign = "center",
			widget = wibox.widget.textbox,
		}),
		bg = beautiful.checkhealth_bg or beautiful.bg_normal,
		border_color = beautiful.popup_border_color or "EEEEEE",
		border_width = beautiful.border_width or 2,
		ontop = true,
		placement = awful.placement.centered,
		screen = screen,
	})

	parse_journal(function(logs)
		---@type Log[]
		local warnings = {}
		---@type Log[]
		local errors = {}

		---@type number|nil
		local max_loop_time

		for _, log in ipairs(logs) do
			if log.level == "E" then
				errors[#errors + 1] = log
			else
				warnings[#warnings + 1] = log
				local pattern = "Last main loop iteration took (%d+.%d+) seconds"
				local loop_time = log.message:match(pattern)
				if loop_time then
					if not max_loop_time or loop_time > max_loop_time then
						max_loop_time = loop_time
					end
				end
			end
		end

		---@type State
		local state = {
			logs = logs,
			errors = errors,
			warnings = warnings,
		}

		local logs_summary = {
			text = #errors .. " errors, " .. #warnings .. " warnings",
			widget = wibox.widget.textbox,
		}

		local info = {
			{
				text = "Session start: " .. startup_date,
				widget = wibox.widget.textbox,
			},
			{
				text = "Longest loop: " .. (max_loop_time or 0) .. " seconds",
				widget = wibox.widget.textbox,
			},
			logs_summary,
			layout = wibox.layout.fixed.vertical,
		}

		local _overview
		local function make_overview()
			if _overview then
				return _overview
			end
			local lines = {}
			for module_name, module in pairs(package.loaded) do
				local ch_fn = type(module) == "table" and rawget(module, "checkhealth")
				if type(ch_fn) == "function" then
					lines[#lines + 1] = check_module_health(module.checkhealth(), module_name)
				end
			end
			_overview = wibox.widget({
				markup = #lines > 0 and table.concat(lines, "\n\n") or "No checkhealth modules loaded",
				widget = wibox.widget.textbox,
			})
			return _overview
		end

		---@param logs Log[]
		---@param or_else string
		---@return AwesomeWidget
		local function logs_widget(logs, or_else)
			local lines = {}
			if #logs == 0 then
				lines = {
					or_else,
				}
			end
			for _, log in ipairs(logs) do
				local icon = log.level == "E" and "❌" or "⚠️"
				lines[#lines + 1] =
					string.format('<span foreground="#aaaaaa">%s</span>  %s  <b>%s</b>', log.time, icon, log.message)
			end
			return wibox.widget({
				{
					markup = table.concat(lines, "\n"),
					widget = wibox.widget.textbox,
					font = beautiful.checkhealth_logs_font or "Monospace 10",
				},
				widget = wibox.container.background,
			})
		end

		local _logs_widget
		local function make_logs_widget()
			if _logs_widget then
				return _logs_widget
			end
			_logs_widget = logs_widget(state.logs, "No errors or warnings")
			return _logs_widget
		end

		local _warnings_widget
		local function make_warnings_widget()
			if _warnings_widget then
				return _warnings_widget
			end
			_warnings_widget = logs_widget(state.warnings, "No warnings")
			return _warnings_widget
		end

		local _errors_widget
		local function make_errors_widget()
			if _errors_widget then
				return _errors_widget
			end
			_errors_widget = logs_widget(state.errors, "No errors")
			return _errors_widget
		end

		local actions_widget = {
			spacing = 20,
			layout = wibox.layout.fixed.horizontal,
		}

		local pager_border_color = beautiful.checkhealth_logs_border_color or beautiful.bg_focus or "#555555"
		local pg = pager({ widget = make_overview(), indicator_bg = pager_border_color })

		---@type PopupHandle
		local handle = {
			show_overview = function(_)
				pg:set_contents(make_overview())
			end,
			show_logs = function(_)
				pg:set_contents(make_logs_widget())
			end,
			show_warnings = function(_)
				pg:set_contents(make_warnings_widget())
			end,
			show_errors = function(_)
				pg:set_contents(make_errors_widget())
			end,
			close = function(_)
				quit()
			end,
		}

		for _, action in ipairs(popup_actions) do
			local label = type(action.label) == "function" and action.label(state) or action.label
			local btn = {
				{
					{
						markup = label .. " (" .. action.key .. ")",
						widget = wibox.widget.textbox,
					},
					widget = wibox.container.margin,
					margins = { top = 5, bottom = 5, left = 10, right = 10 },
				},
				widget = wibox.container.background,
				bg = "#777777",
			}
			if action.cb then
				action.cb(state, btn)
			end
			btn = wibox.widget(btn)

			btn:buttons(awful.button({}, 1, function()
				action.func(handle)
			end))
			actions_widget[#actions_widget + 1] = btn
		end

		-- Build one keygrabber: pager scroll bindings + popup action bindings.
		local keybinds = {}
		for _, kb in ipairs(pg.keybindings) do
			keybinds[#keybinds + 1] = kb
		end
		for _, action in ipairs(popup_actions) do
			keybinds[#keybinds + 1] = {
				{},
				action.key,
				function()
					action.func(handle)
				end,
			}
		end

		keygrabber = awful.keygrabber({ keybindings = keybinds })
		keygrabber:start()

		popup.widget = wibox.widget({
			{
				{
					info,
					actions_widget,
					spacing = 10,
					layout = wibox.layout.fixed.vertical,
				},
				{
					pg.widget,
					widget = wibox.container.margin,
					margins = { left = 2, right = 2 },
					color = pager_border_color,
				},
				spacing = 10,
				layout = wibox.layout.fixed.vertical,
			},
			forced_width = screen.geometry.width * 0.8,
			forced_height = screen.geometry.height * 0.8,
			widget = wibox.container.margin,
			margins = 10,
		})
	end)
end

return checkhealth
