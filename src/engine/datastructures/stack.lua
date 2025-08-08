-- usage:
-- local myStack = Stack:new()
-- myStack:push(10)
-- myStack:push(20)
-- print(myStack:pop()) --> 20
-- print(myStack:pop()) --> 10
-- print(myStack:pop()) --> nil

-- local Stack = {}
Stack = Object:extend()
function Stack:init(item)
	self.items = {}
	self.items:insert(item)
end

function Stack:new()
	local obj = { items = {} }
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function Stack:push(item)
	table.insert(self.items, item)
end

function Stack:pop()
	if #self.items == 0 then
		return nil
	end
	return table.remove(self.items)
end

function Stack:peek(level)
	return self.items[#self.items - (level or 0)]
end

function Stack:is_empty()
	return #self.items == 0
end

function Stack:size()
	return #self.items
end

return Stack
