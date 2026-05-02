require("themes.qubit.types")

-- Awesome
local gears = require("gears")
local lgi = require("lgi")
local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi

-- Theme
local palette = require("themes.qubit.palette")

local media_art = require("continuity.media.art")

---@class MediaWidgetHandle    A self managed media widget.
---@field widget AwesomeWidget The widget for display.
---@field start fun()          Start widget monitoring, IE, tell the widget it is visible.
---@field stop fun()           Stop widget monitoring, IE, tell the widget it is not visible.

---@class MediaWidgetOpts
---@field width           number       The width of the widget.
---@field height          number       The height of the widget.
---@field on_interaction? fun()        Callback for slider interaction.
---@field art?            string|false If nil, the art will be fetched. Is a filepath string or false if there is no art.

local function format_time(time)
	local minutes = math.floor(time / 60)
	local seconds = math.floor(time % 60)
	if minutes < 60 then
		return string.format("-%d:%02d", minutes, seconds)
	end
	local hours = math.floor(minutes / 60)
	return string.format("-%d:%02d:%02d", hours, minutes % 60, seconds)
end

--- Calculates the average color of an image.
---@param image_path string
---@return HexColor|nil
local function average_color(image_path)
	local GdkPixbuf = lgi.GdkPixbuf
	local pixbuf = GdkPixbuf.Pixbuf.new_from_file(image_path)
	if not pixbuf then
		return nil
	end

	local small = pixbuf:scale_simple(1, 1, GdkPixbuf.InterpType.BILINEAR)
	if not small then
		return nil
	end

	local pixels = small:get_pixels()
	local r = pixels:byte(1)
	local g = pixels:byte(2)
	local b = pixels:byte(3)
	return string.format("#%02x%02x%02x", r, g, b)
end

---@param image_path string
---@param cb fun(color: HexColor|nil)
local function average_color_async(image_path, cb)
	awful.spawn.easy_async({ "convert", image_path, "-resize", "1x1!", "txt:-" }, function(stdout, _, _, exitcode)
		if exitcode ~= 0 then
			cb(nil)
			return
		end
		local hex = stdout:match("#(%x%x%x%x%x%x)")
		cb(hex and "#" .. hex:lower() or nil)
	end)
end

---@param color HexColor
---@param image table
---@param width number
---@param height number
local function media_gradient(color, image, width, height)
	-- For wide images, calculate the offset to align the gradient with the left edge.
	if not image.source_height then
		return nil
	end
	local ratio = height / image.source_height
	local offset = image.source_width * ratio - height
	return {
		type = "radial",
		from = { width - offset, height / 2, 8 },
		to = { width - offset, height / 2, width },
		stops = { -- verbose but looks better :c
			{ 0, color .. "00" },
			{ 0.1, color .. "33" },
			{ 0.2, color .. "66" },
			{ 0.3, color .. "aa" },
			{ 0.4, color .. "ff" },
			{ 0.5, color .. "ff" },
			{ 1, color .. "99" },
		},
	}
end

---@class ButtonHandle
---@field widget AwesomeWidget
---@field activate fun()
---@field deactivate fun()
---@field update fun(pb?: Playback)

---@param glyph string|AwesomeWidget
---@param playback? Playback
---@param is_active_for fun(pb?: Playback): boolean
---@param action fun()
---@return ButtonHandle
local function make_button(glyph, playback, is_active_for, action)
	local is_active = is_active_for(playback)
	local btn_bg = is_active and palette.bg_3 .. "AA" or palette.bg_2 .. "88"

	local btn = wibox.widget({
		type(glyph) == "string" and wibox.widget({
			markup = glyph,
			align = "center",
			widget = wibox.widget.textbox,
			forced_height = dpi(18),
		}) or glyph,
		widget = wibox.container.background,
		border_color = palette.bg_2,
		border_width = is_active and dpi(1) or 0,
		shape = gears.shape.rounded_rect,
		bg = btn_bg,
		fg = is_active and palette.fg or palette.fg_2,
	})

	local function highlight()
		btn.bg = palette.fg_2 .. "AA"
	end

	local function unhighlight()
		btn.bg = btn_bg
	end

	local function activate()
		if is_active then
			return
		end
		is_active = true
		btn_bg = palette.bg_3 .. "AA"
		btn.bg = btn_bg
		btn.border_width = dpi(1)
		btn.fg = palette.fg
		btn:connect_signal("mouse::enter", highlight)
		btn:connect_signal("mouse::leave", unhighlight)
		if action then
			btn:buttons(awful.button({}, 1, action))
		end
	end

	local function deactivate()
		if not is_active then
			return
		end
		is_active = false
		btn_bg = palette.bg_2 .. "88"
		btn.bg = btn_bg
		btn.border_width = 0
		btn.fg = palette.fg_2
		btn:disconnect_signal("mouse::enter", highlight)
		btn:disconnect_signal("mouse::leave", unhighlight)
		btn.buttons = {}
	end

	if is_active then
		btn:connect_signal("mouse::enter", highlight)
		btn:connect_signal("mouse::leave", unhighlight)
		if action then
			btn:buttons(awful.button({}, 1, action))
		end
	end

	return {
		widget = btn,
		activate = activate,
		deactivate = deactivate,
		update = function(pb)
			if is_active_for(pb) then
				activate()
			else
				deactivate()
			end
		end,
	}
end

---@param source MediaSource
---@param opts MediaWidgetOpts
---@return MediaWidgetHandle
return function(source, opts)
	local state = source.state
	local updating_slider = false
	local art = opts.art or nil

	local art_widget = wibox.widget({
		image = art,
		resize = true,
		forced_height = opts.height,
		widget = wibox.widget.imagebox,
	})

	local bg = art and average_color(art) or palette.bg_3

	local art_gradient_widget = wibox.widget({
		widget = wibox.container.background,
		bg = art and media_gradient(bg, art_widget, opts.width, opts.height) or nil,
	})

	local bg_widget = {
		{
			art_widget,
			halign = "right",
			widget = wibox.container.place,
		},
		art_gradient_widget,
		layout = wibox.layout.stack,
		opacity = 0.5,
	}

	local loop_widget = wibox.widget({
		markup = state.loop == "track" and "󰑘" or state.loop == "playlist" and "󰑖" or "",
		widget = wibox.widget.textbox,
		forced_width = state.loop and state.loop ~= "none" and dpi(14) or 0,
		forced_height = dpi(10),
	})

	local function set_loop(loop)
		loop_widget:set_markup(loop == "track" and "󰑘" or loop == "playlist" and "󰑖" or "")
		loop_widget.forced_width = loop and loop ~= "none" and dpi(14) or 0
	end

	local shuffle_widget = wibox.widget({
		markup = state.shuffle and "󰒟" or "",
		widget = wibox.widget.textbox,
		forced_width = state.shuffle and dpi(14) or 0,
		forced_height = dpi(10),
	})

	local function set_shuffle(shuffle)
		shuffle_widget:set_markup(shuffle and "󰒟" or "")
		shuffle_widget.forced_width = shuffle and dpi(14) or 0
	end

	local position_widget = wibox.widget({
		markup = format_time(state.duration and state.position and state.duration - state.position),
		align = "center",
		widget = wibox.widget.textbox,
		forced_height = dpi(10),
	})

	-- TODO: Make dynamic between slider and bar based playback can_seek.
	local position_slider = wibox.widget({
		minimum = 0,
		maximum = state.duration and state.duration > 0 and state.duration or 1,
		value = state.position or 0,
		forced_height = dpi(8),
		bar_shape = gears.shape.rounded_rect,
		bar_height = dpi(4),
		bar_color = palette.bg_3,
		bar_active_color = state.status == "playing" and palette.blue or palette.fg_2,
		handle_shape = gears.shape.circle,
		handle_color = state.status == "playing" and palette.blue or palette.fg_2,
		handle_width = dpi(8),
		widget = wibox.widget.slider,
	})
	-- The slider uses a mousegrabber, so debounce is the best option as button::release doesn't work.
	local debounce_timer
	position_slider:connect_signal("property::value", function()
		position_widget:set_markup(format_time(state.duration and state.duration - position_slider.value))
		if updating_slider then
			return
		end
		if opts.on_interaction then
			opts.on_interaction()
		end
		if debounce_timer then
			debounce_timer:again()
			return
		end
		debounce_timer = gears.timer({
			timeout = 0.1,
			autostart = true,
			single_shot = true,
			callback = function()
				source.playback:set_position(position_slider.value)
				debounce_timer = nil
			end,
		})
	end)

	---@param pos? number
	local function update_slider(pos)
		updating_slider = true
		position_slider.value = pos or 0
		updating_slider = false
	end

	local play_pause_icon = wibox.widget({
		markup = state.status == "playing" and "󰏤" or "󰐊",
		align = "center",
		widget = wibox.widget.textbox,
		forced_height = dpi(18),
	})

	local play_pause_btn = make_button(play_pause_icon, source.playback, function(pb)
		return pb and pb.can_play and pb.can_pause or false
	end, function()
		if source.playback then
			source.playback:play_pause()
		end
	end)
	local previous_btn = make_button("󰒮", source.playback, function(pb)
		return pb and pb.can_go_previous or false
	end, function()
		if source.playback then
			source.playback:previous()
		end
	end)
	local next_btn = make_button("󰒭", source.playback, function(pb)
		return pb and pb.can_go_next or false
	end, function()
		if source.playback then
			source.playback:next()
		end
	end)

	local controls = {
		previous_btn.widget,
		play_pause_btn.widget,
		next_btn.widget,
		spacing = dpi(12),
		layout = wibox.layout.flex.horizontal,
	}

	local playback_section = {
		{
			{
				{
					{
						shuffle_widget,
						loop_widget,
						layout = wibox.layout.fixed.horizontal,
					},
					{
						position_slider,
						widget = wibox.container.margin,
						margins = { left = dpi(0), right = dpi(4) },
					},
					position_widget,
					layout = wibox.layout.align.horizontal,
				},
				controls,
				spacing = dpi(6),
				layout = wibox.layout.fixed.vertical,
			},
			widget = wibox.container.margin,
			margins = { left = dpi(8), right = dpi(8), top = dpi(6), bottom = dpi(6) },
		},
		widget = wibox.container.background,
		bg = palette.black .. "44",
	}

	local function title_markup(title)
		return title and title:gsub("&", "&amp;") or "Unknown"
	end

	local title_widget = wibox.widget({
		markup = title_markup(state.title),
		ellipsize = "end",
		widget = wibox.widget.textbox,
	})

	local function artist_markup(artist)
		return " " .. (artist and artist:gsub("&", "&amp;") or "Unknown")
	end

	local artist_widget = wibox.widget({
		markup = artist_markup(state.artist),
		ellipsize = "end",
		widget = wibox.widget.textbox,
	})

	local function album_markup(album)
		return album and #album > 0 and ("󰗮 " .. album:gsub("&", "&amp;")) or ""
	end

	local album_widget = wibox.widget({
		markup = album_markup(state.album),
		ellipsize = "end",
		widget = wibox.widget.textbox,
	})

	local details = {
		nil,
		{
			{
				{
					nil,
					{
						title_widget,
						artist_widget,
						album_widget,
						spacing = dpi(2),
						layout = wibox.layout.flex.vertical,
					},
					source.app_icon and {
						{
							image = source.app_icon,
							resize = true,
							forced_height = opts.height / 4,
							forced_width = opts.height / 4,
							widget = wibox.widget.imagebox,
						},
						halign = "right",
						valign = "top",
						widget = wibox.container.place,
					} or nil,
					layout = wibox.layout.align.horizontal,
				},
				widget = wibox.container.margin,
				margins = dpi(8),
			},
			widget = wibox.container.background,
			bg = gears.color({
				type = "linear",
				from = { 0, 0 },
				to = { opts.width, 0 },
				stops = {
					{ 0, palette.black .. "44" },
					{ 1, palette.black .. "00" },
				},
			}),
		},
		playback_section,
		layout = wibox.layout.align.vertical,
	}

	-- widget is built via wibox.widget() -> make_widget_declarative, so it has
	-- get_children_by_id. rawset set_notification here so naughty's
	-- _set_common_property can hand us the notification for cleanup.
	local widget = wibox.widget({
		bg_widget,
		details,
		forced_width = opts.width,
		forced_height = opts.height,
		layout = wibox.layout.stack,
	})

	---@type string|nil
	local last_art_uri = opts.art ~= nil and state.art_uri or nil

	---@param art_uri string|nil
	local function refresh_art(art_uri)
		if art_uri ~= last_art_uri then
			last_art_uri = art_uri
			media_art.resolve(art_uri, function(img)
				if img and last_art_uri == art_uri then -- img resolved and still target.
					average_color_async(img, function(color)
						if last_art_uri == art_uri then -- still target.
							art_widget.image = img
							art_gradient_widget.bg = img
									and media_gradient(color or palette.bg_3, art_widget, opts.width, opts.height)
								or nil
						end
					end)
				elseif last_art_uri == art_uri then -- no img but still target.
					art_widget.image = nil
					art_gradient_widget.bg = nil
				end
			end)
		end
	end

	---@param s MediaState
	local function update(s)
		state = s
		if state.status == "playing" then
			position_slider.bar_active_color = palette.blue
			position_slider.handle_color = palette.blue
			play_pause_icon:set_markup("󰏤")
		else
			position_slider.bar_active_color = palette.fg_2
			position_slider.handle_color = palette.fg_2
			play_pause_icon:set_markup("󰐊")
		end
		title_widget:set_markup(title_markup(state.title))
		artist_widget:set_markup(artist_markup(state.artist))
		album_widget:set_markup(album_markup(state.album))
		set_shuffle(state.shuffle)
		set_loop(state.loop)
		previous_btn.update(source.playback)
		play_pause_btn.update(source.playback)
		next_btn.update(source.playback)
		if state.duration and state.duration > 0 then
			position_slider.maximum = state.duration
			position_widget:set_markup(format_time(state.duration - position_slider.value))
		end
		update_slider(state.position)
		source.position:get(update_slider)
		refresh_art(state.art_uri)
	end

	source.position:get(update_slider)
	---@type fun()|nil
	local stop_pos = source.position:subscribe(update_slider)
	---@type fun()|nil
	local stop_source_sub = source:subscribe(update)
	-- Art wasn't prefetched, so we need to do that now.
	if opts.art == nil then
		refresh_art(state.art_uri)
	end

	local function start()
		if stop_pos or stop_source_sub then
			return
		end
		update(source.state)
		source.position:get(update_slider)
		stop_pos = source.position:subscribe(update_slider)
		stop_source_sub = source:subscribe(update)
	end

	local function stop()
		if stop_pos then
			stop_pos()
		end
		if stop_source_sub then
			stop_source_sub()
		end
		stop_pos = nil
		stop_source_sub = nil
	end

	return {
		widget = widget,
		stop = stop,
		start = start,
	}
end
