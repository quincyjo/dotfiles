require("themes.qubit.types")

-- Awesome
local naughty = require("naughty")
local dpi = require("beautiful.xresources").apply_dpi

-- Theme
local media_widget = require("themes.qubit.media_widget")

local MEDIA_NOTIFICATION_WIDTH = dpi(300)
local MEDIA_NOTIFICATION_HEIGHT = dpi(128)

naughty.connect_signal("request::display", function(n)
	-- Hard respect resident widgets with a custom template, don't close on click.
	if n.widget_template then
		if n.resident then
			local real_destroy = n.destroy
			rawset(n, "destroy", function(self, reason, ...)
				if reason ~= naughty.notification_closed_reason.dismissed_by_user then
					real_destroy(self, reason, ...)
				end
			end)
		end
	end
	naughty.layout.box({ notification = n })
end)

---@type table<string, MediaWidgetHandle>
local media_widget_cache = {}

--- Get the media widget for a source. If one doesn't exist, make one and cache
--- it. Otherwise, returns the cached widget and starts it.
---@param source MediaSource
---@param art string|nil
---@param on_interaction fun()
---@return MediaWidgetHandle
local function get_media_wiget(source, art, on_interaction)
	local handle
	if media_widget_cache[source.id] then
		handle = media_widget_cache[source.id]
		handle.start()
	else
		handle = media_widget(source, {
			width = MEDIA_NOTIFICATION_WIDTH,
			height = MEDIA_NOTIFICATION_HEIGHT,
			on_interaction = on_interaction,
			art = art or false,
		})
		media_widget_cache[source.id] = handle
		source:on_removed(function(source_id)
			handle.stop()
			media_widget_cache[source_id] = nil
		end)
	end
	return handle
end

---@type table<string, NaughtyNotification>
local source_notifs = {}

---@type MediaNotifyCallback
return function(source, art)
	local handle = get_media_wiget(source, art, function()
		if source_notifs[source.id] then
			source_notifs[source.id]:reset_timeout()
		end
	end)

	return {
		timeout = 8,
		resident = true,
		widget_template = handle.widget,
	}, {
		reuse = true,
		on_destroy = function()
			handle.stop()
			source_notifs[source.id] = nil
		end,
		callback = function(notif)
			source_notifs[source.id] = notif
		end,
	}
end
