-- Audio state backend.
-- Tracks one or more ALSA channels, notifies subscribers when state changes.
-- A single shared timer polls for out-of-band changes; control methods notify
-- subscribers immediately and reset the timer countdown.

local gears = require("gears")
local awful = require("awful")

-- ----------------------------------------------------------------------------
-- Types
-- ----------------------------------------------------------------------------

---@alias AudioLevel    integer   Volume level 0–100.
---@alias AudioMuted    boolean   True when the channel is muted.
---@alias AudioCallback fun(level: AudioLevel, muted: AudioMuted)

---@class AudioChannelEntry
---@field level       AudioLevel
---@field muted       AudioMuted
---@field subscribers AudioCallback[]

---@class AudioHandle
---@field level       AudioLevel
---@field muted       AudioMuted
---@field subscribe   fun(self: AudioHandle, cb: AudioCallback)
---@field adjust_perc fun(self: AudioHandle, delta: integer)
---@field set_perc    fun(self: AudioHandle, value: number)
---@field toggle_mute fun(self: AudioHandle)

---@class AudioOpts
---@field timeout?  integer   Polling interval in seconds. Defaults to 5.
---@field channels? string[]  ALSA channel names to pre-register.

---@class AudioModule
---@field channels table<string, AudioChannelEntry>
---@field handles  table<string, AudioHandle>
---@field timer    table|nil
---@field timeout  integer

-- Module --
local audio = {
	channels = {},
	handles = {},
	timer = nil,
	timeout = 5,
}

-- ----------------------------------------------------------------------------
-- Parsing
-- ----------------------------------------------------------------------------

--- Parse `amixer sget <name>` stdout.
--- Returns level (integer 0-100) and muted (boolean), or nil/nil on failure.
---@param stdout string
---@return AudioLevel|nil, AudioMuted|nil
local function parse_amixer(stdout)
	local level = tonumber(stdout:match("%[(%d+)%%%]"))
	local status = stdout:match("%[(o[nf]+)%]")
	if not level or not status then
		return nil, nil
	end
	return level, status == "off"
end

-- ----------------------------------------------------------------------------
-- Forward declarations
-- ----------------------------------------------------------------------------

--- Async-poll a single channel. Updates cached state and notifies subscribers
--- if either level or muted has changed.
---@param name string
local function poll_channel(name)
	awful.spawn.easy_async(string.format("amixer sget %s", name), function(stdout)
		local entry = audio.channels[name]
		if not entry then
			return
		end
		local level, muted = parse_amixer(stdout)
		if level == nil or muted == nil then
			return
		end
		if level == entry.level and muted == entry.muted then
			return
		end
		entry.level = level
		entry.muted = muted
		-- Keep handle fields in sync so callers can read them synchronously.
		local handle = audio.handles[name]
		if handle then
			handle.level = level
			handle.muted = muted
		end
		for _, cb in ipairs(entry.subscribers) do
			cb(level, muted)
		end
	end)
end

--- Create (or return cached) a handle for the named channel.
--- Assumes the channel entry already exists in audio.channels.
---@param name string
---@return AudioHandle
local function make_handle(name)
	if audio.handles[name] then
		return audio.handles[name]
	end

	local handle = {
		level = 0,
		muted = false,
	}

	--- Register a subscriber callback.
	---@param cb AudioCallback
	function handle:subscribe(cb)
		table.insert(audio.channels[name].subscribers, cb)
	end

	--- Adjust volume by delta percent. Positive values increase, negative decrease.
	--- The `on` suffix unmutes on positive adjustments (intentional, mirrors original rc.lua behaviour).
	---@param delta integer
	function handle:adjust_perc(delta)
		local cmd
		if delta >= 0 then
			cmd = string.format("amixer -q set %s %d%%+ on", name, delta)
		else
			cmd = string.format("amixer -q set %s %d%%- on", name, -delta)
		end
		awful.spawn.easy_async(cmd, function()
			poll_channel(name)
			if audio.timer then
				audio.timer:again()
			end
		end)
	end

	--- Set volume to an absolute percent value.
	---@param value number
	function handle:set_perc(value)
		awful.spawn.easy_async(string.format("amixer -q set %s %d%%", name, math.floor(value)), function()
			poll_channel(name)
			if audio.timer then
				audio.timer:again()
			end
		end)
	end

	--- Toggle mute on the channel.
	function handle:toggle_mute()
		awful.spawn.easy_async(string.format("amixer -q set %s toggle", name), function()
			poll_channel(name)
			if audio.timer then
				audio.timer:again()
			end
		end)
	end

	audio.handles[name] = handle
	return handle
end

-- ----------------------------------------------------------------------------
-- Timer management
-- ----------------------------------------------------------------------------

--- Start the shared polling timer if it isn't running yet.
local function ensure_timer()
	if audio.timer then
		return
	end
	audio.timer = gears.timer({
		timeout = audio.timeout,
		autostart = true,
		call_now = false,
		callback = function()
			for name in pairs(audio.channels) do
				poll_channel(name)
			end
		end,
	})
end

-- ----------------------------------------------------------------------------
-- Channel registration
-- ----------------------------------------------------------------------------

--- Register a channel if not already tracked. Starts the shared timer on
--- first registration and schedules an initial async poll.
---@param name string  ALSA channel name (e.g. "Master", "Capture").
local function register_channel(name)
	if audio.channels[name] then
		return
	end
	audio.channels[name] = { level = 0, muted = false, subscribers = {} }
	ensure_timer()
	-- Initial poll fires asynchronously; handle fields will be seeded once it
	-- completes (typically within a few milliseconds).
	poll_channel(name)
end

-- ----------------------------------------------------------------------------
-- Public API
-- ----------------------------------------------------------------------------

--- Configure the module and pre-register channels.
---@param opts AudioOpts
function audio.setup(opts)
	if opts.timeout then
		audio.timeout = opts.timeout
	end
	if opts.channels then
		for _, name in ipairs(opts.channels) do
			register_channel(name)
		end
	end
end

--- Return the cached handle for `name`, auto-registering if needed.
---@param name string
---@return AudioHandle
function audio.channel(name)
	register_channel(name)
	return make_handle(name)
end

--- Shorthand for audio.channel(name):subscribe(cb).
---@param name string
---@param cb   AudioCallback
function audio.subscribe(name, cb)
	audio.channel(name):subscribe(cb)
end

return audio
