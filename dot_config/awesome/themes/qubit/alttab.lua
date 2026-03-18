-- Alt-tab client switcher.
-- Manages a focus-ordered client stack and a keygrabber-driven switch session.
-- UI is optionally provided via AlttabUI callbacks; if omitted, a simple
-- notification-based UI is used as a fallback.
-- Signal side effects are established explicitly via alttab.setup(), which must
-- be called from rc.lua.

local awful = require("awful")
local naughty = require("naughty")
---@diagnostic disable-next-line: undefined-global
local client = client
---@diagnostic disable-next-line: undefined-global
local tag = tag

-- ----------------------------------------------------------------------------
-- Types
-- ----------------------------------------------------------------------------

---@alias AwesomeClient table
---@alias AwesomeTag    table

---@class AlttabUI
---@field show        fun(clients: AwesomeClient[], index: integer)  Build and display the switcher popup.
---@field update      fun(index: integer)                            Move the highlight to a new index without rebuilding.
---@field hide        fun()                                          Tear down and hide the switcher popup.
---@field on_init?      fun(api: AlttabAPI)    Called after setup() with a reference to the public API.
---@field on_unfocus?   fun(c: AwesomeClient)  Called when a client loses focus. Good for caching content while visible.
---@field on_minimized? fun(c: AwesomeClient)  Called when a client becomes minimized.
---@field on_untagged?  fun(c: AwesomeClient)  Called when a client is removed from a tag.
---@field on_unmanage?  fun(c: AwesomeClient)  Called when a client is removed. Useful for cache cleanup.
---@field on_tag_selected?  fun(t: AwesomeTag)  Called when a client is removed. Useful for cache cleanup.

---@class AlttabAPI
---@field select      fun(index: integer)      Move the highlight to the given index without committing.
---@field close_session fun(commit?: boolean)  End the session, committing (true/nil) or cancelling (false).

---@class AlttabOpts
---@field ui? AlttabUI  UI implementation provided by the active theme. Defaults to a notification UI.
---@field held_key?   string  Key to be held down while the switcher is open. Defaults to "Mod1" (alt).
---@field select_key? string  Key to be pressed to navigate the stack. Defaults to "Tab".

---@class AlttabSession
---@field clients AwesomeClient[]  Snapshot of the full client stack taken when the session started.
---@field index   integer          Index of the currently highlighted client (1-based).

-- ----------------------------------------------------------------------------
-- Module
-- ----------------------------------------------------------------------------

---@class AlttabModule
---@field stack   AwesomeClient[]        Focus-ordered stack of all managed clients.
---@field _set    table<AwesomeClient, true>  Membership set for O(1) existence checks.
---@field ui      AlttabUI|nil           Active UI implementation, set by setup().
---@field session AlttabSession|nil      Active switch session; nil when the switcher is not visible.
---@field grabber table|nil              Active keygrabber; held so the API can stop it mid-session.
---@field held_key string                The key to be held down for the grabber.
---@field select_key string              The key to be pressed to navigate the stack.
local alttab = {
	stack = {},
	_set = {},
	ui = nil,
	session = nil,
	grabber = nil,
	held_key = "Mod1",
	select_key = "Tab",
	_committing = false,
}

-- ----------------------------------------------------------------------------
-- Default UI
-- ----------------------------------------------------------------------------

--- Build a simple notification-based UI, used when no theme UI is provided.
---@return AlttabUI
local function make_default_ui()
	local notif = nil
	local current_clients = nil

	local function render(clients, index)
		local lines = {}
		for i, c in ipairs(clients) do
			local prefix = i == index and "> " or "  "
			table.insert(lines, prefix .. (c.name or "?"))
		end
		notif = naughty.notify({
			title = "Alt-Tab",
			text = table.concat(lines, "\n"),
			timeout = 0,
			replaces_id = notif and notif.id or nil,
		})
	end

	return {
		show = function(clients, index)
			current_clients = clients
			render(clients, index)
		end,
		update = function(index)
			if not current_clients then
				return
			end
			render(current_clients, index)
		end,
		hide = function()
			if notif then
				naughty.destroy(notif)
				notif = nil
			end
			current_clients = nil
		end,
	}
end

-- ----------------------------------------------------------------------------
-- Stack operations
-- ----------------------------------------------------------------------------

--- Move a client to the front of the stack, inserting it if not already present.
---@param c AwesomeClient
local function stack_push(c)
	if alttab._set[c] then
		for i, v in ipairs(alttab.stack) do
			if v == c then
				table.remove(alttab.stack, i)
				break
			end
		end
	end
	table.insert(alttab.stack, 1, c)
	alttab._set[c] = true
end

--- Remove a client from the stack.
---@param c AwesomeClient
local function stack_remove(c)
	if not alttab._set[c] then
		return
	end
	for i, v in ipairs(alttab.stack) do
		if v == c then
			table.remove(alttab.stack, i)
			alttab._set[c] = nil
			return
		end
	end
end

-- ----------------------------------------------------------------------------
-- Session helpers
-- ----------------------------------------------------------------------------

--- Move the highlight to the given index without committing.
---@param index integer
local function select(index)
	local s = alttab.session
	if not s or not alttab.ui then
		return
	end
	s.index = index
	alttab.ui.update(index)
end

--- Advance the session index by delta, wrapping around.
--- Only called from within an active keygrabber session.
---@param delta integer
local function advance(delta)
	local s = alttab.session
	if not s or not alttab.ui then
		return
	end
	s.index = (s.index - 1 + delta) % #s.clients + 1
	alttab.ui.update(s.index)
end

--- End the session, optionally committing the selection.
--- Safe to call from both the keygrabber stop_callback and the public API.
---@param commit? boolean True/nil to commit the selection, false to cancel.
local function close_session(commit)
	if not alttab.session then
		return
	end -- guard against re-entry via stop_callback
	commit = commit == nil and true or commit
	local s = alttab.session
	alttab.session = nil
	-- Stop the grabber if still running (e.g. called from mouse handler).
	-- Nil it first so the resulting stop_callback re-entry returns immediately.
	local g = alttab.grabber
	alttab.grabber = nil
	if g then
		g:stop()
	end
	if alttab.ui then
		alttab.ui.hide()
	end

	if commit then
		if not s then
			return
		end
		local c = s.clients[s.index]
		if not c then
			return
		end

		-- Suppress focus-signal stack updates while we switch tags/focus.
		-- view_only() may auto-focus another client on the target tag, which
		-- would corrupt the stack order. We push `c` manually afterward.
		alttab._committing = true
		c.minimized = false
		awful.screen.focus(c.screen)
		if c.first_tag then
			c.first_tag:view_only()
		end
		client.focus = c
		c:raise()
		alttab._committing = false
		stack_push(c)
	end
end

-- ----------------------------------------------------------------------------
-- Public API
-- ----------------------------------------------------------------------------

--- Set up client signal listeners and store the UI implementation.
--- Connects client::manage, client::unmanage, and client::focus always.
--- Additionally connects client::unfocus, client::property::minimized, and
--- client::untagged if the corresponding hooks are defined on the UI.
---@param opts AlttabOpts
function alttab.setup(opts)
	local ui = opts.ui or make_default_ui()
	alttab.ui = ui
	alttab.held_key = opts.held_key or alttab.held_key
	alttab.select_key = opts.select_key or alttab.select_key

	client.connect_signal("manage", function(c)
		-- Only append if not already present; focus may fire before manage.
		if alttab._set[c] then
			return
		end
		table.insert(alttab.stack, c)
		alttab._set[c] = true
	end)

	client.connect_signal("unmanage", function(c)
		stack_remove(c)
		if ui.on_unmanage then
			ui.on_unmanage(c)
		end
	end)

	client.connect_signal("focus", function(c)
		if not alttab._committing then
			stack_push(c)
		end
	end)

	if ui.on_unfocus then
		client.connect_signal("unfocus", ui.on_unfocus)
	end

	if ui.on_minimized then
		client.connect_signal("property::minimized", function(c)
			if c.minimized then
				ui.on_minimized(c)
			end
		end)
	end

	if ui.on_untagged then
		---@diagnostic disable-next-line: unused-local
		client.connect_signal("untagged", function(c, _tag)
			ui.on_untagged(c)
		end)
	end

	if ui.on_tag_selected then
		tag.connect_signal("property::selected", ui.on_tag_selected)
	end

	if ui.on_init then
		ui.on_init({
			select = select,
			close_session = close_session,
		})
	end
end

--- Start a switch session. Shows the UI and hands off to the keygrabber.
--- Subsequent Tab presses are handled internally; this should only be bound
--- to the initial Alt+Tab and Alt+Shift+Tab keybinding in rc.lua.
---@param dir integer  1 for forward (Alt+Tab), -1 for backward (Alt+Shift+Tab).
function alttab.switch(dir)
	if not alttab.ui then
		return
	end
	if alttab.session then
		return
	end

	-- Reconcile the stack against the live client list, removing any references
	-- that AwesomeWM has invalidated (e.g. after a config reload).
	local live = {}
	for _, c in ipairs(client.get()) do
		live[c] = true
	end
	for i = #alttab.stack, 1, -1 do
		local c = alttab.stack[i]
		if not live[c] then
			table.remove(alttab.stack, i)
			alttab._set[c] = nil
		end
	end

	if #alttab.stack < 2 then
		return
	end

	local index = (dir % #alttab.stack) + 1
	-- NOTE: clients is a reference to alttab.stack, not a snapshot. Changes to
	-- the stack (manage/unmanage) will be reflected in the active session.
	alttab.session = { clients = alttab.stack, index = index }
	alttab.ui.show(alttab.stack, index)

	alttab.grabber = awful.keygrabber({
		stop_key = alttab.held_key,
		stop_event = "release",
		stop_callback = close_session,
		keybindings = {
			{
				{ alttab.held_key },
				alttab.select_key,
				function()
					advance(1)
				end,
			},
			{
				{ alttab.held_key, "Shift" },
				alttab.select_key,
				function()
					advance(-1)
				end,
			},
			{
				{ alttab.held_key },
				"Escape",
				function()
					close_session(false)
				end,
			},
		},
	})
	alttab.grabber:start()
end

return alttab
