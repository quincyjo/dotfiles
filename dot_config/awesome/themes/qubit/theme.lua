require("themes.qubit.types")

-- Awesome
local gears = require("gears")
local shape = gears.shape
local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local dpi = require("beautiful.xresources").apply_dpi

-- Third Party
local lain = require("lain")

-- Backend Modules
local audio = require("continuity.audio")
local media = require("continuity.media")
local bat = require("continuity.sysinfo.bat")
local temp = require("continuity.sysinfo.temp")
local cpu = require("continuity.sysinfo.cpu")
local mem = require("continuity.sysinfo.mem")
local net = require("continuity.sysinfo.net")
local backlight = require("continuity.backlight")
local app_icon = require("continuity.util.app_icon")

-- Theme
local palette = require("themes.qubit.palette")
local colors = require("themes.qubit.colors")
local media_widget = require("themes.qubit.media_widget")

--- Creates a vertical bevel gradient for the wibox.
---@param color HexColor The color of the gradient.
---@param height number The height of the gradient in pixels.
---@param opacity? Alpha An optional opacity between 0 and 1.
local function gradient(color, height, opacity)
	local alpha = opacity and string.format("%02x", opacity * 255) or ""
	return {
		type = "linear",
		from = { 0, 0 },
		to = { 0, dpi(height) },
		stops = {
			{ 0, colors.lighten(color, 0.3) .. alpha },
			{ 0.1, color .. alpha },
			{ 0.9, color .. alpha },
			{ 1, colors.lighten(color, -0.3) .. alpha },
		},
	}
end

---@param mb number
---@return string
local function format_megabytes(mb)
	if mb > 1024 then
		return string.format("%.1fGB", mb / 1024)
	else
		return string.format("%.1fMB", mb)
	end
end

---@param b number
---@return string
local function format_bytes(b)
	if b > 1024 then
		return format_megabytes(b / 1024)
	else
		return string.format("%.1f", b)
	end
end

--- Attach a notification for mouse interactions with the given widget.
---@param widget AwesomeWidget                       The widget to attach to.
---@param callback? fun(widget: NaughtyNotification) Callback with the notification.
---@param initial_args? table                        Initial arguments for the notification.
local function attach_notification_to(widget, callback, initial_args)
	local notification = nil
	widget:connect_signal("mouse::enter", function()
		if notification then
			return
		end
		local args = initial_args or {}
		args.timeout = args.timeout or 0
		args.screen = args.screen or mouse.screen
		notification = naughty.notification(args)
		if callback then
			callback(notification)
		end
	end)
	widget:connect_signal("mouse::leave", function()
		if notification then
			notification:destroy()
			notification = nil
		end
	end)
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
	taglist_bg_occupied = gradient(palette.red, dpi(14)),
	taglist_bg_empty = gradient(palette.red, dpi(14)),
	taglist_bg_urgent = palette.bg_3,
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
	useless_gap = 2,
	gap_single_client = false,
	bg_systray = palette.bg_3,
	menu_height = dpi(18),
	wibox_height = dpi(18),
	menu_width = dpi(160),
	notification_bg = palette.bg_2 .. "33",
	notification_border_color = palette.bg_3,
	notification_border_width = dpi(1),
	hotkeys_bg = palette.bg_2 .. "AA",
	hotkeys_border_color = palette.bg_3,
	hotkeys_modifiers_fg = palette.fg_2,
	hotkeys_fg = palette.fg,
	hotkeys_label_fg = palette.black,
	hotkeys_font = "Terminus Bold 9",
	hotkeys_description_font = "Terminus 9",
	popup_bg = palette.bg_2 .. "AA",
	popup_border_color = palette.bg_3,
	popup_border_width = dpi(2),
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

	-- Checkhealth.
	checkhealth_bg = palette.bg_2,
	checkhealth_logs_font = "Terminus 10",
	checkhealth_logs_border_color = palette.bg_3,
}

-- Minute aligned clock.
local clock = wibox.widget({
	font = theme.font,
	widget = wibox.widget.textbox,
})
awful.spawn.easy_async("date +'%a %d %b %R'", function(stdout)
	clock:set_markup(stdout)
end)
awful.spawn.easy_async("date +'%S'", function(stdout)
	gears.timer({
		timeout = 60 - (tonumber(stdout) or 0),
		oneshot = true,
		autostart = true,
		callback = function()
			awful.widget.watch("date +'%a %d %b %R'", 60, function(widget, date)
				widget:set_markup(date)
			end, clock)
		end,
	})
end)

-- Calendar
theme.cal = lain.widget.cal({
	--cal = "cal --color=always",
	attach_to = { clock },
	notification_preset = {
		font = theme.font,
		fg = theme.fg_normal,
		bg = theme.popup_bg,
		border_color = theme.popup_border_color,
	},
})

-- Taskwarrior
local task = wibox.widget.imagebox(theme.widget_task)
lain.widget.contrib.task.attach(task, {
	-- do not colorize output
	show_cmd = "task | sed -r 's/\\x1B\\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g'",
})
task:buttons(gears.table.join(awful.button({}, 1, lain.widget.contrib.task.prompt)))

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
local volume_notification = nil
local volume_popup_mode = nil
local updating_slider = false
local volume_widget_geo = nil

---@type table<string, MediaWidgetHandle>
local media_widget_cache = {}

--- Get the media widget for a source. If one doesn't exist, make one and cache
--- it. Otherwise, returns the cached widget and starts it.
---@param source MediaSource
---@return MediaWidgetHandle
local function get_media_wiget(source)
	local handle
	if media_widget_cache[source.id] then
		handle = media_widget_cache[source.id]
		handle.start()
	else
		handle = media_widget(source, {
			width = VOLUME_ICON_W + VOLUME_LEVEL_W + VOLUME_BAR_W,
			height = dpi(100),
		})
		media_widget_cache[source.id] = handle
		source:on_removed(function(source_id)
			handle.stop()
			media_widget_cache[source_id] = nil
		end)
	end
	return handle
end

local function hide_volume_popup()
	if volume_notification then
		volume_notification:destroy()
	end
	if volume_popup then
		volume_popup.visible = false
		volume_popup = nil
		if volume_popup_mode == "button" then
			media.enable_notifications()
			for _, widget in pairs(media_widget_cache) do
				widget.stop()
			end
		end
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
---@param glyph? fun(state: AudioState): string
---@return AwesomeWidget
local function build_channel_slider(ch, icon, label, color, glyph)
	local slider = wibox.widget({
		minimum = 0,
		maximum = 100,
		value = ch.state.level,
		forced_height = dpi(16),
		forced_width = VOLUME_BAR_W,
		bar_shape = gears.shape.rounded_rect,
		bar_height = dpi(4),
		bar_color = palette.bg_3,
		bar_active_color = ch.state.muted and palette.fg_2 or color,
		handle_shape = gears.shape.circle,
		handle_color = ch.state.muted and palette.fg_2 or color,
		handle_width = dpi(10),
		widget = wibox.widget.slider,
	})
	local set_debounce_timer
	slider:connect_signal("property::value", function()
		if updating_slider then
			return
		end
		-- Short debounce to avoid thrashing updates
		if not set_debounce_timer then
			set_debounce_timer = gears.timer({
				timeout = 0.05,
				single_shot = true,
				autostart = true,
				callback = function()
					set_debounce_timer = nil
					ch:set_perc(slider.value)
				end,
			})
		end
	end)

	-- Wrap the shared icon in a fresh container for the row.
	-- The mute-toggle button goes on the container, NOT on the shared icon widget,
	-- so the wibar segment's popup-open handler is left intact.
	local icon_container = wibox.container.background(icon)
	icon_container:buttons(awful.button({}, 1, function()
		ch:toggle_mute()
	end))

	---@param state AudioState
	local function update(state)
		if glyph then
			icon:set_text(glyph(state))
		end
		label:set_text(string.format("%3d%%", state.level))
		updating_slider = true
		slider.value = state.level
		updating_slider = false
		slider.bar_active_color = state.muted and palette.fg_2 or color
		slider.handle_color = state.muted and palette.fg_2 or color
	end

	ch:subscribe(update)
	ch:on_ready(update)

	return wibox.widget({
		icon_container,
		slider,
		label,
		layout = wibox.layout.fixed.horizontal,
		spacing = VOLUME_SPACING,
	})
end

local volume = audio.Volume
local volume_icon = wibox.widget({ font = theme.font, forced_width = VOLUME_ICON_W, widget = wibox.widget.textbox })
local volume_level = wibox.widget({ font = theme.font, forced_width = VOLUME_LEVEL_W, widget = wibox.widget.textbox })
local function volume_icon_glyph(state)
	if state.port_type == "headset" or state.port_type == "headphones" then
		return state.connection == "bluetooth" and "󰥰" or state.muted and "󰟎" or "󰋋"
	end
	return state.muted and "󰖁" or (state.level < 30 and "󰕿" or state.level < 70 and "󰖀" or "󰕾")
end
local volume_slider = build_channel_slider(volume, volume_icon, volume_level, palette.blue, volume_icon_glyph)

local capture = audio.Capture
local volume_mic_icon = wibox.widget({ font = theme.font, forced_width = VOLUME_ICON_W, widget = wibox.widget.textbox })
local volume_mic_level =
	wibox.widget({ font = theme.font, forced_width = VOLUME_LEVEL_W, widget = wibox.widget.textbox })
local function capture_icon_glyph(state)
	return state.muted and "󰍭" or "󰍬"
end
local capture_slider =
	build_channel_slider(capture, volume_mic_icon, volume_mic_level, palette.purple, capture_icon_glyph)

do
	-- NOTE: This this build around steps not percent, so requires either the
	-- acpilight or sysfs backends.
	local notification
	local is_updating = false
	local slider = wibox.widget({
		minimum = 0,
		maximum = (backlight.primary_display.steps or 1) - 1,
		value = backlight.primary_display.state.raw or 0,
		forced_height = dpi(16),
		forced_width = VOLUME_BAR_W,
		bar_shape = gears.shape.rounded_rect,
		bar_height = dpi(4),
		bar_color = palette.bg_3,
		bar_active_color = palette.yellow,
		handle_shape = gears.shape.circle,
		handle_color = palette.yellow,
		handle_width = dpi(10),
		widget = wibox.widget.slider,
	})
	local percent_widget = wibox.widget({
		font = theme.font,
		text = backlight.primary_display.state.brightness,
		forced_width = VOLUME_LEVEL_W,
		widget = wibox.widget.textbox,
	})
	local widget = wibox.widget({
		{
			{
				{
					text = "󰃠",
					font = theme.font,
					-- Icon is wide so we offset with reducing left margin.
					forced_width = VOLUME_ICON_W + dpi(3),
					widget = wibox.widget.textbox,
				},
				slider,
				percent_widget,
				spacing = VOLUME_SPACING,
				layout = wibox.layout.fixed.horizontal,
			},
			left = VOLUME_MARGIN - dpi(3),
			right = VOLUME_MARGIN,
			top = dpi(10),
			bottom = dpi(10),
			widget = wibox.container.margin,
		},
		bg = palette.bg_2,
		widget = wibox.container.background,
	})

	local function update(state)
		is_updating = true
		slider.value = state.raw or 0
		is_updating = false
	end

	slider:connect_signal("property::value", function()
		-- NOTE: acpilight has a bug in percent calculation, so we do it
		-- manually for nicer display.
		local percent = slider.value == slider.maximum and 100
			or math.floor(slider.value / (slider.maximum + 1) * 100 + 0.5)
		percent_widget:set_markup(string.format("%3d%%", percent))
		if is_updating then
			return
		end
		local set_debounce_timer
		if not set_debounce_timer then
			set_debounce_timer = gears.timer({
				timeout = 0.05,
				single_shot = true,
				autostart = true,
				callback = function()
					set_debounce_timer = nil
					backlight.primary_display:set(slider.value)
				end,
			})
		end
	end)
	widget:connect_signal("mouse::enter", function()
		if notification then
			notification:reset_timeout(0)
		end
	end)
	widget:connect_signal("mouse::leave", function()
		if notification then
			notification:reset_timeout(2)
		end
	end)

	backlight.primary_display:on_ready(function(state)
		slider.maximum = (backlight.primary_display.steps or 2) - 1
		update(state)
	end)
	backlight.primary_display:subscribe(update)
	backlight.primary_display:on_control(function(_)
		if notification then
			notification:reset_timeout()
		else
			notification = naughty.notification({
				timeout = 2,
				resident = true,
				position = "top_middle",
				widget_template = widget,
			})
			notification:connect_signal("destroyed", function()
				notification = nil
			end)
		end
	end)
end

---@param mode "button"|"change"
local function show_volume_popup(mode)
	volume_popup_mode = mode
	if mode == "button" and volume_popup then
		return
	elseif mode == "change" and volume_notification then
		volume_notification:reset_timeout()
		return
	end

	local s = awful.screen.focused()

	if mode == "change" then
		local content = wibox.widget({
			{
				volume_slider,
				top = dpi(10),
				bottom = dpi(10),
				left = VOLUME_MARGIN,
				right = VOLUME_MARGIN,
				widget = wibox.container.margin,
			},
			bg = palette.bg_2,
			widget = wibox.container.background,
		})
		volume_notification = naughty.notification({
			timeout = 2,
			resident = true,
			position = "top_middle",
			screen = s,
			widget_template = content,
		})
		volume_notification:connect_signal("destroyed", function()
			volume_notification = nil
		end)
		content:connect_signal("mouse::enter", function()
			if volume_notification then
				volume_notification:reset_timeout(0)
			end
		end)
		content:connect_signal("mouse::leave", function()
			if volume_notification then
				volume_notification:reset_timeout(2)
			end
		end)
		return
	end

	media.disable_notifications()
	media.destroy_all_notifications()

	local rows = {
		volume_slider,
		capture_slider,
		layout = wibox.layout.fixed.vertical,
		spacing = VOLUME_SPACING,
	}
	for _, input in ipairs(audio.inputs.all()) do
		local icon_widget = wibox.widget({
			resize = true,
			forced_width = VOLUME_ICON_W,
			forced_height = VOLUME_ICON_W,
			widget = wibox.widget.imagebox,
		})
		if input.icon_name then
			app_icon.by_icon_name(input.icon_name, function(icon_path)
				icon_widget.image = icon_path
			end)
		elseif input.app_name then
			app_icon.by_app_name(input.app_name, function(icon_path)
				icon_widget.image = icon_path
			end)
		end
		local slider = wibox.widget({
			minimum = 0,
			maximum = 100,
			value = input.state.level,
			forced_height = dpi(16),
			forced_width = VOLUME_BAR_W,
			bar_shape = gears.shape.rounded_rect,
			bar_height = dpi(4),
			bar_color = palette.bg_3,
			bar_active_color = input.state.muted and palette.fg_2 or palette.green,
			handle_shape = gears.shape.circle,
			handle_color = input.state.muted and palette.fg_2 or palette.green,
			handle_width = dpi(10),
			widget = wibox.widget.slider,
		})
		local set_debounce_timer
		slider:connect_signal("property::value", function()
			if updating_slider then
				return
			end
			-- Short debounce to avoid thrashing updates
			if not set_debounce_timer then
				set_debounce_timer = gears.timer({
					timeout = 0.05,
					single_shot = true,
					autostart = true,
					callback = function()
						set_debounce_timer = nil
						input:set_perc(slider.value)
					end,
				})
			end
		end)

		local level_widget = wibox.widget({
			text = string.format("%3d%%", input.state.level),
			font = theme.font,
			widget = wibox.widget.textbox,
		})

		icon_widget:buttons(awful.button({}, 1, function()
			input:toggle_mute()
		end))

		---@param state SinkInputState
		local function update(state)
			level_widget:set_markup(string.format("%3d%%", state.level))
			updating_slider = true
			slider.value = state.level
			updating_slider = false
			slider.bar_active_color = state.muted and palette.fg_2 or palette.green
			slider.handle_color = state.muted and palette.fg_2 or palette.green
		end

		input:subscribe(update)

		rows[#rows + 1] = {
			icon_widget,
			slider,
			level_widget,
			spacing = VOLUME_SPACING,
			layout = wibox.layout.fixed.horizontal,
		}
	end
	for _, source in pairs(media.sources.all()) do
		if source:active() then
			local widget_handle = get_media_wiget(source)
			rows[#rows + 1] = {
				widget_handle.widget,
				shape = gears.shape.rounded_rect,
				widget = wibox.container.background,
			}
		end
	end

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
		border_color = theme.popup_border_color,
		ontop = true,
		placement = function(popup)
			if volume_widget_geo then
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

volume:on_control(function(_)
	if volume_popup then
		if volume_hide_timer.started then
			volume_hide_timer:again()
		end
	else
		show_volume_popup("change")
	end
end)

-- Mem
local mem_widget = wibox.widget({
	text = " …",
	font = theme.font,
	widget = wibox.widget.textbox,
})
mem:subscribe(function(state)
	mem_widget:set_markup(" " .. format_megabytes(state.used))
end)
attach_notification_to(mem_widget, function(notification)
	notification:connect_signal(
		"destroyed",
		mem:subscribe(function(state)
			notification.title = string.format("Memory (%02.1f%%)", state.perc)
			notification.message = table.concat({
				string.format("%s / %s", format_megabytes(state.used), format_megabytes(state.total)),
				string.format("Free: %s", format_megabytes(state.free)),
				string.format("Buffers: %s", format_megabytes(state.buffers)),
				string.format("Cached: %s", format_megabytes(state.cached)),
				string.format("Swap: %s / %s", format_megabytes(state.swap_used), format_megabytes(state.swap_total)),
			}, "\n")
		end)
	)
end)
--]]

-- CPU
local cpu_widget = wibox.widget({
	text = " …",
	font = theme.font,
	widget = wibox.widget.textbox,
})
cpu:subscribe(function(state)
	cpu_widget:set_markup(string.format(" %0.f%%", state.usage))
end)
attach_notification_to(cpu_widget, function(notification)
	notification:connect_signal(
		"destroyed",
		cpu:subscribe(function(state)
			local lines = {}
			for k, v in pairs(state) do
				if type(v) == "number" then
					lines[#lines + 1] = string.format("%s: %2.f%%", k, v)
				end
			end
			for i, core in ipairs(state.cores) do
				lines[#lines + 1] = string.format("Core %d: %2.f%%", i - 1, core.usage)
			end
			notification.message = table.concat(lines, "\n")
		end)
	)
end)
--]]

-- Coretemp
local temp_widget = wibox.widget({
	text = " …",
	font = theme.font,
	widget = wibox.widget.textbox,
})
temp:subscribe(function(state)
	temp_widget:set_markup(string.format(" %0.f°C", state.avg))
end)
attach_notification_to(temp_widget, function(notification)
	notification:connect_signal(
		"destroyed",
		temp:subscribe(function(state)
			local lines = {}
			for k, v in pairs(state.zones) do
				if type(v) == "number" then
					lines[#lines + 1] = string.format("%s: %0.1f°C", k:match("thermal_zone%d+"), v)
				end
			end
			notification.title = string.format("Temp (%0.f°C)", state.avg)
			notification.message = table.concat(lines, "\n")
		end)
	)
end)

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

---@param seconds integer
---@return string
local function format_time(seconds)
	local minutes = math.floor(seconds / 60)
	local hours = math.floor(minutes / 60 + 0.5)
	if hours >= 3 then
		return string.format("%d hr", hours)
	end
	if hours == 0 then
		return string.format("%d min", minutes)
	end
	return string.format("%d:%02d", hours, minutes % 60)
end

-- Battery
local battery_widget = wibox.widget({
	text = "󱧥 …",
	font = theme.font,
	widget = wibox.widget.textbox,
})
bat:subscribe(function(state)
	if state.ac_online then
		local markup = " AC"
		if state.status == bat.BatteryStatus.Charging and not state.charge_controlled then
			markup = string.format("%s (%s)", markup, format_time(bat.time_until_full() or 0))
		end
		battery_widget:set_markup(markup)
	else
		battery_widget:set_markup(
			string.format("%s %d%% (%s)", battery_icon(state.perc), state.perc, format_time(bat.time_remaining() or 0))
		)
	end
end)
attach_notification_to(battery_widget, function(notification)
	notification:connect_signal(
		"destroyed",
		bat:subscribe(function(state)
			notification.title = string.format("%s%% (%s)", state.perc, state.status)
			local lines = {}
			if state.status == bat.BatteryStatus.Charging then
				lines[#lines + 1] = format_time(bat.time_until_full() or 0) .. " until full"
				if state.charge_controlled then
					lines[#lines + 1] = "󱞜 Charge controlled"
				end
			elseif state.status == bat.BatteryStatus.Discharging then
				lines[#lines + 1] = format_time(bat.time_remaining() or 0) .. " remaining"
			end
			lines[#lines + 1] = "AC: " .. (state.ac_online and "Online" or "Offline")
			if state.capacity then
				lines[#lines + 1] = string.format("Health: %d%%", state.capacity)
			end
			notification.message = table.concat(lines, "\n")
		end)
	)
end)

-- Net
local net_widget = wibox.widget({
	text = "󱛄 0.0 ↓↑ 0.0",
	font = theme.font,
	widget = wibox.widget.textbox,
})
net:subscribe(function(state)
	local icon = "󰤮"
	for _, c in pairs(state.devices) do
		if c.state == net.DeviceState.Up and c.carrier then
			if c.wifi then
				icon = c.signal == nil and "󰖩"
					or c.signal >= -50 and "󰤨"
					or c.signal >= -67 and "󰤥"
					or c.signal >= -73 and "󰤢"
					or c.signal >= -80 and "󰤟"
					or "󰤫"
			else
				icon = "󰈀"
			end
			break
		end
	end
	net_widget:set_markup(
		string.format("%s %s ↓↑ %s", icon, format_bytes(state.rx_rate), format_bytes(state.tx_rate))
	)
end)
attach_notification_to(net_widget, function(notification)
	notification:connect_signal(
		"destroyed",
		net:subscribe(function(state)
			local carrier
			for _, c in pairs(state.devices) do
				if c.state == net.DeviceState.Up and c.carrier then
					carrier = c
					break
				end
			end
			notification.message = table.concat({
				carrier and carrier.wifi and ("Signal: " .. (carrier.signal and (carrier.signal .. "dBm") or "N/A"))
					or "LAN",
				string.format("RX: %s/s", format_bytes(state.rx_rate)),
				string.format("TX: %s/s", format_bytes(state.tx_rate)),
				string.format("RX: %s", format_bytes(carrier.rx_bytes)),
				string.format("TX: %s", format_bytes(carrier.tx_bytes)),
			}, "\n")
		end)
	)
end, { title = "Network" })

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
---@field widget AwesomeWidget                 The widget to display.
---@field background? HexColor                 Forced background color of the segment.
---@field color? HexColor                      Forced foreground color of the segment.
---@field callback? fun(widget: AwesomeWidget) Callback to mutate the resulting widget, eg, add buttons.

--- Expands a segment into a list of widgets and its powerline seperator.
---@param segment Segment|AwesomeWidget
---@param bg_color HexColor
---@return AwesomeWidget[]
local function expand_segment(segment, bg_color)
	local widget = segment.widget or segment
	local container = wibox.container.background(
		wibox.container.margin(widget, dpi(16), dpi(16)),
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
	{
		widget = wibox.widget({ net_widget, layout = wibox.layout.align.horizontal }),
		background = palette.fg_2,
	},
	{
		widget = wibox.widget.systray(),
		background = palette.bg_3,
	},
	{
		widget = task,
	},
	{
		widget = wibox.widget({ mem_widget, layout = wibox.layout.align.horizontal }),
		color = palette.orange,
	},
	{
		widget = wibox.widget({ cpu_widget, layout = wibox.layout.align.horizontal }),
		color = palette.green,
	},
	{
		widget = wibox.widget({ temp_widget, layout = wibox.layout.align.horizontal }),
		color = palette.purple,
	},
	{
		widget = volume_icon,
		color = palette.yellow,
		callback = function(w)
			w:buttons(awful.button({}, 1, function()
				volume_widget_geo = mouse.current_widget_geometry
				if (volume_popup or volume_notification) and volume_popup_mode == "change" then
					hide_volume_popup()
				end
				if volume_popup then
					hide_volume_popup()
				else
					show_volume_popup("button")
					volume_hide_timer:stop()
				end
			end))
			w:connect_signal("mouse::leave", function()
				volume_hide_timer:again()
			end)
		end,
	},
	{
		widget = wibox.widget({ battery_widget, layout = wibox.layout.align.horizontal }),
		color = palette.cyan,
	},
	{
		widget = clock,
		background = palette.bg_3,
	},
}

local function color_from_index(i)
	return i % 2 == 0 and palette.bg_2 or palette.bg
end

function theme.at_screen_connect(s)
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
	s.mylayoutbox:buttons(gears.table.join(
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
		for _, x in ipairs(expand_segment(segment, this_color)) do
			powerline[#powerline + 1] = x
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
			shape = theme.slab,
		},
		buttons = awful.util.taglist_buttons,
		layout = {
			spacing = -dpi(5),
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
				left = 12,
				right = 12,
				widget = wibox.container.margin,
			},
			id = "background_role",
			widget = wibox.container.background,
			-- Add support for hover colors and an index label
			create_callback = function(self, _, _, _)
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
					self.shape_border_color = colors.lighten(self.shape_border_color, 30)
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
	menu_button:buttons(awful.button({}, 1, nil, function()
		awful.util.mymainmenu:toggle()
	end))

	-- Add widgets to the wibox
	-- There is some weird nonsense with nested fixed layouts when the inner has
	-- negative spacing so we have to structure this a little oddly.
	s.mywibox:setup({
		{ -- Left widget
			{
				layout = wibox.layout.fixed.horizontal,
				wibox.container.background(menu_button, gradient(palette.red, theme.wibox_height)),
			},
			wibox.container.background( -- Left widget
				wibox.container.margin(
					wibox.container.background(
						wibox.container.margin(s.mytaglist, dpi(3), dpi(3), dpi(2), dpi(2)),
						gradient(palette.bg, theme.wibox_height),
						theme.slab
					),
					dpi(0),
					dpi(12)
				),
				gradient(palette.red, theme.wibox_height),
				theme.gutter_start
			),
			layout = wibox.layout.align.horizontal,
		},
		{ -- Middle widget
			s.mypromptbox,
			wibox.container.margin(s.mytasklist, dpi(12), dpi(12), dpi(1), dpi(1)),
			layout = wibox.layout.align.horizontal,
		},
		-- Right widget
		powerline,
		layout = wibox.layout.align.horizontal,
	})
end

return theme
