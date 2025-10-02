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

local FuelEater = Passenger:new("Fuel Eater", "fuelEater.png", "move", function(index)
	if index % 3 == 0 then
		Resources.fuel = Resources.fuel + 1
	end
end)

local Scrapbot = Passenger:new("Scrapbot", "robot.png", "hullDamage", function()
	Resources.money = Resources.money + 1
end)

local HitchhikerBlob = Passenger:new("Hitchhiker blob", "hitchhikerBlob.png", "sellBlob", function()
	Resources.money = Resources.money + 5
end)

local SmugglerLizard = Passenger:new("Smuggler Lizard", "lizard.png", "combatEnds", function()
	-- 50% chance of finding 2 money?
	Resources.money = Resources.money + 5
end)

local CosmicGambler = Passenger:new("Cosmic Gambler", "cosmicGambler.png", "onGamble", function()
	-- boost chance when gambling at the shops
end)

local BreatherFungus = Passenger:new("Breather Fungus", "mushroom.png", "jump", function(index)
	if index % 2 == 0 then
		Resources.oxygen = Resources.oxygen + 1
	end
end)

local Stargazer = Passenger:new("Stargazer", "stargazer.png", "signalUpdated", function()
	Resources.signals = Resources.signals + 1
end)

local OxygenSniffer = Passenger:new("Oxygen sniffer", "oxygenSniffer.png", "visitResourceFindNode", function()
	Resources.oxygen = Resources.oxygen + 1
end)

--export out public components ie. the actual passengers
local M = {
	Trader,
	Scientist,
	Explorer,
	FuelEater,
	Scrapbot,
	HitchhikerBlob,
	SmugglerLizard,
	CosmicGambler,
	BreatherFungus,
	Stargazer,
	OxygenSniffer,
}

return M
