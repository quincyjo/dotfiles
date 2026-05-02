require("themes.qubit.types")

---@class StackedWidget
---@field id integer
---@field widget AwesomeWidget
---@field pop fun(self)
---@field reset_timeout fun(self)

---@class PushOpts
---@field timeout number
---@field widget AwesomeWidget

---@class PopupStack
---@field is_visible boolean
---@field push fun(self, opts: PushOpts): StackedWidget

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

---@param stack PopupStack
---@reuturn AwesomePopup
local function create_popup(stack)
	local widget = {
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(8),
	}
	---@diagnostic disable-next-line: undefined-field
	for _, stacked_widget in ipairs(stack._private.widgets) do
		widget[#widget + 1] = stacked_widget.widget
	end
	local popup = awful.popup({
		widget = wibox.widget(widget),
		ontop = true,
		placement = function(popup)
			awful.placement.top(popup, {
				margins = { top = dpi(24) },
				parent = awful.screen.focused(),
			})
		end,
		-- TODO: Window compositor still blurs this, so true margins is not doable.
		-- Maybe need to generate N popups with relative placements?
		bg = "#00000000",
		visible = true,
	})
	return popup
end

local PopupStackMt = {
	__index = {
		push = function(self, opts)
			local id = self._private.rolling_id + 1
			self._private.rolling_id = id
			local stacked_widget = {
				id = id,
				widget = opts.widget,
				pop = function(handle)
					for i, stack in ipairs(self._private.widgets) do
						if stack.id == handle.id then
							table.remove(self._private.widgets, i)
							if self._private.timers[handle.id] then
								self._private.timers[handle.id]:stop()
								self._private.timers[handle.id] = nil
							end
							if self._private.popup then
								self._private.popup.widget:remove_widgets(handle.widget)
							end
							if #self._private.widgets == 0 and self._private.popup then
								self.is_visible = false
								self._private.popup.visible = false
								self._private.popup = nil
							end
							break
						end
					end
				end,
				reset_timeout = function(handle)
					if self._private.timers[handle.id] then
						self._private.timers[handle.id]:again()
					end
				end,
			}
			table.insert(self._private.widgets, stacked_widget)
			self._private.timers[id] = gears.timer({
				timeout = opts.timeout or 5,
				single_shot = true,
				autostart = true,
				callback = function()
					stacked_widget:pop()
				end,
			})
			if not self._private.popup then
				self.is_visible = true
				self._private.popup = create_popup(self)
			else
				self._private.popup.widget:add(opts.widget)
			end
			return stacked_widget
		end,
	},
}

---@return PopupStack
function M.new()
	local _private = {
		---@type table<string, table>
		timers = {},
		rolling_id = 0,
		---@type StackedWidget[]
		widgets = {},
		---@type AwesomePopup
		popup = nil,
	}

	local stack = {
		_private = _private,
		is_visible = false,
	}

	return setmetatable(stack, PopupStackMt)
end

return setmetatable(M, {
	__call = function(_)
		return M.new()
	end,
})
