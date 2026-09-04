local obj = {}
local _store = {}
setmetatable(obj, {
	__index = function(_, k)
		return _store[k]
	end,
	__newindex = function(t, k, v)
		rawset(_store, k, v)
		if t._init_done then
			if t._attribs[k] then
				t:init()
			end
		end
	end,
})
obj.__index = obj

obj.name = "KeyShortCuts"
obj.version = "0.1"
obj.author = "Travis R"
obj.license = "MIT - https://opensource.org/licenses/MIT"

function obj:init()
	hs.hotkey.bind({}, "Home", function()
		hs.eventtap.keyStroke({ "cmd" }, "Left")
	end)

	hs.hotkey.bind({}, "End", function()
		hs.eventtap.keyStroke({ "cmd" }, "Right")
	end)

	hs.hotkey.bind({ "ctrl", "shift" }, "O", function()
		local f = io.open(os.getenv("HOME") .. "/.claude/.last-read", "r")
		if not f then
			hs.alert.show("No file breadcrumb found")
			return
		end
		local line = f:read("*l")
		local root = f:read("*l") or ""
		f:close()
		if not line or line == "" then
			hs.alert.show("Empty breadcrumb")
			return
		end
		local file, ln = line:match("^(.+):(%d+)$")
		if not file then
			file = line
			ln = "1"
		end
		local cd_cmd = ""
		if root ~= "" then
			cd_cmd = "cd '" .. root .. "' && "
		end
		hs.osascript.applescript([[
			tell application "iTerm2"
				tell current window
					create tab with default profile
					tell current session
						write text "]] .. cd_cmd .. [[nvim +]] .. ln .. [[ ']] .. file .. [['"
					end tell
				end tell
			end tell
		]])
	end)
end

return obj
