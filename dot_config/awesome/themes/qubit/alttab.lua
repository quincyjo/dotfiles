local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi

local lgi = require("lgi")
local cairo = lgi.cairo

local palette = require("themes.qubit.palette")

local LIST_WIDTH = dpi(260)
local PREVIEW_WIDTH = dpi(480)
local PREVIEW_HEIGHT = dpi(270)
local ITEM_HEIGHT = dpi(40)
local ICON_SIZE = dpi(24)
local MINI_ICON_SIZE = dpi(64)
local PADDING = dpi(0)

local BG_COLOR = palette.bg_2 .. "33"
local SELECTED_BG_COLOR = palette.bg_3 .. "AA"
local SELECTED_FG_COLOR = palette.blue

local INFO_HEIGHT = dpi(8)
local INFO_COLOR = palette.black .. "CC"
local INFO_COLOR_ACTIVE = palette.purple

---@type table<AwesomeClient, ImageSurface>  Cached ImageSurfaces keyed by client.
local preview_cache = {}
---@type AlttabAPI|nil
local api = nil
---@type table<integer, AwesomeWidget>  Background containers for each list item.
local item_bgs = {}
---@type AwesomeWidget|nil  Right-panel background container.
local preview_bg = nil
---@type table|nil
local popup = nil
---@type AwesomeClient[]|nil
local current_clients = nil
---@type integer|nil
local current_index = nil
---@type {screen: AwesomeScreen, spec: table}[]
local screen_dot_specs = {}
---@type table<AwesomeScreen, {tag_name: string, spec: table}[]>
local tag_dot_specs = {}

--- Capture a client's current content into the cache and return the image.
--- Returns nil if the content is unavailable.
---@param c AwesomeClient
---@return ImageSurface|nil
local function capture(c)
	if c.minimized or c.hidden then
		return nil
	end
	---@diagnostic disable-next-line: param-type-mismatch
	local ok, surf = pcall(gears.surface, c.content)
	if not ok or not surf then
		return nil
	end
	local geom = c:geometry()
	if geom.width <= 0 or geom.height <= 0 then
		return nil
	end
	local img = cairo.ImageSurface.create(cairo.Format.ARGB32, geom.width, geom.height)
	local cr = cairo.Context.create(img)
	cr:set_source_surface(surf, 0, 0)
	cr:paint()
	preview_cache[c] = img
	return img
end

local function build_dot_specs()
	screen_dot_specs = {}
	for s in screen do
		local ratio = s.geometry.width / s.geometry.height
		screen_dot_specs[#screen_dot_specs + 1] = {
			screen = s,
			spec = {
				forced_height = INFO_HEIGHT,
				forced_width = ratio * INFO_HEIGHT,
				shape = function(cr, w, h)
					gears.shape.rounded_rect(cr, w, h, 2)
				end,
				bg = INFO_COLOR,
				widget = wibox.container.background,
			},
		}
	end
	for s in screen do
		tag_dot_specs[s] = {}
		for _, tag in ipairs(s.tags) do
			tag_dot_specs[s][#tag_dot_specs[s] + 1] = {
				tag_name = tag.name,
				spec = {
					forced_height = INFO_HEIGHT / 2,
					forced_width = INFO_HEIGHT / 2,
					shape = gears.shape.circle,
					bg = INFO_COLOR,
					widget = wibox.container.background,
				},
			}
		end
	end
end

local function make_tags(c)
	local active = {}
	for _, tag in ipairs(c:tags()) do
		active[tag.name] = true
	end
	local items = { layout = wibox.layout.fixed.horizontal, spacing = dpi(2) }
	for _, entry in ipairs(tag_dot_specs[c.screen]) do
		local spec = entry.spec
		if active[entry.tag_name] then
			spec = {}
			for k, v in pairs(entry.spec) do
				spec[k] = v
			end
			spec.bg = INFO_COLOR_ACTIVE
		end
		items[#items + 1] = spec
	end
	return items
end

local function make_screens(c)
	if screen.count() == 1 then
		return
	end
	local items = { layout = wibox.layout.fixed.horizontal, spacing = dpi(2) }
	for _, entry in ipairs(screen_dot_specs) do
		local spec = entry.spec
		if c.screen == entry.screen then
			spec = {}
			for k, v in pairs(entry.spec) do
				spec[k] = v
			end
			spec.bg = INFO_COLOR_ACTIVE
		end
		items[#items + 1] = spec
	end
	return items
end

---@param c AwesomeClient
---@param index integer
---@param selected boolean
---@return AwesomeWidget
local function make_item(c, index, selected)
	local info = {
		{
			{
				{
					make_screens(c),
					halign = "right",
					valign = "center",
					widget = wibox.container.place,
				},
				nil,
				make_tags(c),
				forced_height = ITEM_HEIGHT,
				layout = wibox.layout.align.vertical,
			},
			widget = wibox.container.margin,
			margins = dpi(2),
		},
		halign = "right",
		valign = "center",
		forced_height = ITEM_HEIGHT,
		forced_width = LIST_WIDTH,
		widget = wibox.container.place,
	}

	local client = {
		{
			{
				image = c.icon,
				resize = true,
				forced_width = ICON_SIZE,
				forced_height = ICON_SIZE,
				widget = wibox.widget.imagebox,
			},
			{
				text = c.name or "?",
				forced_width = LIST_WIDTH - ICON_SIZE - dpi(24),
				ellipsize = "end",
				widget = wibox.widget.textbox,
			},
			spacing = dpi(8),
			layout = wibox.layout.fixed.horizontal,
		},
		margins = dpi(8),
		widget = wibox.container.margin,
	}

	local item = wibox.widget({
		{
			info,
			client,
			layout = wibox.layout.stack,
		},
		bg = selected and SELECTED_BG_COLOR or "#00000000",
		fg = selected and SELECTED_FG_COLOR or palette.fg,
		forced_height = ITEM_HEIGHT,
		widget = wibox.container.background,
	})

	item:connect_signal("mouse::enter", function()
		if api then
			api.select(index)
		end
	end)
	item:connect_signal("button::press", function(_, _, _, button)
		if not api then
			return
		end
		if button == 1 then
			api.close_session(true)
		elseif button == 3 then
			api.close_session(false)
		end
	end)

	return item
end

---@param c AwesomeClient
local function set_preview(c)
	---@type ImageSurface|nil
	local img = not c:isvisible() and preview_cache[c] or c:isvisible() and capture(c) or nil
	preview_bg.widget = {
		img and {
			image = img,
			resize = true,
			widget = wibox.widget.imagebox,
		} or {
			image = c.icon,
			resize = true,
			forced_width = MINI_ICON_SIZE,
			forced_height = MINI_ICON_SIZE,
			widget = wibox.widget.imagebox,
		},
		halign = "center",
		valign = "center",
		forced_width = PREVIEW_WIDTH,
		forced_height = PREVIEW_HEIGHT,
		widget = wibox.container.place,
	}
end

---@param clients AwesomeClient[]
---@param index integer
local function build_popup(clients, index)
	build_dot_specs()
	current_clients = clients
	current_index = index
	item_bgs = {}

	local list = { layout = wibox.layout.fixed.vertical }
	for i, c in ipairs(clients) do
		local item = make_item(c, i, i == index)
		item_bgs[i] = item
		list[i] = item
	end

	preview_bg = wibox.widget({
		forced_width = PREVIEW_WIDTH,
		forced_height = PREVIEW_HEIGHT,
		bg = palette.black .. "55",
		widget = wibox.container.background,
	})
	set_preview(clients[index])

	popup = awful.popup({
		widget = {
			{
				{
					list,
					strategy = "exact",
					width = LIST_WIDTH,
					widget = wibox.container.constraint,
				},
				preview_bg,
				spacing = PADDING,
				layout = wibox.layout.fixed.horizontal,
			},
			margins = PADDING,
			widget = wibox.container.margin,
		},
		bg = BG_COLOR,
		border_width = dpi(2),
		border_color = palette.bg_3,
		placement = awful.placement.centered,
		ontop = true,
		visible = true,
	})
end

---@type AlttabUI
return {
	show = build_popup,
	update = function(index)
		if not current_clients then
			return
		end
		if item_bgs[current_index] then
			item_bgs[current_index].bg = "00000000"
			item_bgs[current_index].fg = palette.fg
		end
		current_index = index
		if item_bgs[index] then
			item_bgs[index].bg = SELECTED_BG_COLOR
			item_bgs[index].fg = SELECTED_FG_COLOR
		end
		set_preview(current_clients[index])
	end,
	hide = function()
		if popup then
			popup.visible = false
			popup = nil
		end
		item_bgs = {}
		preview_bg = nil
		current_clients = nil
		current_index = nil
		screen_dot_specs = {}
		tag_dot_specs = {}
	end,
	on_init = function(a)
		api = a
	end,
	-- on_unfocus = capture,
	-- on_untagged = capture,
	on_minimized = capture,
	on_tag_selected = function(t)
		if not t.selected then
			for _, c in pairs(t:clients()) do
				capture(c)
			end
		end
	end,
	on_unmanage = function(c)
		preview_cache[c] = nil
	end,
}
