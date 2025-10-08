-- event manager object to help manage all the resource updates and game state changes

Event = {
	listeners = {},
	_listenerId = 0,
}

function Event.on(eventName, callback)
	if not Event.listeners[eventName] then
		Event.listeners[eventName] = {}
	end
	Event._listenerId = Event._listenerId + 1
	local id = Event._listenerId
	Event.listeners[eventName][id] = callback
	-- return the unique id for later removal
	return id
end

function Event.emit(eventName, data)
	if Event.listeners[eventName] then
		-- Make a copy of keys to avoid issues if listeners are removed during emit
		local keys = {}
		for k in pairs(Event.listeners[eventName]) do
			table.insert(keys, k)
		end
		for _, k in ipairs(keys) do
			local callback = Event.listeners[eventName][k]
			if callback then
				callback(data)
			end
		end
	end
end

function Event.removeListener(eventName, id)
	if Event.listeners[eventName] and Event.listeners[eventName][id] then
		Event.listeners[eventName][id] = nil
	end
end

function Event.reset()
	Event.listeners = {}
	Event._listenerId = 0
end

return Event

