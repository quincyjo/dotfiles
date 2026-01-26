local gears    = require("gears")
local shape    = gears.shape
local lain     = require("lain")
local awful    = require("awful")
local wibox    = require("wibox")
local dpi      = require("beautiful.xresources").apply_dpi

local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility

local palette  = {
    black = '#0a0909',
    white = '#e4e2e1',
    bg = '#1c1b1a',
    bg_2 = '#252121',
    bg_3 = '#464442',
    fg = '#d7d4d2',
    fg_2 = '#656260',
    pink = '#d3729c',
    red = '#d3426c',
    green = '#8aac54',
    yellow = '#c3a22c',
    blue = '#51a5c5',
    cyan = '#62a7a3',
    purple = '#b69bd3',
    orange = '#e3826c',
}

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
    return string.format('#%02x%02x%02x', rgb.r, rgb.g, rgb.b)
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
    local alpha = opacity and string.format('%02x', opacity * 255) or ''
    return {
        type  = "linear",
        from  = { 0, 0 },
        to    = { 0, dpi(height) },
        stops = {
            { 0,   lighten(color, 0.3) .. alpha },
            { 0.1, color .. alpha },
            { 0.9, color .. alpha },
            { 1,   lighten(color, -0.3) .. alpha },
        },
    }
end

local dir      = os.getenv("HOME") .. "/.config/awesome/themes/qubit"
local theme    = {
    wallpaper                                 = dir .. "/wall.png",
    -- font                                      = "MesloLGS NF 10",
    font                                      = "Hack Nerd Font 10",
    fg_normal                                 = palette.white,
    fg_focus                                  = palette.yellow,
    fg_urgent                                 = palette.red,
    bg_focus                                  = palette.bg_2,
    bg_normal                                 = palette.bg,
    bg_urgent                                 = palette.bg_3,
    taglist_fg_focus                          = palette.blue,
    taglist_bg_focus                          = palette.black,
    -- taglist_shape_border_color_focus          = palette.red,
    tasklist_fg_normal                        = palette.fg_2,
    tasklist_bg_normal                        = palette.bg,
    tasklist_fg_focus                         = palette.blue,
    tasklist_bg_focus                         = palette.bg_2,
    tasklist_shape_border_color_focus         = palette.bg_3,
    border_width                              = dpi(2),
    border_normal                             = palette.bg_3,
    border_focus                              = palette.yellow,
    border_marked                             = palette.pink,
    border_urgent                             = palette.red,
    titlebar_bg_focus                         = palette.bg,
    titlebar_bg_normal                        = palette.bg_2,
    titlebar_fg_focus                         = palette.yellow,
    titlebar_fg_normal                        = palette.purple,
    menu_height                               = dpi(18),
    wibox_height                              = dpi(18),
    menu_width                                = dpi(160),
    menu_submenu_icon                         = dir .. "/icons/submenu.png",
    awesome_icon                              = dir .. "/icons/awesome.png",
    awesome_icon_2                            = dir .. "/icons/awesome_w.png",
    taglist_squares_sel                       = dir .. "/icons/square_sel.png",
    taglist_squares_unsel                     = dir .. "/icons/square_unsel.png",
    layout_tile                               = dir .. "/icons/tile.png",
    layout_tileleft                           = dir .. "/icons/tileleft.png",
    layout_tilebottom                         = dir .. "/icons/tilebottom.png",
    layout_tiletop                            = dir .. "/icons/tiletop.png",
    layout_fairv                              = dir .. "/icons/fairv.png",
    layout_fairh                              = dir .. "/icons/fairh.png",
    layout_spiral                             = dir .. "/icons/spiral.png",
    layout_dwindle                            = dir .. "/icons/dwindle.png",
    layout_max                                = dir .. "/icons/max.png",
    layout_fullscreen                         = dir .. "/icons/fullscreen.png",
    layout_magnifier                          = dir .. "/icons/magnifier.png",
    layout_floating                           = dir .. "/icons/floating.png",
    widget_ac                                 = dir .. "/icons/ac.png",
    widget_battery                            = dir .. "/icons/battery.png",
    widget_battery_low                        = dir .. "/icons/battery_low.png",
    widget_battery_empty                      = dir .. "/icons/battery_empty.png",
    widget_brightness                         = dir .. "/icons/brightness.png",
    widget_mem                                = dir .. "/icons/mem.png",
    widget_cpu                                = dir .. "/icons/cpu.png",
    widget_temp                               = dir .. "/icons/temp.png",
    widget_net                                = dir .. "/icons/net.png",
    widget_hdd                                = dir .. "/icons/hdd.png",
    widget_music                              = dir .. "/icons/note.png",
    widget_music_on                           = dir .. "/icons/note_on.png",
    widget_music_pause                        = dir .. "/icons/pause.png",
    widget_music_stop                         = dir .. "/icons/stop.png",
    widget_vol                                = dir .. "/icons/vol.png",
    widget_vol_low                            = dir .. "/icons/vol_low.png",
    widget_vol_no                             = dir .. "/icons/vol_no.png",
    widget_vol_mute                           = dir .. "/icons/vol_mute.png",
    widget_mail                               = dir .. "/icons/mail.png",
    widget_mail_on                            = dir .. "/icons/mail_on.png",
    widget_task                               = dir .. "/icons/task.png",
    widget_scissors                           = dir .. "/icons/scissors.png",
    tasklist_plain_task_name                  = true,
    tasklist_disable_icon                     = false,
    useless_gap                               = 2,
    titlebar_close_button_focus               = dir .. "/icons/titlebar/close_focus.png",
    titlebar_close_button_normal              = dir .. "/icons/titlebar/close_normal.png",
    titlebar_ontop_button_focus_active        = dir .. "/icons/titlebar/ontop_focus_active.png",
    titlebar_ontop_button_normal_active       = dir .. "/icons/titlebar/ontop_normal_active.png",
    titlebar_ontop_button_focus_inactive      = dir .. "/icons/titlebar/ontop_focus_inactive.png",
    titlebar_ontop_button_normal_inactive     = dir .. "/icons/titlebar/ontop_normal_inactive.png",
    titlebar_sticky_button_focus_active       = dir .. "/icons/titlebar/sticky_focus_active.png",
    titlebar_sticky_button_normal_active      = dir .. "/icons/titlebar/sticky_normal_active.png",
    titlebar_sticky_button_focus_inactive     = dir .. "/icons/titlebar/sticky_focus_inactive.png",
    titlebar_sticky_button_normal_inactive    = dir .. "/icons/titlebar/sticky_normal_inactive.png",
    titlebar_floating_button_focus_active     = dir .. "/icons/titlebar/floating_focus_active.png",
    titlebar_floating_button_normal_active    = dir .. "/icons/titlebar/floating_normal_active.png",
    titlebar_floating_button_focus_inactive   = dir .. "/icons/titlebar/floating_focus_inactive.png",
    titlebar_floating_button_normal_inactive  = dir .. "/icons/titlebar/floating_normal_inactive.png",
    titlebar_maximized_button_focus_active    = dir .. "/icons/titlebar/maximized_focus_active.png",
    titlebar_maximized_button_normal_active   = dir .. "/icons/titlebar/maximized_normal_active.png",
    titlebar_maximized_button_focus_inactive  = dir .. "/icons/titlebar/maximized_focus_inactive.png",
    titlebar_maximized_button_normal_inactive = dir .. "/icons/titlebar/maximized_normal_inactive.png",
}

local markup   = lain.util.markup

local binclock = awful.widget.watch(
    "date +'%a %d %b %R'", 60,
    function(widget, stdout)
        widget:set_markup(markup.font(theme.font, stdout))
    end
)

-- Calendar
theme.cal      = lain.widget.cal({
    --cal = "cal --color=always",
    attach_to = { binclock },
    notification_preset = {
        font = "Terminus 10",
        fg   = theme.fg_normal,
        bg   = theme.bg_normal
    }
})

-- Taskwarrior
local task     = wibox.widget.imagebox(theme.widget_task)
lain.widget.contrib.task.attach(task, {
    -- do not colorize output
    show_cmd = "task | sed -r 's/\\x1B\\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g'"
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

-- ALSA volume
theme.volume = lain.widget.alsabar({
    --togglechannel = "IEC958,3",
    notification_preset = { font = "Terminus 10", fg = theme.fg_normal },
})

-- MPD
local musicplr = awful.util.terminal .. " -title Music -g 130x34-320+16 -e ncmpcpp"
local mpdicon = wibox.widget.imagebox(theme.widget_music)
mpdicon:buttons(my_table.join(
    awful.button({ modkey }, 1, function() awful.spawn.with_shell(musicplr) end),
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
    end)))
theme.mpd = lain.widget.mpd({
    settings = function()
        if mpd_now.state == "play" then
            artist = mpd_now.artist
            title  = mpd_now.title
            mpdicon:set_image(theme.widget_music_on)
            widget:set_markup(markup.font(theme.font, markup(palette.orange, artist) .. " " .. title))
        elseif mpd_now.state == "pause" then
            widget:set_markup(markup.font(theme.font, " mpd paused "))
            mpdicon:set_image(theme.widget_music_pause)
        else
            widget:set_text("")
            mpdicon:set_image(theme.widget_music)
        end
    end
})

-- MEM
local mem = lain.widget.mem({
    settings = function()
        widget:set_markup(markup.font(theme.font, ' ' .. mem_now.used .. "MB"))
    end
})

-- CPU
local cpu = lain.widget.cpu({
    settings = function()
        widget:set_markup(markup.font(theme.font, ' ' .. cpu_now.usage .. "%"))
    end
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
        widget:set_markup(markup.font(theme.font, ' ' .. coretemp_now .. '°C'))
    end
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
        return '󰁹'
    elseif perc > 85 then
        return '󰂂'
    elseif perc > 75 then
        return '󰂁'
    elseif perc > 65 then
        return '󰂀'
    elseif perc > 55 then
        return '󰁿'
    elseif perc > 45 then
        return '󰁾'
    elseif perc > 35 then
        return '󰁽'
    elseif perc > 25 then
        return '󰁼'
    elseif perc > 15 then
        return '󰁻'
    elseif perc > 5 then
        return '󰁺'
    else
        return '󰂎'
    end
end

-- Battery
local bat = lain.widget.bat({
    settings = function()
        if bat_now.status and bat_now.status ~= "N/A" then
            if bat_now.ac_status == 1 then
                widget:set_markup(markup.font(theme.font, " AC"))
                return
            end
            widget:set_markup(markup.font(theme.font, battery_icon(bat_now.perc) .. " " .. bat_now.perc .. "%"))
        else
            widget:set_markup('󱧥 ...')
        end
    end
})

-- Net
local neticon = wibox.widget.imagebox(theme.widget_net)
local net = lain.widget.net({
    settings = function()
        widget:set_markup(markup.fontfg(theme.font, palette.white,
            net_now.received .. " ↓↑ " .. net_now.sent))
    end
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
        width  = width + 2 * arrow_depth
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
        width  = width + 2 * arrow_depth
        offset = -arrow_depth
    end

    cr:move_to(offset + arrow_depth, 0)
    cr:line_to(offset + width, 0)
    cr:line_to(offset + width, height)
    cr:line_to(offset, height)

    cr:close_path()
end

--- Parallelogram that uses the same angle logic as the powerline.
---@param cr cairo_t
---@param width number
---@param height number
function theme.slab(cr, width, height)
    return shape.parallelogram(cr, width, height, width - height / 2)
end

---@class Segment
---@field widget any
---@field background? HexColor
---@field color? HexColor
---@field margin? integer

--- Expands a segment into a list of widgets and its powerline seperator.
---@param segment Segment
---@param bg_color HexColor
---@return any[]
local function expand_segment(segment, bg_color, margin)
    local widget = segment.widget or segment
    local container = wibox.container.background(
        wibox.container.margin(widget, dpi(margin or 16), dpi(margin or 16)),
        gradient(bg_color, theme.wibox_height),
        function(cr, width, height) shape.powerline(cr, width, height, 0 - height / 2) end
    )
    if segment.color then
        container.fg = segment.color
    end
    return {
        wibox.widget {
            forced_width = 10,
            color = gradient(segment.color or bg_color, theme.wibox_height),
            widget = wibox.widget.separator,
            shape = function(cr, width, height) shape.powerline(cr, width + 2, height, 0 - height / 2) end,
        },
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
        background = palette.bg_3
    },
    {
        widget = wibox.widget { mpdicon, theme.mpd.widget, layout = wibox.layout.align.horizontal },
    },
    {
        widget = task,
    },
    {
        widget = wibox.widget { mem.widget, layout = wibox.layout.align.horizontal },
        color = palette.orange
    },
    {
        widget = wibox.widget { cpu.widget, layout = wibox.layout.align.horizontal },
        color = palette.green
    },
    {
        widget = wibox.widget { temp.widget, layout = wibox.layout.align.horizontal },
        color = palette.purple
    },
    --[[
    {
        widget = wibox.widget { theme.fs and theme.fs.widget, layout = wibox.layout.align.horizontal },
        color = palette.orange
    },
    ]]
    {
        widget = wibox.widget { bat.widget, layout = wibox.layout.align.horizontal },
        color = palette.cyan
    },
    {
        widget = wibox.widget { nil, neticon, net.widget, layout = wibox.layout.align.horizontal },
        background = palette.fg_2
    },
    {
        widget = binclock,
        background = palette.bg_3
    },
}

local function color_from_index(i)
    return i % 2 == 0 and palette.bg_2 or palette.bg
end

function theme.at_screen_connect(s)
    -- Quake application
    s.quake = lain.util.quake({ app = awful.util.terminal })

    -- If wallpaper is a function, call it with the screen
    local wallpaper = theme.wallpaper
    if type(wallpaper) == "function" then
        wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s, true)

    ---@type table
    local powerline = {
        layout = wibox.layout.fixed.horizontal,
        spacing = -9,
    }

    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(my_table.join(
        awful.button({}, 1, function() awful.layout.inc(1) end),
        awful.button({}, 2, function() awful.layout.set(awful.layout.layouts[1]) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc(1) end),
        awful.button({}, 5, function() awful.layout.inc(-1) end)))

    -- Add global widgets to this screen.
    for i, segment in ipairs(segments) do
        local this_color = segment.background or color_from_index(i)
        for _, x in ipairs(expand_segment(segment, this_color, segment.margin)) do
            table.insert(powerline, x)
        end
    end
    -- Add screen layout to this screen.
    table.insert(powerline,
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
    s.mypromptbox     = awful.widget.prompt()
    -- Create a taglist widget
    s.mytaglist       = awful.widget.taglist {
        screen          = s,
        filter          = awful.widget.taglist.filter.all,
        style           = {
            shape_border_width = dpi(2),
            shape_border_color = gradient(palette.bg, theme.wibox_height),
            shape = theme.slab,
        },
        buttons         = awful.util.taglist_buttons,
        layout          = {
            spacing = -dpi(10),
            layout  = wibox.layout.fixed.horizontal
        },
        widget_template = {
            {
                {
                    {
                        id     = 'text_role',
                        widget = wibox.widget.textbox,
                    },
                    layout = wibox.layout.fixed.horizontal,
                },
                left   = 14,
                right  = 14,
                widget = wibox.container.margin
            },
            id              = 'background_role',
            widget          = wibox.container.background,
            -- Add support for hover colors and an index label
            ---@diagnostic disable-next-line: unused-local
            create_callback = function(self, c3, index, objects) --luacheck: no unused args
                self:connect_signal('mouse::enter', function()
                    if self.shape_border ~= palette.bg_3 then
                        self.backup     = self.bg
                        self.has_backup = true
                    end
                    self.bg = palette.bg_3
                end)
                self:connect_signal('mouse::leave', function()
                    if self.has_backup then self.bg = self.backup end
                end)
            end,
        },
    }

    -- Create a tasklist widget
    s.mytasklist      = awful.widget.tasklist {
        screen          = s,
        filter          = awful.widget.tasklist.filter.currenttags,
        buttons         = awful.util.tasklist_buttons,
        style           = {
            shape_border_width = dpi(1),
            shape_border_color = palette.bg_2,
            shape = shape.rounded_rect,
        },
        layout          = {
            spacing = 8,
            layout  = wibox.layout.flex.horizontal

        },
        widget_template = {
            {
                {
                    {
                        {
                            id     = 'icon_role',
                            widget = wibox.widget.imagebox,
                        },
                        margins = 2,
                        widget  = wibox.container.margin,
                    },
                    {
                        id     = 'text_role',
                        widget = wibox.widget.textbox,
                    },
                    layout = wibox.layout.fixed.horizontal,
                },
                left   = 10,
                right  = 10,
                widget = wibox.container.margin
            },
            id              = 'background_role',
            widget          = wibox.container.background,
            ---@diagnostic disable-next-line: unused-local
            create_callback = function(self, c3, index, objects) --luacheck: no unused args
                self:connect_signal('mouse::enter', function()
                    self.backup             = self.shape_border_color
                    self.has_backup         = true
                    self.shape_border_color = lighten(self.shape_border_color, 30)
                end)
                self:connect_signal('mouse::leave', function()
                    if self.has_backup then self.shape_border_color = self.backup end
                end)
            end,
        },
    }

    -- Create the wibox
    s.mywibox         = awful.wibar {
        position = "top",
        screen = s,
        height = dpi(theme.wibox_height),
        bg = gradient(palette.bg, theme.wibox_height, 0.85),
        fg = theme.fg_normal,
    }

    local menu_button = wibox.container.margin(wibox.widget.imagebox(
        theme.awesome_icon), dpi(2), dpi(2)
    )
    menu_button:buttons(gears.table.join(
        awful.widget.button():buttons(),
        awful.button({}, 1, nil, function()
            awful.util.mymainmenu:toggle()
        end)
    ))

    -- Add widgets to the wibox
    -- There is some weird nonsense with nested fixed layouts when the inner has
    -- negative spacing so we have to structure this a little oddly.
    s.mywibox:setup {
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
        powerline
    }
end

return theme
