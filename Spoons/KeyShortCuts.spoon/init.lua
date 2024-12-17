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
end

return obj
