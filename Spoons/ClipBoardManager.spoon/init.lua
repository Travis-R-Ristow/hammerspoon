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
local acquiNameHistory = {}
local guidHistory = {}
local maxSize = 10

local tableContains = function(t, value)
	for _, v in pairs(t) do
		if v == value then
			return true
		end
	end
	return false
end

local dedupTable = function(t)
	local temp = {}
	for _, v in ipairs(t) do
		if not tableContains(temp, v) then
			table.insert(temp, v)
		end
	end
	return temp
end

function obj:init()
	local menuTable = { { title = "No Copies to Paste" } }
	local menuBar = hs.menubar.new(true, "ClipHistory")
	menuBar:setIcon(hs.image.imageFromPath("~/.hammerspoon/ClipboardIcon.png"):size({ w = 20, h = 20 }))
	menuBar:setMenu(menuTable)

	hs.hotkey.bind({ "cmd", "ctrl" }, "V", function()
		local focusedWindow = hs.screen.mainScreen():frame()
		menuBar:popupMenu({ x = focusedWindow.w - (focusedWindow.w / 4), y = 0 })
	end)

	local saveCopy = function()
		local copyCtx = hs.pasteboard.getContents()
		if string.match(copyCtx, "^ACQ" .. string.rep("%x", 32) .. "$") then
			if #acquiNameHistory < maxSize then
				table.insert(acquiNameHistory, copyCtx)
			else
				table.remove(acquiNameHistory, 1)
				table.insert(acquiNameHistory, copyCtx)
			end
			acquiNameHistory = dedupTable(acquiNameHistory)
		elseif
			string.match(
				copyCtx,
				"^"
					.. string.rep("%x", 8)
					.. "%-"
					.. string.rep(string.rep("%x", 4) .. "%-", 3)
					.. string.rep("%x", 12)
					.. "$"
			)
		then
			if #guidHistory < maxSize then
				table.insert(guidHistory, copyCtx)
			else
				table.remove(guidHistory, 1)
				table.insert(guidHistory, copyCtx)
			end
			guidHistory = dedupTable(guidHistory)
			hs.pasteboard.setContents(string.lower(copyCtx))
		elseif #clipboardHistory < maxSize then
			clipboardHistory = dedupTable(clipboardHistory)
			table.insert(clipboardHistory, copyCtx)
		else
			clipboardHistory = dedupTable(clipboardHistory)
			table.remove(clipboardHistory, 1)
			table.insert(clipboardHistory, copyCtx)
		end
	end

	local updateDisplayTable = function()
		menuTable = {}
		for _, v in pairs(clipboardHistory) do
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
		end

		if #acquiNameHistory then
			table.insert(menuTable, { title = "~~ ~~ Acquisition Names ~~ ~~", indent = 2, disabled = true })
			for _, v in pairs(acquiNameHistory) do
				table.insert(menuTable, {
					title = v,
					fn = function()
						hs.eventtap.keyStrokes(v)
					end,
				})
			end
		end

		if #guidHistory then
			table.insert(menuTable, { title = "~~  ~~   G U I D s   ~~  ~~", indent = 2, disabled = true })
			for _, v in pairs(guidHistory) do
				table.insert(menuTable, {
					title = v,
					fn = function()
						hs.eventtap.keyStrokes(string.lower(v))
					end,
				})
			end
		end

		menuBar:setMenu(menuTable)
	end

	self.eventtap = hs.eventtap.new(
		{ hs.eventtap.event.types.keyUp, hs.eventtap.event.types.flagsChanged },
		function(event)
			local flags = event:getFlags()
			local keyCode = event:getKeyCode()

			if flags.cmd and keyCode == hs.keycodes.map["C"] then
				saveCopy()
				updateDisplayTable()
			end

			if flags.cmd and keyCode == hs.keycodes.map["V"] then
				saveCopy()
				updateDisplayTable()
			end
		end
	)

	self.eventtap:start()
end

return obj
