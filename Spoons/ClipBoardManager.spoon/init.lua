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
local GUID_REGEX = "^"
	.. string.rep("%x", 8)
	.. "%-"
	.. string.rep(string.rep("%x", 4) .. "%-", 3)
	.. string.rep("%x", 12)
	.. "$"
local AcquiName_Parse_REGEX = "("
	.. string.rep("%x", 8)
	.. ")"
	.. "("
	.. string.rep("%x", 4)
	.. ")"
	.. "("
	.. string.rep("%x", 4)
	.. ")"
	.. "("
	.. string.rep("%x", 4)
	.. ")"
	.. "("
	.. string.rep("%x", 8)
	.. ")"

tableContains = function(t, value)
	for _, v in ipairs(t) do
		if v == value then
			return true
		end
	end
	return false
end

dedupTable = function(t)
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
	MenuBar = hs.menubar.new(true, "ClipHistory")
	MenuBar:setIcon(hs.image.imageFromPath("~/.hammerspoon/ClipboardIcon.png"):size({ w = 20, h = 20 }))
	MenuBar:setMenu(menuTable)

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
					hs.pasteboard.setContents(v)
					hs.eventtap.keyStroke({ "cmd" }, "v")
				end,
			})
		end

		if #acquiNameHistory then
			table.insert(menuTable, { title = "~~ ~~ Acquisition Names ~~ ~~", indent = 2, disabled = true })
			for _, v in pairs(acquiNameHistory) do
				table.insert(menuTable, {
					title = v,
					fn = function(keysPressed)
						local print_v = v
						if keysPressed.alt or keysPressed.cmd or keysPressed.ctrl then
							print_v = string
								.sub(print_v, 4, string.len(print_v))
								:gsub(AcquiName_Parse_REGEX, "%1-%2-%3-%4-%5")
						end
						hs.pasteboard.setContents(print_v)
						hs.eventtap.keyStroke({ "cmd" }, "v")
					end,
				})
			end
		end

		if #guidHistory then
			table.insert(menuTable, { title = "~~  ~~   G U I D s   ~~  ~~", indent = 2, disabled = true })
			for _, v in pairs(guidHistory) do
				table.insert(menuTable, {
					title = v,
					fn = function(keysPressed)
						local print_v = v
						if keysPressed.alt or keysPressed.cmd or keysPressed.ctrl then
							print_v = string.gsub(print_v, "-", "")
							print_v = string.upper("ACQ") .. print_v
						end
						hs.pasteboard.setContents(print_v)
						hs.eventtap.keyStroke({ "cmd" }, "v")
					end,
				})
			end
		end

		MenuBar:setMenu(menuTable)
	end

	hs.hotkey.bind({ "cmd", "ctrl" }, "V", function()
		FocusedWindow = hs.window.focusedWindow():screen():frame()
		updateDisplayTable()
		MenuBar:popupMenu({ x = FocusedWindow.x + (FocusedWindow.w / 2) - (FocusedWindow.w / 4), y = FocusedWindow.y })
	end)

	saveCopy = function()
		CopyCtx = hs.pasteboard.getContents()
		print("copyCtx", CopyCtx)

		if string.match(CopyCtx, "^ACQ" .. string.rep("%x", 32) .. "$") then
			if #acquiNameHistory < maxSize then
				table.insert(acquiNameHistory, CopyCtx)
			else
				table.remove(acquiNameHistory, 1)
				table.insert(acquiNameHistory, CopyCtx)
			end
			acquiNameHistory = dedupTable(acquiNameHistory)
		elseif string.match(CopyCtx, GUID_REGEX) then
			if #guidHistory < maxSize then
				table.insert(guidHistory, CopyCtx)
			else
				table.remove(guidHistory, 1)
				table.insert(guidHistory, CopyCtx)
			end
			guidHistory = dedupTable(guidHistory)
			hs.pasteboard.setContents(string.lower(CopyCtx))
		elseif #clipboardHistory < maxSize then
			table.insert(clipboardHistory, CopyCtx)
			clipboardHistory = dedupTable(clipboardHistory)
		else
			table.remove(clipboardHistory, 1)
			table.insert(clipboardHistory, CopyCtx)
			clipboardHistory = dedupTable(clipboardHistory)
		end
	end

	NormalEventCaptures = hs.eventtap.new(
		{ hs.eventtap.event.types.keyUp, hs.eventtap.event.types.flagsChanged },
		function(event)
			local flags = event:getFlags()
			local keyCode = event:getKeyCode()

			print("Test??", flags.cmd, keyCode)

			if
				flags.cmd
				and (
					keyCode == hs.keycodes.map["C"]
					or keyCode == hs.keycodes.map["V"]
					or keyCode == hs.keycodes.map["X"]
				)
			then
				print("Save Copy")
				saveCopy()
			end

			print("new test", flags.alt, keyCode)

			if flags.alt and (keyCode == hs.keycodes.map["V"]) then
				local currentCopy = hs.pasteboard.getContents()
				if string.match(currentCopy, GUID_REGEX) then
					currentCopy = string.gsub(currentCopy, "-", "")
					currentCopy = string.upper("ACQ") .. currentCopy
					hs.pasteboard.setContents(currentCopy)
					hs.eventtap.keyStroke({ "cmd" }, "v")
				elseif string.match(CopyCtx, "^ACQ" .. string.rep("%x", 32) .. "$") then
					currentCopy = string
						.sub(currentCopy, 4, string.len(currentCopy))
						:gsub(AcquiName_Parse_REGEX, "%1-%2-%3-%4-%5")
					hs.pasteboard.setContents(currentCopy)
					hs.eventtap.keyStroke({ "cmd" }, "v")
				end
			end
		end
	)

	NormalEventCaptures:start()
end

return obj
