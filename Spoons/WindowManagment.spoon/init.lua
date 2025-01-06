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

obj.name = "WindowManagment"
obj.version = "0.1"
obj.author = "Travis R"
obj.license = "MIT - https://opensource.org/licenses/MIT"

function obj:init()
	hs.grid.setGrid("2x2")
	hs.grid.setMargins("0x0")

	hs.hotkey.bind({ "alt", "shift" }, "Q", function()
		local win = hs.window.focusedWindow()
		hs.grid.set(win, "0,0,1,1")
	end)

	hs.hotkey.bind({ "alt", "shift" }, "W", function()
		local win = hs.window.focusedWindow()
		hs.grid.set(win, "1,0,1,1")
	end)

	hs.hotkey.bind({ "alt", "shift" }, "A", function()
		local win = hs.window.focusedWindow()
		hs.grid.set(win, "0,1,1,1")
	end)

	hs.hotkey.bind({ "alt", "shift" }, "S", function()
		local win = hs.window.focusedWindow()
		hs.grid.set(win, "1,1,1,1")
	end)

	hs.hotkey.bind({ "alt", "shift" }, "[", function()
		local win = hs.window.focusedWindow()
		hs.grid.set(win, "0,0,1,2")
	end)

	hs.hotkey.bind({ "alt", "shift" }, "]", function()
		local win = hs.window.focusedWindow()
		hs.grid.set(win, "1,0,1,2")
	end)

	hs.hotkey.bind({ "ctrl" }, "F", function()
		local win = hs.window.focusedWindow()
		local winSizeW = hs.window.focusedWindow():screen():frame().w
		local winSizeH = hs.window.focusedWindow():screen():frame().h

		if win:frame().w ~= winSizeW or win:frame().h ~= winSizeH or win:frame().x ~= 0 or win:frame().y ~= 0 then
			win:maximize()
		else
			win:setFrame({
				x = (winSizeW - (winSizeW / 1.5)) / 2,
				y = (winSizeH - (winSizeH / 1.5)) / 2,
				w = winSizeW / 1.5,
				h = winSizeH / 1.5,
			})
		end
	end)
end

return obj
