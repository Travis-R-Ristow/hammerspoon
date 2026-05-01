local obj = {}
obj.__index = obj

obj.name = "FocusIndicator"
obj.version = "0.1"
obj.author = "Travis R"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local canvas = nil
local windowFilter = nil
local menuBar = nil
local flashTimer = nil

local SETTINGS_KEY = "FocusIndicator"

local function loadSetting(key, default)
	local val = hs.settings.get(SETTINGS_KEY .. "." .. key)
	if val == nil then
		return default
	end
	return val
end

local function saveSetting(key, value)
	hs.settings.set(SETTINGS_KEY .. "." .. key, value)
end

local currentMode = loadSetting("mode", "alwaysVisible")
local currentStyle = loadSetting("style", "corners")
local currentColorName = loadSetting("color", "Green")
local flashDuration = 1.5

local sizePresets = {
	{ name = "Small", length = 20, thickness = 2 },
	{ name = "Medium", length = 40, thickness = 3 },
	{ name = "Large", length = 60, thickness = 4 },
}
local currentSizeName = loadSetting("size", "Small")
local markerLength = sizePresets[1].length
local markerThickness = sizePresets[1].thickness

for _, preset in ipairs(sizePresets) do
	if preset.name == currentSizeName then
		markerLength = preset.length
		markerThickness = preset.thickness
		break
	end
end

local colorMap = {
	Green = { red = 0.2, green = 0.84, blue = 0.29, alpha = 1 },
	Blue = { red = 0.04, green = 0.52, blue = 1, alpha = 1 },
	Red = { red = 1, green = 0.27, blue = 0.23, alpha = 1 },
	White = { white = 1, alpha = 1 },
	Yellow = { red = 1, green = 0.84, blue = 0, alpha = 1 },
	Orange = { red = 1, green = 0.58, blue = 0, alpha = 1 },
	Purple = { red = 0.69, green = 0.32, blue = 0.87, alpha = 1 },
	Cyan = { red = 0.35, green = 0.78, blue = 0.98, alpha = 1 },
}

local colorOrder = { "Green", "Blue", "Red", "White", "Yellow", "Orange", "Purple", "Cyan" }

local function buildElements(w, h, color)
	local el = function(frame)
		return { type = "rectangle", action = "fill", fillColor = color, frame = frame }
	end
	local zero = { x = 0, y = 0, w = 0, h = 0 }

	if currentStyle == "full" then
		return {
			el({ x = 0, y = 0, w = w, h = markerThickness }),
			el({ x = 0, y = h - markerThickness, w = w, h = markerThickness }),
			el({ x = 0, y = 0, w = markerThickness, h = h }),
			el({ x = w - markerThickness, y = 0, w = markerThickness, h = h }),
			el(zero),
			el(zero),
			el(zero),
			el(zero),
		}
	end

	return {
		el({ x = 0, y = 0, w = markerLength, h = markerThickness }),
		el({ x = 0, y = 0, w = markerThickness, h = markerLength }),
		el({ x = w - markerLength, y = 0, w = markerLength, h = markerThickness }),
		el({ x = w - markerThickness, y = 0, w = markerThickness, h = markerLength }),
		el({ x = 0, y = h - markerThickness, w = markerLength, h = markerThickness }),
		el({ x = 0, y = h - markerLength, w = markerThickness, h = markerLength }),
		el({ x = w - markerLength, y = h - markerThickness, w = markerLength, h = markerThickness }),
		el({ x = w - markerThickness, y = h - markerLength, w = markerThickness, h = markerLength }),
	}
end

local function updateElementPositions(w, h)
	local color = colorMap[currentColorName]
	local elements = buildElements(w, h, color)
	for i, el in ipairs(elements) do
		canvas[i].frame = el.frame
	end
end

local function hideMarkers()
	if canvas then
		canvas:hide()
	end
	if flashTimer then
		flashTimer:stop()
		flashTimer = nil
	end
end

local function showMarkers()
	if not canvas then
		return
	end

	if currentMode == "alwaysVisible" then
		canvas:alpha(1)
		canvas:show()
	elseif currentMode == "flashOnChange" then
		if flashTimer then
			flashTimer:stop()
			flashTimer = nil
		end
		canvas:alpha(1)
		canvas:show()
		flashTimer = hs.timer.doAfter(flashDuration, function()
			hideMarkers()
		end)
	end
end

local function updateMarkers()
	local win = hs.window.focusedWindow()
	if not win then
		hideMarkers()
		return
	end

	if win:isMinimized() then
		hideMarkers()
		return
	end

	local f = win:frame()
	if not f or f.w == 0 or f.h == 0 then
		hideMarkers()
		return
	end

	canvas:frame(f)
	updateElementPositions(f.w, f.h)
	showMarkers()
end

local function applyColor(colorName)
	currentColorName = colorName
	saveSetting("color", colorName)
	local color = colorMap[colorName]
	if canvas then
		for i = 1, 8 do
			canvas[i].fillColor = color
		end
	end
end

local function applySize(sizeName)
	currentSizeName = sizeName
	saveSetting("size", sizeName)
	for _, preset in ipairs(sizePresets) do
		if preset.name == sizeName then
			markerLength = preset.length
			markerThickness = preset.thickness
			break
		end
	end
	updateMarkers()
end

local function createMenuBarIcon()
	local size = 20
	local len = 6
	local thick = 1.5
	local color = { white = 1 }
	local iconCanvas = hs.canvas.new({ x = 0, y = 0, w = size, h = size })
	local corners = {
		{ x = 1, y = 1, w = len, h = thick },
		{ x = 1, y = 1, w = thick, h = len },
		{ x = size - len - 1, y = 1, w = len, h = thick },
		{ x = size - thick - 1, y = 1, w = thick, h = len },
		{ x = 1, y = size - thick - 1, w = len, h = thick },
		{ x = 1, y = size - len - 1, w = thick, h = len },
		{ x = size - len - 1, y = size - thick - 1, w = len, h = thick },
		{ x = size - thick - 1, y = size - len - 1, w = thick, h = len },
	}
	for _, frame in ipairs(corners) do
		iconCanvas:insertElement({ type = "rectangle", action = "fill", fillColor = color, frame = frame })
	end
	local icon = iconCanvas:imageFromCanvas():template(true)
	iconCanvas:delete()
	return icon
end

local function createCanvas()
	canvas = hs.canvas.new({ x = 0, y = 0, w = 1, h = 1 })
	local color = colorMap[currentColorName]
	local elements = buildElements(1, 1, color)
	for _, el in ipairs(elements) do
		canvas:insertElement(el)
	end
	canvas:level(hs.canvas.windowLevels.overlay)
	canvas:behavior({ "transient", "canJoinAllSpaces" })
	canvas:clickActivating(false)
	canvas:canvasMouseEvents(false, false)
end

local function buildMenuTable()
	local menu = {
		{ title = "Behavior", disabled = true },
		{
			title = "Always Visible",
			checked = (currentMode == "alwaysVisible"),
			fn = function()
				currentMode = "alwaysVisible"
				saveSetting("mode", currentMode)
				updateMarkers()
			end,
		},
		{
			title = "Flash on Change",
			checked = (currentMode == "flashOnChange"),
			fn = function()
				currentMode = "flashOnChange"
				saveSetting("mode", currentMode)
				hideMarkers()
			end,
		},
		{ title = "-" },
		{ title = "Style", disabled = true },
		{
			title = "Corners",
			checked = (currentStyle == "corners"),
			fn = function()
				currentStyle = "corners"
				saveSetting("style", currentStyle)
				updateMarkers()
			end,
		},
		{
			title = "Full Border",
			checked = (currentStyle == "full"),
			fn = function()
				currentStyle = "full"
				saveSetting("style", currentStyle)
				updateMarkers()
			end,
		},
		{ title = "-" },
		{ title = "Size", disabled = true },
	}

	for _, preset in ipairs(sizePresets) do
		table.insert(menu, {
			title = preset.name,
			checked = (currentSizeName == preset.name),
			fn = function()
				applySize(preset.name)
			end,
		})
	end

	table.insert(menu, { title = "-" })
	table.insert(menu, { title = "Color", disabled = true })

	for _, name in ipairs(colorOrder) do
		table.insert(menu, {
			title = name,
			checked = (currentColorName == name),
			fn = function()
				applyColor(name)
				if currentMode == "alwaysVisible" then
					updateMarkers()
				end
			end,
		})
	end

	return menu
end

function obj:init()
	createCanvas()

	menuBar = hs.menubar.new()
	menuBar:setIcon(createMenuBarIcon())
	menuBar:setMenu(buildMenuTable)

	windowFilter = hs.window.filter.new()

	windowFilter:subscribe(hs.window.filter.windowFocused, function()
		updateMarkers()
	end)

	windowFilter:subscribe(hs.window.filter.windowUnfocused, function()
		hideMarkers()
	end)

	windowFilter:subscribe(hs.window.filter.windowMoved, function(win)
		local focused = hs.window.focusedWindow()
		if focused and win:id() == focused:id() then
			updateMarkers()
		end
	end)

	updateMarkers()
end

return obj
