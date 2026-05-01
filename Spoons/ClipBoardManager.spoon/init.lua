local obj = {}
obj.__index = obj

obj.name = "ClipBoardManager"
obj.version = "0.2"
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

local ACQUI_NAME_REGEX = "^ACQ" .. string.rep("%x", 32) .. "$"

local ACQUI_PARSE_REGEX = "("
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

local function addToHistory(list, value)
	for i, v in ipairs(list) do
		if v == value then
			table.remove(list, i)
			break
		end
	end
	if #list >= maxSize then
		table.remove(list, 1)
	end
	table.insert(list, value)
	return list
end

local function guidToAcquiName(guid)
	local stripped = string.gsub(guid, "-", "")
	return "ACQ" .. stripped
end

local function acquiNameToGuid(acquiName)
	local hex = string.sub(acquiName, 4)
	return hex:gsub(ACQUI_PARSE_REGEX, "%1-%2-%3-%4-%5")
end

local function hasModifier(keysPressed)
	return keysPressed.alt or keysPressed.cmd or keysPressed.ctrl
end

local function truncate(str, len)
	if string.len(str) > len then
		return string.sub(str, 1, len)
	end
	return str
end

local function pasteValue(value)
	hs.pasteboard.setContents(value)
	hs.eventtap.keyStroke({ "cmd" }, "v")
end

local function saveCopy()
	local contents = hs.pasteboard.getContents()
	if not contents then
		return
	end

	if string.match(contents, ACQUI_NAME_REGEX) then
		acquiNameHistory = addToHistory(acquiNameHistory, contents)
	elseif string.match(contents, GUID_REGEX) then
		guidHistory = addToHistory(guidHistory, contents)
		hs.pasteboard.setContents(string.lower(contents))
	else
		clipboardHistory = addToHistory(clipboardHistory, contents)
	end
end

local menuBar

function obj:init()
	menuBar = hs.menubar.new(true, "ClipHistory")
	menuBar:setIcon(hs.image.imageFromPath("~/.hammerspoon/ClipboardIcon.png"):size({ w = 20, h = 20 }))
	menuBar:setMenu({ { title = "No Copies to Paste" } })

	local function buildMenu()
		local menuTable = {}

		if #clipboardHistory == 0 and #acquiNameHistory == 0 and #guidHistory == 0 then
			table.insert(menuTable, { title = "Use Cmd+C to copy, Ctrl+Cmd+V to open this popup", disabled = true })
		end

		for _, v in ipairs(clipboardHistory) do
			table.insert(menuTable, {
				title = truncate(v, 50),
				fn = function()
					pasteValue(v)
				end,
			})
		end

		table.insert(menuTable, { title = "~~ ~~ Acquisition Names ~~ ~~", indent = 2, disabled = true })
		for _, v in ipairs(acquiNameHistory) do
			table.insert(menuTable, {
				title = v,
				fn = function(keysPressed)
					if hasModifier(keysPressed) then
						pasteValue(acquiNameToGuid(v))
					else
						pasteValue(v)
					end
				end,
			})
		end

		table.insert(menuTable, { title = "~~  ~~   G U I D s   ~~  ~~", indent = 2, disabled = true })
		for _, v in ipairs(guidHistory) do
			table.insert(menuTable, {
				title = v,
				fn = function(keysPressed)
					if hasModifier(keysPressed) then
						pasteValue(guidToAcquiName(v))
					else
						pasteValue(v)
					end
				end,
			})
		end

		menuBar:setMenu(menuTable)
	end

	hs.hotkey.bind({ "cmd", "ctrl" }, "V", function()
		buildMenu()
		local screen = hs.window.focusedWindow():screen():frame()
		local iconFrame = menuBar:frame()
		menuBar:popupMenu({ x = iconFrame.x, y = screen.y })
	end)

	local pendingAction = nil

	local function isCopyKey(keyCode)
		return keyCode == hs.keycodes.map["C"]
			or keyCode == hs.keycodes.map["V"]
			or keyCode == hs.keycodes.map["X"]
	end

	local eventCapture = hs.eventtap.new(
		{ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp },
		function(event)
			local eventType = event:getType()
			local flags = event:getFlags()
			local keyCode = event:getKeyCode()

			if eventType == hs.eventtap.event.types.keyDown then
				if flags.alt and flags.cmd and keyCode == hs.keycodes.map["V"] then
					pendingAction = "altpaste"
					return true
				elseif flags.cmd and isCopyKey(keyCode) then
					pendingAction = "copy"
				end
				return
			end

			if pendingAction == "copy" and isCopyKey(keyCode) then
				pendingAction = nil
				hs.timer.doAfter(0.05, saveCopy)
			elseif pendingAction == "altpaste" and keyCode == hs.keycodes.map["V"] then
				pendingAction = nil
				local currentCopy = hs.pasteboard.getContents()
				if not currentCopy then
					return true
				end

				currentCopy = currentCopy:match("^%s*(.-)%s*$")

				if string.match(currentCopy, GUID_REGEX) then
					pasteValue(guidToAcquiName(currentCopy))
				elseif string.match(currentCopy, ACQUI_NAME_REGEX) then
					pasteValue(acquiNameToGuid(currentCopy))
				end
				return true
			end
		end
	)

	eventCapture:start()
end

return obj
