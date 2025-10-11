Passenger = {}
Passenger.__index = Passenger

function Passenger:new(name, image, effectTriggerEventName, effectCallback, effectsDescription)
	local obj = {
		name = name,
		image = image,
		listenerRef = nil,
		-- eventName that is triggered on the eventManager eg. resource update or something
		triggerEvent = effectTriggerEventName,
		-- the effect that is
		effectCallback = effectCallback,
		effectsDescription = effectsDescription,
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
local Trader = Passenger:new("Trader", "assets/alien2.png", "fuelUpdated", function()
	-- trigger animation indicating passenger effect has been called
	Resources.money = Resources.money + 1
end, "Gains +1 Money whenever Fuel is updated.")

local Scientist = Passenger:new("Scientist", "assets/alien.png", "signalsUpdated", function()
	Resources.oxygen = Resources.oxygen + 2
end, "Generates +2 Oxygen whenever Signals are updated.")

local Explorer = Passenger:new("Explorer", "assets/alien2.png", "moneyUpdated", function()
	Resources.fuel = Resources.fuel + 1
end, "Restores +1 Fuel whenever Money is updated.")

local FuelEater = Passenger:new("Fuel Eater", "assets/fuelEater.png", "move", function(index)
	if index % 3 == 0 then
		Resources.fuel = Resources.fuel + 1
	end
end, "Every 3rd move grants +1 Fuel.")

local Scrapbot = Passenger:new("Scrapbot", "assets/robot.png", "hullDamage", function()
	Resources.money = Resources.money + 1
end, "Converts Hull damage into +1 Money.")

local HitchhikerBlob = Passenger:new("Hitchhiker Blob", "assets/hitchhikerBlob.png", "sellBlob", function()
	Resources.money = Resources.money + 5
end, "Earns +5 Money when sold or interacted with.")

local SmugglerLizard = Passenger:new("Smuggler Lizard", "assets/lizard.png", "combatEnds", function()
	Resources.money = Resources.money + 5
end, "After combat ends, gain +5 Money.")

local CosmicGambler = Passenger:new("Cosmic Gambler", "assets/cosmicGambler.png", "onGamble", function()
	-- boost chance when gambling at the shops
end, "Increases luck and rewards when gambling at shops.")

local BreatherFungus = Passenger:new("Breather Fungus", "assets/mushroom.png", "move", function(index)
	if index % 2 == 0 then
		Resources.oxygen = Resources.oxygen + 1
	end
end, "Every 2nd move restores +1 Oxygen.")

local Stargazer = Passenger:new("Stargazer", "assets/stargazer.png", "signalsUpdated", function()
	Resources.signals = Resources.signals + 1
end, "Each signal update grants +1 Signal.")

local OxygenSniffer = Passenger:new("Oxygen Sniffer", "assets/oxygenSniffer.png", "visitedResourceFindNode", function()
	Resources.oxygen = Resources.oxygen + 1
end, "Visiting a Resource node grants +1 Oxygen.")

local Peach = Passenger:new("Peach", "assets/peach.png", "move", function()
	Resources.money = Resources.money + 2
end, "+2 money on every move")

local SpaceSlimy = Passenger:new("Space Slimy", "assets/snail.png", "move", function(index)
	if index % 2 == 0 then
		Resources.money = Resources.money - 1
	else
		Resources.fuel = Resources.fuel + 1
	end
end, "Alternates on each move -1 Money and +1 Fuel")

local VomitBob = Passenger:new("Vomit Bob", "assets/flubber.png", "move", function(index)
	Resources.hull = Resources.hull - 1
	Resources.money = Resources.money - 1
	Resources.fuel = Resources.fuel - 1
	local outcome = math.random()
	if outcome < 0.1 then
		Resources.signals = Resources.signals + 5
	end
end, "-1 on hull, money, fuel on every move BUT 10% chance of +5 signal")

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
	Peach,
	SpaceSlimy,
	VomitBob,
}

return M
