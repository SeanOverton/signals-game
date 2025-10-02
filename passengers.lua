Passenger = {}
Passenger.__index = Passenger

function Passenger:new(name, image, effectTriggerEventName, effectCallback)
	local obj = {
		name = name,
		image = image,
		listenerRef = nil,
		-- eventName that is triggered on the eventManager eg. resource update or something
    triggerEvent = effectTriggerEventName,
    -- the effect that is 
		effectCallback = effectCallback,
	}
	setmetatable(obj, Passenger)
	return obj
end

function Passenger:register(eventManager)
	self.listenerRef = eventManager.on(self.triggerEvent, self.effectCallback)
end

function Passenger:deregister(eventManager)
	eventManager.removeListener(self.triggerEvent, self.listenerRef)
end

-- Trader passenger
local Trader = Passenger:new("Trader", "alien2.png", "fuelUpdated", function()
	Resources.money = Resources.money + 1
end)

local Scientist = Passenger:new("Scientist", "alien.png", "signalsUpdated", function()
	Resources.oxygen = Resources.oxygen + 2
end)

local Explorer = Passenger:new("Explorer", "alien2.png", "moneyUpdated", function()
	Resources.fuel = Resources.fuel + 1
end)

--export out public components ie. the actual passengers
local M = {
	Trader,
	Scientist,
	Explorer,
}

return M
