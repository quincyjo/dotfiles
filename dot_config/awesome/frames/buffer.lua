-- frames/buffer.lua
-- Scrollable clip container widget.
-- Returns a handle with a .widget (wibox node) and scroll API.
local base = require("wibox.widget.base")
local hierarchy = require("wibox.hierarchy")
local dpi = require("beautiful.xresources").apply_dpi

-- ----------------------------------------------------------------------------
-- Types
-- ----------------------------------------------------------------------------

---@class ScrollState
---@field offset     integer  Pixel offset from top (0 = at top).
---@field max_offset integer  content_height - viewport_height, clamped >= 0.
---@field pct        number   0–100 scroll percentage.
---@field at_top     boolean
---@field at_bottom  boolean

---@class BufferOpts
---@field widget?    table                        Initial content widget.
---@field height?    integer                      Known viewport height; updated dynamically from draw if nil.
---@field on_scroll? fun(state: ScrollState)      Called on every scroll change.

---@class BufferHandle
---@field widget          table        Embeddable wibox container.
---@field state           ScrollState  Current scroll state (readable).
---@field viewport_height integer      Last seen viewport height (readable).
---@field scroll_by       fun(self, delta: integer)
---@field set_scroll      fun(self, delta: integer)
---@field go_to_bottom    fun(self)
---@field go_to_top       fun(self)
---@field set_contents    fun(self, widget: AwesomeWidget)
---@field _private        BufferHandlePrivate

---@class BufferHandlePrivate
---@field content_height integer|nil  Cached content height; nil until first draw.
---@field child          table|nil    Inner content widget.
---@field on_scroll      fun(state: ScrollState)|nil
---@field hier           table|nil    wibox.hierarchy for the child subtree.
---@field hier_context   table|nil    Cleaned draw context for the hierarchy.
---@field hier_width     integer|nil  Width the hierarchy was built for.
---@field height_hint    integer|nil  Width the hierarchy was built for.

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------

-- Strip context fields that reference the outer drawable/wibox so that the
-- child hierarchy draws into the clip surface rather than the root window.
local function cleanup_context(context)
	local skip = { wibox = true, drawable = true, client = true, position = true }
	local res = {}
	for k, v in pairs(context) do
		if not skip[k] then
			res[k] = v
		end
	end
	return res
end

-- ----------------------------------------------------------------------------
-- State computation
-- ----------------------------------------------------------------------------

---@param offset         integer
---@param content_height integer|nil
---@param viewport_height integer
---@return ScrollState
local function compute_state(offset, content_height, viewport_height)
	local max_offset = math.max(0, (content_height or 0) - viewport_height)
	offset = math.max(0, math.min(offset, max_offset))
	local pct = max_offset > 0 and (offset / max_offset * 100) or 0
	return {
		offset = offset,
		max_offset = max_offset,
		pct = pct,
		at_top = offset == 0,
		at_bottom = offset >= max_offset,
	}
end

-- ----------------------------------------------------------------------------
-- Handle methods
-- ----------------------------------------------------------------------------

local handle_mt = {}
handle_mt.__index = handle_mt

--- Apply a new offset: clamp, update state, fire callback, request redraw.
---@param offset integer
function handle_mt:_apply(offset)
	local new_state = compute_state(offset, self._private.content_height, self.viewport_height)
	self.state = new_state
	if self._private.on_scroll then
		self._private.on_scroll(new_state)
	end
	self.widget:emit_signal("widget::redraw_needed")
	self.widget:emit_signal("widget::layout_changed")
end

--- Update state in-place after content/viewport height changes (no redraw emit).
--- Called from draw() after _content_height transitions from nil — so
--- max_offset always changes on that call. If new call sites are added,
--- the guard condition should be re-evaluated.
function handle_mt:_sync()
	local new_state = compute_state(self.state.offset, self._private.content_height, self.viewport_height)
	if new_state.max_offset == self.state.max_offset then
		return
	end
	self.state = new_state
	if self._private.on_scroll then
		self._private.on_scroll(new_state)
	end
end

---@param offset integer
function handle_mt:set_scroll(offset)
	self:_apply(offset)
end

---@param delta integer
function handle_mt:scroll_by(delta)
	self:_apply(self.state.offset + delta)
end

function handle_mt:go_to_top()
	self:_apply(0)
end

function handle_mt:go_to_bottom()
	-- Pass content_height as offset; compute_state clamps to max_offset.
	self:_apply(self._private.content_height or 0)
end

---@param widget table
function handle_mt:set_contents(widget)
	self._private.child = widget
	self._private.content_height = nil
	self._private.hier = nil
	self:_apply(0)
end

-- ----------------------------------------------------------------------------
-- Widget (clip container)
-- ----------------------------------------------------------------------------

---@param handle BufferHandle
---@return table
local function make_widget(handle)
	local w = base.make_widget(nil, nil, { enable_properties = true })

	-- Return the natural content height (capped at the offered height) so containers
	-- without a forced_height allocate only the space the content actually needs.
	-- Falls back to _height_hint (opts.height) before the first draw when content
	-- has not yet been measured. Do NOT set viewport_height here — align:fit() calls
	-- fit() on all slots with the full container height, which is larger than the
	-- buffer's actual allocated slice; only layout() and draw() get the correct value.
	function w:fit(_, width, height)
		local bound = handle._private.height_hint or handle._private.content_height
		return width, bound and math.min(height, bound) or height
	end

	-- Render the child via a wibox.hierarchy so the clip rectangle persists into
	-- child rendering. AwesomeWM's own hierarchy wraps widget.draw() in save/restore,
	-- which would undo any clip set there before children are drawn. By managing our
	-- own sub-hierarchy here and returning {} from layout(), we fully control clipping.
	function w:draw(context, cr, width, height)
		if not handle._private.child then
			return
		end
		handle.viewport_height = height

		-- Measure content height on first draw or after set_contents / width change.
		-- Use a large finite sentinel rather than math.huge: passing infinity through
		-- base.fit_widget can produce NaN (inf - inf) which LuaJIT's minsd converts
		-- back to infinity, causing cairo.RectangleInt to reject it.
		if not handle._private.content_height or handle._private.hier_width ~= width then
			local _, ch = base.fit_widget(self, context, handle._private.child, width, 2 ^ 24)
			handle._private.content_height = ch
			handle._private.hier = nil -- invalidate; hierarchy was built for different dimensions
			handle:_sync()
		end

		-- (Re)build the child hierarchy when needed.
		if not handle._private.hier then
			local ctx = cleanup_context(context)
			handle._private.hier = hierarchy.new(
				ctx,
				handle._private.child,
				width,
				handle._private.content_height,
				-- redraw_callback: child wants a visual refresh
				function()
					handle.widget:emit_signal("widget::redraw_needed")
				end,
				-- layout_callback: child dimensions changed; re-measure on next draw
				function()
					handle._private.content_height = nil
					handle._private.hier = nil
					handle.widget:emit_signal("widget::redraw_needed")
					handle.widget:emit_signal("widget::layout_changed")
				end,
				nil
			)
			handle._private.hier_context = ctx
			handle._private.hier_width = width
		end

		cr:save()
		cr:rectangle(0, 0, width, height)
		cr:clip()
		cr:translate(0, -handle.state.offset)
		handle._private.hier:draw(handle._private.hier_context, cr)
		cr:restore()
	end

	-- Return no children: the child subtree is rendered directly in draw() above.
	-- Returning children via layout() would place them at (0, -offset) without
	-- clipping, causing content to bleed outside the viewport boundary.
	function w:layout(_, _, height)
		handle.viewport_height = height
		return {}
	end

	local gears = require("gears")
	local awful = require("awful")
	w:buttons(gears.table.join(
		awful.button({}, 4, function()
			handle:scroll_by(dpi(-25))
		end),
		awful.button({}, 5, function()
			handle:scroll_by(dpi(25))
		end)
	))

	return w
end

-- ----------------------------------------------------------------------------
-- Constructor
-- ----------------------------------------------------------------------------

local buffer = {}

setmetatable(buffer, {
	__call = function(_, opts)
		opts = opts or {}
		local handle = setmetatable({
			state = compute_state(0, nil, opts.height or 0),
			viewport_height = opts.height or 0,
			_private = {
				content_height = nil,
				height_hint = opts.height or nil,
				child = opts.widget or nil,
				on_scroll = opts.on_scroll or nil,
				hier = nil,
				hier_context = nil,
				hier_width = nil,
			},
		}, handle_mt)
		handle.widget = make_widget(handle)
		return handle
	end,
})

return buffer
