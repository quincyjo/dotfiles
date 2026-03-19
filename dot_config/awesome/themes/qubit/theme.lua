local gears = require("gears")
local shape = gears.shape
local lain = require("lain")
local audio = require("themes.qubit.audio")
local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi

local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility

local palette = {
	black = "#0a0909",
	white = "#e4e2e1",
	bg = "#1c1b1a",
	bg_2 = "#252121",
	bg_3 = "#464442",
	fg = "#d7d4d2",
	fg_2 = "#656260",
	pink = "#e495b7",
	red = "#f04c8b",
	green = "#7eba7d",
	yellow = "#c4ad61",
	blue = "#79b8cc",
	cyan = "#71bcb5",
	purple = "#bea5db",
	orange = "#ea9785",
}

---@alias AwesomeWidget table
---@alias CairoContext table

---@alias HexColor string

---@alias RGB {
---    r: number,
---    g: number,
---    b: number,
---}

---@param hex HexColor
---@return RGB
local function hex_to_rgb(hex)
	if hex == nil then
		return { r = 0, g = 0, b = 0 }
	end
	return {
		r = tonumber(hex:sub(2, 3), 16),
		g = tonumber(hex:sub(4, 5), 16),
		b = tonumber(hex:sub(6, 7), 16),
	}
end

--- Convert an RGB color to a hex color string.
---@param rgb RGB
---@return HexColor
local function rgb_to_hex(rgb)
	-- Note that if awesome is not built against luajit, then this will error
	-- out. It can be fixed by adding a floor or ceil to the values before
	-- formatting the string.
	return string.format("#%02x%02x%02x", rgb.r, rgb.g, rgb.b)
end

--- Lighten a color. If amt is 1 or less, then it will be treated as a
--- percentage. Otherwise, it will be treated as an absolute amount and added to
--- each channel weighted to perserve hue.
---@param hex HexColor
---@param amt number
---@return HexColor
local function lighten(hex, amt)
	local rgb = hex_to_rgb(hex)
	if amt <= 1 then
		-- percentage
		local ratio = 1 + amt
		rgb.r = rgb.r * ratio
		rgb.g = rgb.g * ratio
		rgb.b = rgb.b * ratio
	else
		-- ratiod absolute
		local max = math.max(rgb.r, rgb.g, rgb.b)
		rgb.r = rgb.r + amt * (rgb.r / max)
		rgb.g = rgb.g + amt * (rgb.g / max)
		rgb.b = rgb.b + amt * (rgb.b / max)
	end
	rgb.r = (rgb.r < 0) and 0 or (rgb.r > 255) and 255 or rgb.r
	rgb.g = (rgb.g < 0) and 0 or (rgb.g > 255) and 255 or rgb.g
	rgb.b = (rgb.b < 0) and 0 or (rgb.b > 255) and 255 or rgb.b
	return rgb_to_hex(rgb)
end

--- Creates a vertical bevel gradient for the wibox.
---@param color HexColor The color of the gradient.
---@param height number The height of the gradient in pixels.
---@param opacity? number An optional opacity between 0 and 1.
local function gradient(color, height, opacity)
	local alpha = opacity and string.format("%02x", opacity * 255) or ""
	return {
		type = "linear",
		from = { 0, 0 },
		to = { 0, dpi(height) },
		stops = {
			{ 0, lighten(color, 0.3) .. alpha },
			{ 0.1, color .. alpha },
			{ 0.9, color .. alpha },
			{ 1, lighten(color, -0.3) .. alpha },
		},
	}
end

local dir = os.getenv("HOME") .. "/.config/awesome/themes/qubit"
local theme = {
	wallpaper = dir .. "/wall.png",
	-- font                                      = "MesloLGS NF 10",
	font = "Hack Nerd Font 10",
	fg_normal = palette.white,
	fg_focus = palette.yellow,
	fg_urgent = palette.red,
	bg_focus = palette.bg_2,
	bg_normal = palette.bg,
	bg_urgent = palette.bg_3,
	taglist_fg_focus = palette.blue,
	taglist_bg_focus = palette.black,
	-- taglist_shape_border_color_focus          = palette.red,
	tasklist_fg_normal = palette.fg_2,
	tasklist_bg_normal = palette.bg,
	tasklist_fg_focus = palette.blue,
	tasklist_bg_focus = palette.bg_2,
	tasklist_shape_border_color_focus = palette.bg_3,
	border_width = dpi(2),
	border_normal = palette.bg_3,
	border_focus = palette.yellow,
	border_marked = palette.pink,
	border_urgent = palette.red,
	titlebar_bg_focus = palette.bg,
	titlebar_bg_normal = palette.bg_2,
	titlebar_fg_focus = palette.yellow,
	titlebar_fg_normal = palette.purple,
	menu_height = dpi(18),
	wibox_height = dpi(18),
	menu_width = dpi(160),
	menu_submenu_icon = dir .. "/icons/submenu.png",
	awesome_icon = dir .. "/icons/awesome.png",
	awesome_icon_2 = dir .. "/icons/awesome_w.png",
	taglist_squares_sel = dir .. "/icons/square_sel.png",
	taglist_squares_unsel = dir .. "/icons/square_unsel.png",
	layout_tile = dir .. "/icons/tile.png",
	layout_tileleft = dir .. "/icons/tileleft.png",
	layout_tilebottom = dir .. "/icons/tilebottom.png",
	layout_tiletop = dir .. "/icons/tiletop.png",
	layout_fairv = dir .. "/icons/fairv.png",
	layout_fairh = dir .. "/icons/fairh.png",
	layout_spiral = dir .. "/icons/spiral.png",
	layout_dwindle = dir .. "/icons/dwindle.png",
	layout_max = dir .. "/icons/max.png",
	layout_fullscreen = dir .. "/icons/fullscreen.png",
	layout_magnifier = dir .. "/icons/magnifier.png",
	layout_floating = dir .. "/icons/floating.png",
	widget_ac = dir .. "/icons/ac.png",
	widget_battery = dir .. "/icons/battery.png",
	widget_battery_low = dir .. "/icons/battery_low.png",
	widget_battery_empty = dir .. "/icons/battery_empty.png",
	widget_brightness = dir .. "/icons/brightness.png",
	widget_mem = dir .. "/icons/mem.png",
	widget_cpu = dir .. "/icons/cpu.png",
	widget_temp = dir .. "/icons/temp.png",
	widget_net = dir .. "/icons/net.png",
	widget_hdd = dir .. "/icons/hdd.png",
	widget_music = dir .. "/icons/note.png",
	widget_music_on = dir .. "/icons/note_on.png",
	widget_music_pause = dir .. "/icons/pause.png",
	widget_music_stop = dir .. "/icons/stop.png",
	widget_vol = dir .. "/icons/vol.png",
	widget_vol_low = dir .. "/icons/vol_low.png",
	widget_vol_no = dir .. "/icons/vol_no.png",
	widget_vol_mute = dir .. "/icons/vol_mute.png",
	widget_mail = dir .. "/icons/mail.png",
	widget_mail_on = dir .. "/icons/mail_on.png",
	widget_task = dir .. "/icons/task.png",
	widget_scissors = dir .. "/icons/scissors.png",
	tasklist_plain_task_name = true,
	tasklist_disable_icon = false,
	useless_gap = 2,
	titlebar_close_button_focus = dir .. "/icons/titlebar/close_focus.png",
	titlebar_close_button_normal = dir .. "/icons/titlebar/close_normal.png",
	titlebar_ontop_button_focus_active = dir .. "/icons/titlebar/ontop_focus_active.png",
	titlebar_ontop_button_normal_active = dir .. "/icons/titlebar/ontop_normal_active.png",
	titlebar_ontop_button_focus_inactive = dir .. "/icons/titlebar/ontop_focus_inactive.png",
	titlebar_ontop_button_normal_inactive = dir .. "/icons/titlebar/ontop_normal_inactive.png",
	titlebar_sticky_button_focus_active = dir .. "/icons/titlebar/sticky_focus_active.png",
	titlebar_sticky_button_normal_active = dir .. "/icons/titlebar/sticky_normal_active.png",
	titlebar_sticky_button_focus_inactive = dir .. "/icons/titlebar/sticky_focus_inactive.png",
	titlebar_sticky_button_normal_inactive = dir .. "/icons/titlebar/sticky_normal_inactive.png",
	titlebar_floating_button_focus_active = dir .. "/icons/titlebar/floating_focus_active.png",
	titlebar_floating_button_normal_active = dir .. "/icons/titlebar/floating_normal_active.png",
	titlebar_floating_button_focus_inactive = dir .. "/icons/titlebar/floating_focus_inactive.png",
	titlebar_floating_button_normal_inactive = dir .. "/icons/titlebar/floating_normal_inactive.png",
	titlebar_maximized_button_focus_active = dir .. "/icons/titlebar/maximized_focus_active.png",
	titlebar_maximized_button_normal_active = dir .. "/icons/titlebar/maximized_normal_active.png",
	titlebar_maximized_button_focus_inactive = dir .. "/icons/titlebar/maximized_focus_inactive.png",
	titlebar_maximized_button_normal_inactive = dir .. "/icons/titlebar/maximized_normal_inactive.png",
}

local markup = lain.util.markup

local binclock = awful.widget.watch("date +'%a %d %b %R'", 60, function(widget, stdout)
	widget:set_markup(markup.font(theme.font, stdout))
end)

-- Calendar
theme.cal = lain.widget.cal({
	--cal = "cal --color=always",
	attach_to = { binclock },
	notification_preset = {
		font = "Terminus 10",
		fg = theme.fg_normal,
		bg = theme.bg_normal,
	},
})

-- Taskwarrior
local task = wibox.widget.imagebox(theme.widget_task)
lain.widget.contrib.task.attach(task, {
	-- do not colorize output
	show_cmd = "task | sed -r 's/\\x1B\\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g'",
})
task:buttons(my_table.join(awful.button({}, 1, lain.widget.contrib.task.prompt)))

-- Mail IMAP check
--[[ commented because it needs to be set before use
local mailicon = wibox.widget.imagebox(theme.widget_mail)
mailicon:buttons(my_table.join(awful.button({ }, 1, function () awful.spawn(mail) end)))
theme.mail = lain.widget.imap({
    timeout  = 180,
    server   = "server",
    mail     = "mail",
    password = "keyring get mail",
    settings = function()
        if mailcount > 0 then
            widget:set_text(" " .. mailcount .. " ")
            mailicon:set_image(theme.widget_mail_on)
        else
            widget:set_text("")
            mailicon:set_image(theme.widget_mail)
        end
    end
})
--]]

-- Volume popup
local VOLUME_ICON_W = dpi(10)
local VOLUME_LEVEL_W = dpi(32)
local VOLUME_BAR_W = dpi(160)
local VOLUME_SPACING = dpi(4)
local VOLUME_MARGIN = dpi(12)
local volume_popup = nil
local volume_popup_mode = nil
local updating_slider = false
local volume_widget_geo = nil

local function hide_volume_popup()
	if volume_popup then
		volume_popup.visible = false
		volume_popup = nil
		volume_popup_mode = nil
	end
end

local volume_hide_timer = gears.timer({
	timeout = 2,
	single_shot = true,
	callback = function()
		hide_volume_popup()
	end,
})

local arrow_size = dpi(8)
local bubble_shape = function(cr, width, height)
	gears.shape.infobubble(cr, width, height, dpi(6), arrow_size, width / 2 - arrow_size)
end

--- Builds a volume slider linked to the given channel. Also manages updating
--- the icon and label in response to changes.
---@param ch AudioHandle
---@param icon AwesomeWidget
---@param label AwesomeWidget
---@param color string
---@param glyph? fun(level: AudioLevel, muted: AudioMuted): string
---@return AwesomeWidget
local function build_channel_slider(ch, icon, label, color, glyph)
	local progress = wibox.widget({
		max_value = 100,
		value = ch.level,
		forced_height = dpi(4),
		forced_width = VOLUME_BAR_W,
		bar_shape = gears.shape.rounded_rect,
		color = ch.muted and palette.fg_2 or color,
		background_color = palette.bg_3,
		widget = wibox.widget.progressbar,
	})
	local slider = wibox.widget({
		minimum = 0,
		maximum = 100,
		value = ch.level,
		forced_height = dpi(16),
		forced_width = VOLUME_BAR_W,
		bar_shape = gears.shape.rounded_rect,
		bar_height = dpi(4),
		bar_color = "#00000000",
		handle_shape = gears.shape.circle,
		handle_color = ch.muted and palette.fg_2 or color,
		handle_width = dpi(12),
		widget = wibox.widget.slider,
	})
	slider:connect_signal("property::value", function()
		if updating_slider then
			return
		end
		progress.value = slider.value
		ch:set_perc(slider.value)
	end)

	-- Wrap the shared icon in a fresh container for the row.
	-- The mute-toggle button goes on the container, NOT on the shared icon widget,
	-- so the wibar segment's popup-open handler is left intact.
	local icon_container = wibox.container.background(icon)
	icon_container:buttons(awful.button({}, 1, function()
		ch:toggle_mute()
	end))

	ch:subscribe(function(level, muted)
		if glyph then
			icon:set_markup(markup.font(theme.font, glyph(level, muted)))
		end
		label:set_markup(markup.font(theme.font, string.format("%d%%", level)))
		updating_slider = true
		slider.value = level
		progress.value = level
		updating_slider = false
		progress.color = muted and palette.fg_2 or color
		slider.handle_color = muted and palette.fg_2 or color
	end)

	return wibox.widget({
		icon_container,
		{
			{
				progress,
				left = dpi(6),
				right = dpi(6),
				top = dpi(6),
				bottom = dpi(6),
				widget = wibox.container.margin,
			},
			slider,
			layout = wibox.layout.stack,
		},
		label,
		layout = wibox.layout.fixed.horizontal,
		spacing = VOLUME_SPACING,
	})
end

local volume_icon = wibox.widget({ forced_width = VOLUME_ICON_W, widget = wibox.widget.textbox })
local volume_level = wibox.widget({ forced_width = VOLUME_LEVEL_W, widget = wibox.widget.textbox })
theme.volume = audio.channel("Master")
local function volume_icon_glyph(level, muted)
	return muted and "󰖁" or (level < 30 and "󰕿" or level < 70 and "󰖀" or "󰕾")
end

local volume_slider = build_channel_slider(theme.volume, volume_icon, volume_level, palette.blue, volume_icon_glyph)

local volume_mic_icon = wibox.widget({ forced_width = VOLUME_ICON_W, widget = wibox.widget.textbox })
local volume_mic_level = wibox.widget({ forced_width = VOLUME_LEVEL_W, widget = wibox.widget.textbox })
theme.capture = audio.channel("Capture")
local function capture_icon_glyph(_, muted)
	return muted and "󰍭" or "󰍬"
end

local capture_slider =
	build_channel_slider(theme.capture, volume_mic_icon, volume_mic_level, palette.purple, capture_icon_glyph)

---@param mode "button"|"change"
local function show_volume_popup(mode)
	volume_popup_mode = mode
	if volume_popup then
		return
	end

	local s = awful.screen.focused()

	local rows = mode == "button"
			and wibox.widget({
				volume_slider,
				capture_slider,
				layout = wibox.layout.fixed.vertical,
				spacing = VOLUME_SPACING,
			})
		or volume_slider
	local content = wibox.container.margin(
		rows,
		VOLUME_MARGIN,
		VOLUME_MARGIN,
		mode == "button" and arrow_size + dpi(10) or dpi(10),
		dpi(10)
	)

	volume_popup = awful.popup({
		widget = content,
		bg = palette.bg_2,
		shape = mode == "button" and bubble_shape or gears.shape.rounded_rect,
		border_width = dpi(1),
		border_color = palette.bg_3,
		ontop = true,
		placement = function(popup)
			if mode == "button" and volume_widget_geo then
				awful.placement.next_to(popup, {
					preferred_positions = { "bottom" },
					preferred_anchors = { "middle" },
					geometry = volume_widget_geo,
					margins = { top = VOLUME_SPACING },
				})
			else
				awful.placement.top(popup, {
					margins = { top = dpi(24) },
					parent = s,
				})
			end
		end,
		visible = true,
	})
	volume_popup:connect_signal("mouse::enter", function()
		volume_hide_timer:stop()
	end)
	volume_popup:connect_signal("mouse::leave", function()
		volume_hide_timer:again()
	end)
	volume_hide_timer:again()
end

-- Suppress the popup on the very first (startup) poll; open it on subsequent changes.
local volume_output_initialized = false
theme.volume:subscribe(function(_, _)
	if not volume_output_initialized then
		volume_output_initialized = true
		return
	end
	if volume_popup then
		if volume_hide_timer.started then
			volume_hide_timer:again()
		end
	else
		show_volume_popup("change")
	end
end)

-- MPD
local musicplr = awful.util.terminal .. " -title Music -g 130x34-320+16 -e ncmpcpp"
local mpdicon = wibox.widget.imagebox(theme.widget_music)
mpdicon:buttons(my_table.join(
	awful.button({ modkey }, 1, function()
		awful.spawn.with_shell(musicplr)
	end),
	awful.button({}, 1, function()
		os.execute("mpc prev")
		theme.mpd.update()
	end),
	awful.button({}, 2, function()
		os.execute("mpc toggle")
		theme.mpd.update()
	end),
	awful.button({}, 3, function()
		os.execute("mpc next")
		theme.mpd.update()
	end)
))
theme.mpd = lain.widget.mpd({
	settings = function()
		---@diagnostic disable-next-line: undefined-global
		local mpd_now, widget = mpd_now, widget
		if mpd_now.state == "play" then
			local artist = mpd_now.artist
			local title = mpd_now.title
			mpdicon:set_image(theme.widget_music_on)
			widget:set_markup(markup.font(theme.font, markup(palette.orange, artist) .. " " .. title))
		elseif mpd_now.state == "pause" then
			widget:set_markup(markup.font(theme.font, " mpd paused "))
			mpdicon:set_image(theme.widget_music_pause)
		else
			widget:set_text("")
			mpdicon:set_image(theme.widget_music)
		end
	end,
})

-- MEM
local mem = lain.widget.mem({
	settings = function()
		---@diagnostic disable-next-line: undefined-global
		local mem_now = mem_now
		local usage = mem_now.used > 1024 and string.format("%.1fGB", mem_now.used / 1024) or mem_now.used .. "MB"
		widget:set_markup(markup.font(theme.font, " " .. usage))
	end,
})

-- CPU
local cpu = lain.widget.cpu({
	settings = function()
		---@diagnostic disable-next-line: undefined-global
		local cpu_now = cpu_now
		widget:set_markup(markup.font(theme.font, " " .. cpu_now.usage .. "%"))
	end,
})

--[[ Coretemp (lm_sensors, per core)
local tempwidget = awful.widget.watch({awful.util.shell, '-c', 'sensors | grep Core'}, 30,
function(widget, stdout)
    local temps = ""
    for line in stdout:gmatch("[^\r\n]+") do
        temps = temps .. line:match("+(%d+).*°C")  .. "° " -- in Celsius
    end
    widget:set_markup(markup.font(theme.font, " " .. temps))
end)
--]]
-- Coretemp (lain, average)
local temp = lain.widget.temp({
	settings = function()
		---@diagnostic disable-next-line: undefined-global
		local coretemp_now = coretemp_now
		widget:set_markup(markup.font(theme.font, " " .. coretemp_now .. "°C"))
	end,
})
--]]

--[[ / fs
theme.fs = lain.widget.fs({
    notification_preset = { fg = theme.fg_normal, bg = theme.bg_normal, font = "Terminus 10" },
    settings = function()
        local fsp = string.format(" %3.2f %s", fs_now["/"].free, fs_now["/"].units)
        widget:set_markup(markup.font(theme.font, fsp))
    end
})
]]

local function battery_icon(perc)
	if perc > 95 then
		return "󰁹"
	elseif perc > 85 then
		return "󰂂"
	elseif perc > 75 then
		return "󰂁"
	elseif perc > 65 then
		return "󰂀"
	elseif perc > 55 then
		return "󰁿"
	elseif perc > 45 then
		return "󰁾"
	elseif perc > 35 then
		return "󰁽"
	elseif perc > 25 then
		return "󰁼"
	elseif perc > 15 then
		return "󰁻"
	elseif perc > 5 then
		return "󰁺"
	else
		return "󰂎"
	end
end

-- Battery
local bat = lain.widget.bat({
	settings = function()
		---@diagnostic disable-next-line: undefined-global
		local bat_now = bat_now
		if bat_now.status and bat_now.status ~= "N/A" then
			if bat_now.ac_status == 1 then
				widget:set_markup(markup.font(theme.font, " AC"))
				return
			end
			widget:set_markup(markup.font(theme.font, battery_icon(bat_now.perc) .. " " .. bat_now.perc .. "%"))
		else
			widget:set_markup("󱧥 ...")
		end
	end,
})

-- Net
local neticon = wibox.widget.imagebox(theme.widget_net)
local net = lain.widget.net({
	settings = function()
		---@diagnostic disable-next-line: undefined-global
		local net_now = net_now
		widget:set_markup(markup.fontfg(theme.font, palette.white, net_now.received .. " ↓↑ " .. net_now.sent))
	end,
})

--[[ Brigtness
local brighticon = wibox.widget.imagebox(theme.widget_brightness)
-- If you use xbacklight, comment the line with "light -G" and uncomment the line bellow
local brightwidget = awful.widget.watch('xbacklight -get', 0.1,
    -- local brightwidget = awful.widget.watch('light -G', 0.1,
    ---@diagnostic disable-next-line: unused-local
    function(widget, stdout, stderr, exitreason, exitcode)
        local brightness_level = tonumber(string.format("%.0f", stdout))
        widget:set_markup(markup.font(theme.font, " " .. brightness_level .. "%"))
    end)
]]

function theme.gutter_start(cr, width, height, depth)
	local arrow_depth, offset = depth or height / 2, 0

	-- Avoid going out of the (potential) clip area
	if arrow_depth < 0 then
		width = width + 2 * arrow_depth
		offset = -arrow_depth
	end

	cr:move_to(offset, 0)
	cr:line_to(offset + width, 0)
	cr:line_to(offset + width - arrow_depth, height)
	cr:line_to(0, height)

	cr:close_path()
end

function theme.gutter_end(cr, width, height, depth)
	local arrow_depth, offset = depth or height / 2, 0

	-- Avoid going out of the (potential) clip area
	if arrow_depth < 0 then
		width = width + 2 * arrow_depth
		offset = -arrow_depth
	end

	cr:move_to(offset + arrow_depth, 0)
	cr:line_to(offset + width, 0)
	cr:line_to(offset + width, height)
	cr:line_to(offset, height)

	cr:close_path()
end

--- Parallelogram that uses the same angle logic as the powerline.
---@param cr CairoContext
---@param width number
---@param height number
function theme.slab(cr, width, height)
	return shape.parallelogram(cr, width, height, width - height / 2)
end

---@class Segment
---@field widget AwesomeWidget
---@field background? HexColor
---@field color? HexColor
---@field margin? integer
---@field callback? fun(widget: AwesomeWidget)

--- Expands a segment into a list of widgets and its powerline seperator.
---@param segment Segment
---@param bg_color HexColor
---@return AwesomeWidget[]
local function expand_segment(segment, bg_color, margin)
	local widget = segment.widget or segment
	local container = wibox.container.background(
		wibox.container.margin(widget, dpi(margin or 16), dpi(margin or 16)),
		gradient(bg_color, theme.wibox_height),
		function(cr, width, height)
			shape.powerline(cr, width, height, 0 - height / 2)
		end
	)
	if segment.color then
		container.fg = segment.color
	end
	if segment.callback then
		segment.callback(container)
	end
	return {
		wibox.widget({
			forced_width = 10,
			color = gradient(segment.color or bg_color, theme.wibox_height),
			widget = wibox.widget.separator,
			shape = function(cr, width, height)
				shape.powerline(cr, width + 2, height, 0 - height / 2)
			end,
		}),
		container,
	}
end

---@type Segment[]
local segments = {
	--[[
    {
        widget = wibox.container.margin(
            wibox.widget { mailicon, theme.mail and theme.mail.widget, layout = wibox.layout.align.horizontal }, dpi(4),
            dpi(7)),
    },
    ]]
	{
		widget = wibox.widget.systray(),
		background = palette.bg_3,
	},
	{
		widget = wibox.widget({ mpdicon, theme.mpd.widget, layout = wibox.layout.align.horizontal }),
	},
	{
		widget = task,
	},
	{
		widget = wibox.widget({ mem.widget, layout = wibox.layout.align.horizontal }),
		color = palette.orange,
	},
	{
		widget = wibox.widget({ cpu.widget, layout = wibox.layout.align.horizontal }),
		color = palette.green,
	},
	{
		widget = wibox.widget({ temp.widget, layout = wibox.layout.align.horizontal }),
		color = palette.purple,
	},
	--[[
    {
        widget = wibox.widget { theme.fs and theme.fs.widget, layout = wibox.layout.align.horizontal },
        color = palette.orange
    },
    ]]
	{
		widget = volume_icon,
		color = palette.yellow,
		callback = function(w)
			w:buttons(awful.button({}, 1, function()
				volume_widget_geo = mouse.current_widget_geometry
				if volume_popup and volume_popup_mode == "change" then
					hide_volume_popup()
				end
				if volume_popup then
					hide_volume_popup()
				else
					show_volume_popup("button")
				end
			end))
		end,
	},
	{
		widget = wibox.widget({ bat.widget, layout = wibox.layout.align.horizontal }),
		color = palette.cyan,
	},
	{
		widget = wibox.widget({ neticon, net.widget, layout = wibox.layout.align.horizontal }),
		background = palette.fg_2,
	},
	{
		widget = binclock,
		background = palette.bg_3,
	},
}

local function color_from_index(i)
	return i % 2 == 0 and palette.bg_2 or palette.bg
end

-- {{{ Alttab UI
do
	local cairo = require("lgi").cairo

	local LIST_WIDTH = dpi(260)
	local PREVIEW_WIDTH = dpi(480)
	local PREVIEW_HEIGHT = dpi(270)
	local ITEM_HEIGHT = dpi(40)
	local ICON_SIZE = dpi(24)
	local MINI_ICON_SIZE = dpi(64)
	local PADDING = dpi(8)

	local BG_COLOR = palette.bg_2 .. "CC"
	local SELECTED_BG_COLOR = palette.bg_3
	local SELECTED_FG_COLOR = palette.blue

	---@type table<AwesomeClient, CairoContext>  Cached ImageSurfaces keyed by client.
	local preview_cache = {}

	--- Capture a client's current content into the cache and return the image.
	--- Returns nil if the content is unavailable.
	---@param c AwesomeClient
	---@return CairoContext|nil
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

	---@param c AwesomeClient
	---@param index integer
	---@param selected boolean
	---@return AwesomeWidget
	local function make_item(c, index, selected)
		local item = wibox.widget({
			{
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
	---@return AwesomeWidget
	local function make_preview_inner(c)
		---@type CairoContext|nil
		local img = not c:isvisible() and preview_cache[c] or c:isvisible() and capture(c) or nil
		if not img then
			return wibox.widget({
				nil,
				{
					nil,
					{
						image = c.icon,
						resize = true,
						forced_width = MINI_ICON_SIZE,
						forced_height = MINI_ICON_SIZE,
						widget = wibox.widget.imagebox,
					},
					nil,
					expand = "none",
					layout = wibox.layout.align.horizontal,
				},
				nil,
				expand = "none",
				layout = wibox.layout.align.vertical,
			})
		else
			local iw = img:get_width()
			local ih = img:get_height()
			local scale = math.min(PREVIEW_WIDTH / iw, PREVIEW_HEIGHT / ih)
			return wibox.widget({
				{
					image = img,
					resize = true,
					forced_width = math.floor(iw * scale),
					forced_height = math.floor(ih * scale),
					widget = wibox.widget.imagebox,
				},
				halign = "center",
				valign = "center",
				forced_width = PREVIEW_WIDTH,
				forced_height = PREVIEW_HEIGHT,
				widget = wibox.container.place,
			})
		end
	end

	---@param c AwesomeClient
	local function set_preview(c)
		preview_bg.bg = palette.black .. "55"
		preview_bg.widget = make_preview_inner(c)
	end

	---@param clients AwesomeClient[]
	---@param index integer
	local function build_popup(clients, index)
		item_bgs = {}

		local list = wibox.widget({ layout = wibox.layout.fixed.vertical })
		for i, c in ipairs(clients) do
			local item = make_item(c, i, i == index)
			item_bgs[i] = item
			list:add(item)
		end

		preview_bg = wibox.widget({
			forced_width = PREVIEW_WIDTH,
			forced_height = PREVIEW_HEIGHT,
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
	theme.alttab = {
		show = function(clients, index)
			current_clients = clients
			current_index = index
			build_popup(clients, index)
		end,
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
		end,
		on_init = function(a)
			api = a
		end,
		on_unfocus = capture,
		on_untagged = capture,
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
end
-- }}}

function theme.at_screen_connect(s)
	-- Quake application
	s.quake = lain.util.quake({ app = awful.util.terminal })

	-- If wallpaper is a function, call it with the screen
	local wallpaper = theme.wallpaper
	if type(wallpaper) == "function" then
		wallpaper = wallpaper(s)
	end
	gears.wallpaper.maximized(wallpaper, s, true)

	---@type AwesomeWidget
	local powerline = {
		layout = wibox.layout.fixed.horizontal,
		spacing = -9,
	}

	-- Create an imagebox widget which will contains an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(my_table.join(
		awful.button({}, 1, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 2, function()
			awful.layout.set(awful.layout.layouts[1])
		end),
		awful.button({}, 3, function()
			awful.layout.inc(-1)
		end),
		awful.button({}, 4, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 5, function()
			awful.layout.inc(-1)
		end)
	))

	-- Add global widgets to this screen.
	for i, segment in ipairs(segments) do
		local this_color = segment.background or color_from_index(i)
		for _, x in ipairs(expand_segment(segment, this_color, segment.margin)) do
			table.insert(powerline, x)
		end
	end
	-- Add screen layout to this screen.
	table.insert(
		powerline,
		wibox.container.background(
			wibox.container.background(
				wibox.container.margin(s.mylayoutbox, dpi(8), dpi(0)),
				gradient(palette.red, theme.wibox_height),
				theme.gutter_end
			),
			gradient(segments[#segments].background or color_from_index(#segments), theme.wibox_height)
		)
	)

	-- Tags
	awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()
	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist({
		screen = s,
		filter = awful.widget.taglist.filter.all,
		style = {
			shape_border_width = dpi(2),
			shape_border_color = gradient(palette.bg, theme.wibox_height),
			shape = theme.slab,
		},
		buttons = awful.util.taglist_buttons,
		layout = {
			spacing = -dpi(10),
			layout = wibox.layout.fixed.horizontal,
		},
		widget_template = {
			{
				{
					{
						id = "text_role",
						widget = wibox.widget.textbox,
					},
					layout = wibox.layout.fixed.horizontal,
				},
				left = 14,
				right = 14,
				widget = wibox.container.margin,
			},
			id = "background_role",
			widget = wibox.container.background,
			-- Add support for hover colors and an index label
			---@diagnostic disable-next-line: unused-local
			create_callback = function(self, c3, index, objects) --luacheck: no unused args
				self:connect_signal("mouse::enter", function()
					if self.shape_border ~= palette.bg_3 then
						self.backup = self.bg
						self.has_backup = true
					end
					self.bg = palette.bg_3
				end)
				self:connect_signal("mouse::leave", function()
					if self.has_backup then
						self.bg = self.backup
					end
				end)
			end,
		},
	})

	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist({
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = awful.util.tasklist_buttons,
		style = {
			shape_border_width = dpi(1),
			shape_border_color = palette.bg_2,
			shape = shape.rounded_rect,
		},
		layout = {
			spacing = 8,
			layout = wibox.layout.flex.horizontal,
		},
		widget_template = {
			{
				{
					{
						{
							id = "icon_role",
							widget = wibox.widget.imagebox,
						},
						margins = 2,
						widget = wibox.container.margin,
					},
					{
						id = "text_role",
						widget = wibox.widget.textbox,
					},
					layout = wibox.layout.fixed.horizontal,
				},
				left = 10,
				right = 10,
				widget = wibox.container.margin,
			},
			id = "background_role",
			widget = wibox.container.background,
			---@diagnostic disable-next-line: unused-local
			create_callback = function(self, c3, index, objects) --luacheck: no unused args
				self:connect_signal("mouse::enter", function()
					self.backup = self.shape_border_color
					self.has_backup = true
					self.shape_border_color = lighten(self.shape_border_color, 30)
				end)
				self:connect_signal("mouse::leave", function()
					if self.has_backup then
						self.shape_border_color = self.backup
					end
				end)
			end,
		},
	})

	-- Create the wibox
	s.mywibox = awful.wibar({
		position = "top",
		screen = s,
		height = dpi(theme.wibox_height),
		bg = gradient(palette.bg, theme.wibox_height, 0.85),
		fg = theme.fg_normal,
	})

	local menu_button = wibox.container.margin(wibox.widget.imagebox(theme.awesome_icon), dpi(2), dpi(2))
	menu_button:buttons(my_table.join(
		awful.widget.button():buttons(),
		awful.button({}, 1, nil, function()
			awful.util.mymainmenu:toggle()
		end)
	))

	-- Add widgets to the wibox
	-- There is some weird nonsense with nested fixed layouts when the inner has
	-- negative spacing so we have to structure this a little oddly.
	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		{ -- Middle widget
			layout = wibox.layout.align.horizontal,
			{
				layout = wibox.layout.fixed.horizontal,
				wibox.container.background(menu_button, gradient(palette.red, theme.wibox_height)),
			},
			wibox.container.background( -- Left widget
				wibox.container.margin(s.mytaglist, dpi(0), dpi(12)),
				gradient(palette.red, theme.wibox_height),
				theme.gutter_start
			),
		},
		{ -- Middle widget
			layout = wibox.layout.align.horizontal,
			s.mypromptbox,
			wibox.container.margin(s.mytasklist, dpi(12), dpi(12), dpi(1), dpi(1)),
		},
		-- Right widget
		powerline,
	})
end

return theme
