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
		local winSizeW = hs.window.focusedWindow():screen():frame().w
		local winSizeH = hs.window.focusedWindow():screen():frame().h
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

	function getCurrentIndex(tbl, searchValue)
		for k, v in pairs(tbl) do
			if v == searchValue then
				return k
			end
		end
	end

	hs.hotkey.bind({ "ctrl", "shift" }, "LEFT", function()
		local currentScreen = hs.screen.mainScreen()
		local allScreens = hs.screen.allScreens()
		local currentScreenIndex = getCurrentIndex(allScreens, currentScreen)
		local moveToScreenIndex = currentScreenIndex - 1

		if moveToScreenIndex <= 0 then
			moveToScreenIndex = #allScreens
		end

		hs.window.focusedWindow():moveToScreen(allScreens[moveToScreenIndex], false, true)
	end)

	hs.hotkey.bind({ "ctrl", "shift" }, "RIGHT", function()
		local currentScreen = hs.screen.mainScreen()
		local allScreens = hs.screen.allScreens()
		local currentScreenIndex = getCurrentIndex(allScreens, currentScreen)
		local moveToScreenIndex = currentScreenIndex + 1

		if moveToScreenIndex >= #allScreens + 1 then
			moveToScreenIndex = 1
		end

		hs.window.focusedWindow():moveToScreen(allScreens[moveToScreenIndex], false, true)
	end)
end

return obj
