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
local maxSize = 5

function obj:init()
	self.eventtap = hs.eventtap.new(
		{ hs.eventtap.event.types.keyUp, hs.eventtap.event.types.flagsChanged },
		function(event)
			local flags = event:getFlags()
			local keyCode = event:getKeyCode()

			if flags.cmd and keyCode == hs.keycodes.map["C"] then
				local copyCtx = hs.pasteboard.getContents()
				if #clipboardHistory < maxSize then
					table.insert(clipboardHistory, copyCtx)
					print(copyCtx)
				else
					table.remove(clipboardHistory, 1)
					table.insert(clipboardHistory, copyCtx)
				end
				for k, v in pairs(clipboardHistory) do
					print("Key:", k, "Value:", v)
				end
			end
		end
	)

	self.eventtap:start()
end

return obj
