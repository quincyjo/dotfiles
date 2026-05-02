-- frames/pager.lua
-- Scroll chrome wrapping a frames.buffer.
-- The pager exposes scroll keybindings as a readable field so the owner can
-- incorporate them into a single keygrabber alongside its own bindings.
local wibox = require("wibox")
local buffer = require("frames.buffer")

-- ----------------------------------------------------------------------------
-- Types
-- ----------------------------------------------------------------------------

---@class PagerOpts
---@field widget?       table                 Content widget passed through to buffer.
---@field height?       integer               Total pager height; buffer uses dynamic height if nil.
---@field indicator_bg? string                Background color of indicator widgets.
---@field on_scroll? fun(state: ScrollState)  Called after pager updates its display.

---@class PagerHandle
---@field widget       table    Full composed widget to embed in a popup layout.
---@field keybindings  table[]  Scroll keybindings: `{ {mods}, key, fn }`. Merge into owner's keygrabber.
---@field set_contents fun(self, widget: AwesomeWidget)
---@field _buffer      BufferHandle

-- ----------------------------------------------------------------------------
-- Constructor
-- ----------------------------------------------------------------------------

local pager = {}

setmetatable(pager, {
	__call = function(_, opts)
		opts = opts or {}

		local top_indicator = wibox.widget({ widget = wibox.widget.textbox, text = " ", align = "center" })
		local bottom_left = wibox.widget({
			text = "C-d/u C-f/b g/G",
			align = "left",
			forced_width = 150,
			widget = wibox.widget.textbox,
		})
		local bottom_center = wibox.widget({ widget = wibox.widget.textbox, text = " ", align = "center" })
		local bottom_right = wibox.widget({
			text = "0%",
			align = "right",
			forced_width = 150,
			widget = wibox.widget.textbox,
		})

		local function update_display(state)
			top_indicator:set_text(state.max_offset == 0 and " " or state.at_top and "-- TOP --" or "▲ MORE ▲")
			bottom_center:set_text(
				state.max_offset == 0 and " " or state.at_bottom and "-- BOTTOM --" or "▼ MORE ▼"
			)
			bottom_right:set_text(math.floor(state.pct) .. "%")
			if opts.on_scroll then
				opts.on_scroll(state)
			end
		end

		local buf = buffer({
			widget = opts.widget,
			height = opts.height,
			on_scroll = update_display,
		})

		-- Seed the display with the initial (pre-layout) state.
		update_display(buf.state)

		-- Composed layout
		local bottom_bar = {
			{
				bottom_left,
				bottom_center,
				bottom_right,
				layout = wibox.layout.align.horizontal,
			},
			widget = wibox.container.background,
			bg = opts.indicator_bg,
		}

		local top_bar = {
			top_indicator,
			widget = wibox.container.background,
			bg = opts.indicator_bg,
		}

		local composed = wibox.widget({
			top_bar,
			buf.widget,
			bottom_bar,
			layout = wibox.layout.align.vertical,
		})

		-- Scroll keybindings — read buf.viewport_height at keypress time.
		-- The owner merges these into its own keygrabber.
		local keybindings = {
			{
				{ "Control" },
				"d",
				function()
					buf:scroll_by(math.floor(buf.viewport_height / 2))
				end,
			},
			{
				{ "Control" },
				"u",
				function()
					buf:scroll_by(-math.floor(buf.viewport_height / 2))
				end,
			},
			{
				{ "Control" },
				"f",
				function()
					buf:scroll_by(buf.viewport_height)
				end,
			},
			{
				{ "Control" },
				"b",
				function()
					buf:scroll_by(-buf.viewport_height)
				end,
			},
			{
				{},
				"g",
				function()
					buf:go_to_top()
				end,
			},
			{
				{ "Shift" },
				"G",
				function()
					buf:go_to_bottom()
				end,
			},
		}

		return {
			widget = composed,
			keybindings = keybindings,
			_buffer = buf,
			set_contents = function(self, widget)
				self._buffer:set_contents(widget)
			end,
		}
	end,
})

return pager
