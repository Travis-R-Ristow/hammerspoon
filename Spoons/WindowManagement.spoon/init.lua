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

obj.name = "WindowManagement"
obj.version = "0.1"
obj.author = "Travis R"
obj.license = "MIT - https://opensource.org/licenses/MIT"

function obj:init()
	hs.grid.setGrid("2x2")
	hs.grid.setMargins("0x0")

	hs.hotkey.bind({ "cmd" }, "1", function()
		hs.application.launchOrFocus("iTerm")
	end)

	hs.hotkey.bind({ "cmd" }, "2", function()
		hs.application.launchOrFocus("Google Chrome")
	end)

	hs.hotkey.bind({ "cmd" }, "3", function()
		hs.application.launchOrFocus("Rider")
	end)

	hs.hotkey.bind({ "cmd" }, "4", function()
		hs.application.launchOrFocus("Visual Studio Code")
	end)

	hs.hotkey.bind({ "cmd" }, "5", function()
		hs.application.launchOrFocus("Postman")
	end)

	hs.hotkey.bind({ "cmd" }, "9", function()
		local iterm = hs.application.get("iTerm2")
		if iterm then
			local windows = iterm:allWindows()
			for _, win in ipairs(windows) do
				if string.find(win:title(), "scratch%-pad") then
					win:focus()
					return
				end
			end
		end

		hs.application.launchOrFocus("iTerm")
		hs.eventtap.keyStroke({ "cmd" }, "n")
		hs.eventtap.keyStrokes("cd ~/Documents/Notes && vim scratch-pad.md\n")
		local win = hs.window.focusedWindow()
		if win then
			win:maximize()
		end
	end)

	hs.hotkey.bind({ "cmd" }, "0", function()
		hs.application.launchOrFocus("Slack")
	end)

	hs.hotkey.bind({ "ctrl", "shift" }, "Q", function()
		local win = hs.window.focusedWindow()
		hs.grid.set(win, "0,0,1,1")
	end)

	hs.hotkey.bind({ "ctrl", "shift" }, "W", function()
		local win = hs.window.focusedWindow()
		hs.grid.set(win, "1,0,1,1")
	end)

	hs.hotkey.bind({ "ctrl", "shift" }, "A", function()
		local win = hs.window.focusedWindow()
		hs.grid.set(win, "0,1,1,1")
	end)

	hs.hotkey.bind({ "ctrl", "shift" }, "S", function()
		local win = hs.window.focusedWindow()
		hs.grid.set(win, "1,1,1,1")
	end)

	hs.hotkey.bind({ "ctrl", "shift" }, "[", function()
		local win = hs.window.focusedWindow()
		hs.grid.set(win, "0,0,1,2")
	end)

	hs.hotkey.bind({ "ctrl", "shift" }, "]", function()
		local win = hs.window.focusedWindow()
		hs.grid.set(win, "1,0,1,2")
	end)

	hs.hotkey.bind({ "ctrl" }, "F", function()
		local win = hs.window.focusedWindow()
		local winSizeW = win:screen():frame().w
		local winSizeH = win:screen():frame().h
		local screenX = hs.screen.mainScreen():frame().x
		local screenY = hs.screen.mainScreen():frame().y

		if
			win:frame().w < winSizeW
			or win:frame().h < winSizeH
			or win:frame().x ~= screenX
			or win:frame().y ~= screenY
		then
			win:maximize()
		else
			local resizeW = winSizeW / 1.5
			local resizeH = winSizeH / 1.5

			win:setFrame({
				x = screenX + (resizeW / 4),
				y = screenY + (resizeH / 4),
				w = resizeW,
				h = resizeH,
			})
		end
	end)

	local function getCurrentIndex(tbl, searchValue)
		for k, v in pairs(tbl) do
			if v == searchValue then
				return k
			end
		end
	end

	local function getOrderedScreens()
		local screens = hs.screen.allScreens()
		table.sort(screens, function(a, b)
			local aFrame = a:frame()
			local bFrame = b:frame()
			if aFrame.x ~= bFrame.x then
				return aFrame.x < bFrame.x
			end
			return aFrame.y < bFrame.y
		end)
		return screens
	end

	hs.hotkey.bind({ "ctrl", "shift" }, "RIGHT", function()
		local win = hs.window.focusedWindow()
		local screens = getOrderedScreens()
		local currentIndex = getCurrentIndex(screens, win:screen())
		local nextIndex = (currentIndex % #screens) + 1
		win:moveToScreen(screens[nextIndex], false, true)
	end)

	hs.hotkey.bind({ "ctrl", "shift" }, "LEFT", function()
		local win = hs.window.focusedWindow()
		local screens = getOrderedScreens()
		local currentIndex = getCurrentIndex(screens, win:screen())
		local prevIndex = ((currentIndex - 2) % #screens) + 1
		win:moveToScreen(screens[prevIndex], false, true)
	end)
end

return obj
