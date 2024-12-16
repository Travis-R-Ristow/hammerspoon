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

obj.name = "ClipBoardManager"
obj.version = "0.1"
obj.author = "Travis R"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local clipboardHistory = {}
local maxSize = 10

-- {
-- 		{
-- 			title = "my menu item",
-- 			fn = function()
-- 				print("you clicked my menu item!")
-- 			end,
-- 		},
-- 		{ title = "-" },
-- 		-- { title = "other item", fn = some_function },
-- 		{ title = "disabled item", disabled = true },
-- 		{ title = "checked item", checked = true },
-- 	}

function obj:init()
	local winSizeW = hs.window.focusedWindow():screen():frame().w
	local menuTable = {}
	local menuBar = hs.menubar.new(true, "ClipHistory")
	menuBar:setIcon(hs.image.imageFromPath("~/.hammerspoon/ClipboardIcon.png"):size({ w = 20, h = 20 }))

	hs.hotkey.bind({ "cmd", "ctrl" }, "V", function()
		if #menuTable == 0 then
			menuBar:setMenu({ { title = "No Copies to Paste" } })
		end
		menuBar:popupMenu({ x = winSizeW - 450, y = 0 })
	end)

	self.eventtap = hs.eventtap.new(
		{ hs.eventtap.event.types.keyUp, hs.eventtap.event.types.flagsChanged },
		function(event)
			local flags = event:getFlags()
			local keyCode = event:getKeyCode()

			if flags.cmd and keyCode == hs.keycodes.map["C"] then
				local copyCtx = hs.pasteboard.getContents()
				if #clipboardHistory < maxSize then
					table.insert(clipboardHistory, copyCtx)
					-- print(copyCtx)
				else
					table.remove(clipboardHistory, 1)
					table.insert(clipboardHistory, copyCtx)
				end

				menuTable = {}
				for k, v in pairs(clipboardHistory) do
					local shortV = v
					if string.len(v) > 50 then
						shortV = string.sub(v, 1, 50)
					end
					table.insert(menuTable, {
						title = shortV,
						fn = function()
							hs.eventtap.keyStrokes(v)
						end,
					})
					-- print("Key:", k, "Value:", v)
				end
				menuBar:setMenu(menuTable)
			end
		end
	)

	self.eventtap:start()
end

return obj
