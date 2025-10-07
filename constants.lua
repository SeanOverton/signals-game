local types = require("./types/main")
local PassengerNodeHandler = require("./nodes/passenger")
local DefaultNodeHandler = require("./nodes/default")

local M = {}
M.GAME_TITLE = "Signals"
M.MAX_WIDTH = 10
M.PLAYER_RADIUS = 10
M.FUEL_CONSUMPTION_PER_MOVE = 1
M.OXYGEN_CONSUMPTION_PER_MOVE = 1
M.DEFAULT_RESOURCES = {
	FUEL = 30,
	OXYGEN = 100,
	MONEY = 50,
	SIGNALS = 0,
	HULL = 30,
}
M.SIGNAL_TOTAL_GOAL = 10

M.NODE_TYPES = {
	Passenger = "passenger",
	Shop = "shop",
	Anomaly = "anomaly",
	Combat = "combat",
	ResourceFind = "resourceFind",
	EmptySpace = "emptySpace",
	Story = "story",
}

M.Probabilities = {
	[types.GameStateType.Gameplay] = {
		{ type = M.NODE_TYPES.Passenger, weight = 10 },
		{ type = M.NODE_TYPES.Shop, weight = 5 },
		{ type = M.NODE_TYPES.Anomaly, weight = 15 },
		{ type = M.NODE_TYPES.Combat, weight = 10 },
		{ type = M.NODE_TYPES.ResourceFind, weight = 20 },
		{ type = M.NODE_TYPES.EmptySpace, weight = 30 },
		{ type = M.NODE_TYPES.Story, weight = 10 },
	},
}

-- config for choices at each planet, or spaceship or alien encounter etc.
M.NODE_OPTIONS = {
	[M.NODE_TYPES.Shop] = {
		{
			type = M.NODE_TYPES.Shop,
			question = "You encounter a space trader. Do you want to buy fuel?",
			choices = {
				{
					text = "Trade",
					description = "Spend 10 money to gain 20 fuel.",
					effect = function(updateResource)
						if Resources.money < 10 then
							print("Not enough money to buy fuel.")
							return
						end
						updateResource("money", -10)
						updateResource("fuel", 20)
					end,
				},
				{
					text = "Skip",
					description = "No effect. You ignore the trader.",
					effect = function()
						print("Ignored trader")
					end,
				},
			},
			image = "alien.png",
			characterImage = "assets/spaceGuy.png",
			handler = DefaultNodeHandler,
		},
	},

	[M.NODE_TYPES.Passenger] = {
		{
			type = M.NODE_TYPES.Passenger,
			question = "You encounter two aliens seeking passage. Let one on board?",
			characterImage = "assets/spaceGuy.png",
			description = "Choosing a passenger grants unique bonuses or penalties during travel.",
			handler = PassengerNodeHandler,
		},
	},

	[M.NODE_TYPES.Anomaly] = {
		{
			type = M.NODE_TYPES.Anomaly,
			handler = DefaultNodeHandler,
			question = "Spatial Rift detected ahead.",
			choices = {
				{
					text = "Investigate",
					description = "Gain +1 signal and lose either 10 fuel or 10 oxygen (50% chance).",
					effect = function(updateResource)
						local outcome = math.random()
						if outcome < 0.5 then
							updateResource("signal", 1)
							updateResource("fuel", -10)
						else
							updateResource("signal", 1)
							updateResource("oxygen", -10)
						end
					end,
				},
				{
					text = "Avoid",
					description = "No change to resources.",
					effect = function()
						print("Ignored anomaly")
					end,
				},
			},
			image = "dryPlanet.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.Anomaly,
			handler = DefaultNodeHandler,
			question = "Temporal echo... distorted signals nearby.",
			choices = {
				{
					text = "Merge timelines",
					description = "Lose 10 fuel and gain +1 signal.",
					effect = function(updateResource)
						updateResource("fuel", -10)
						updateResource("signal", 1)
					end,
				},
				{
					text = "Ignore",
					description = "No effect.",
					effect = function()
						print("Ignored anomaly")
					end,
				},
			},
			image = "dryPlanet.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			handler = DefaultNodeHandler,
			type = M.NODE_TYPES.Anomaly,
			question = "Quantum storm brewing ahead.",
			choices = {
				{
					text = "Stabilize",
					description = "Lose 5 fuel and gain +5 oxygen.",
					effect = function(updateResource)
						updateResource("fuel", -5)
						updateResource("oxygen", 5)
					end,
				},
				{
					text = "Ride it",
					description = "50% chance to gain +3 money or lose 3 fuel.",
					effect = function(updateResource)
						local random = math.random()
						if random < 0.5 then
							updateResource("money", 3)
						else
							updateResource("fuel", -3)
						end
					end,
				},
			},
			image = "dryPlanet.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			handler = DefaultNodeHandler,
			type = M.NODE_TYPES.Anomaly,
			question = "You're caught in a graviton well.",
			choices = {
				{
					text = "Escape",
					description = "Lose 5 fuel and gain +1 signal.",
					effect = function(updateResource)
						updateResource("fuel", -5)
						updateResource("signal", 1)
					end,
				},
				{
					text = "Endure",
					description = "Lose 1 hull and gain either +3 money or +3 oxygen (50% chance).",
					effect = function(updateResource)
						local random = math.random()
						if random < 0.5 then
							updateResource("hull", -1)
							updateResource("money", 3)
						else
							updateResource("hull", -1)
							updateResource("oxygen", 3)
						end
					end,
				},
			},
			image = "dryPlanet.png",
			characterImage = "assets/spaceGuy.png",
		},
	},

	[M.NODE_TYPES.Combat] = {
		{
			type = M.NODE_TYPES.Combat,
			handler = DefaultNodeHandler,
			question = "You encounter Scavenger raiders!",
			choices = {
				{
					text = "Pay",
					description = "Lose 2 money to avoid the fight.",
					effect = function(updateResource)
						updateResource("money", -2)
					end,
				},
				{
					text = "Fight",
					description = "Lose 2 fuel and either gain +3 money or lose 1 hull (50% chance).",
					effect = function(updateResource)
						updateResource("fuel", -2)
						local outcome = math.random()
						if outcome < 0.5 then
							updateResource("money", 3)
						else
							updateResource("hull", -1)
						end
					end,
				},
				{
					text = "Flee",
					description = "Lose 2 fuel and 50% chance to lose 1 hull.",
					effect = function(updateResource)
						updateResource("fuel", -2)
						local outcome = math.random()
						if outcome < 0.5 then
							updateResource("hull", -1)
						end
					end,
				},
			},
			image = "planet.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.Combat,
			handler = DefaultNodeHandler,
			question = "You are ambushed by symbiotes!",
			choices = {
				{
					text = "Merge",
					description = "Gain +10 oxygen but permanently lose 1 oxygen each jump.",
					effect = function(updateResource)
						updateResource("oxygen", 10)
					end,
				},
				{
					text = "Burn",
					description = "Lose 5 fuel and 5 money to destroy the symbiotes.",
					effect = function(updateResource)
						updateResource("money", -5)
						updateResource("fuel", -5)
					end,
				},
			},
			image = "planet.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.Combat,
			handler = DefaultNodeHandler,
			question = "A space warlord blocks your trajectory...",
			choices = {
				{
					text = "Duel",
					description = "Lose 3 fuel and 1 hull, gain +7 money.",
					effect = function(updateResource)
						updateResource("money", 7)
						updateResource("hull", -1)
						updateResource("fuel", -3)
					end,
				},
				{
					text = "Bribe",
					description = "Lose 3 money to pass safely.",
					effect = function(updateResource)
						updateResource("money", -3)
					end,
				},
				{
					text = "Run",
					description = "Lose 3 fuel and 50% chance to lose 2 hull.",
					effect = function(updateResource)
						updateResource("fuel", -3)
						local outcome = math.random()
						if outcome < 0.5 then
							updateResource("hull", -2)
						end
					end,
				},
			},
			image = "planet.png",
			characterImage = "assets/spaceGuy.png",
		},
	},

	[M.NODE_TYPES.ResourceFind] = {
		{
			type = M.NODE_TYPES.ResourceFind,
			handler = DefaultNodeHandler,
			question = "You find a derelict ship drifting nearby.",
			choices = {
				{
					text = "Salvage",
					description = "Gain +3 money and 30% chance to lose 1 hull.",
					effect = function(updateResource)
						local outcome = math.random()
						updateResource("money", 3)
						if outcome < 0.3 then
							updateResource("hull", -1)
						end
					end,
				},
				{
					text = "Repair",
					description = "Lose 3 fuel and gain +1 signal.",
					effect = function(updateResource)
						updateResource("fuel", -3)
						updateResource("signal", 1)
					end,
				},
			},
			image = "satellite.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.ResourceFind,
			handler = DefaultNodeHandler,
			question = "A broken shuttle drifts in the void.",
			choices = {
				{
					text = "Board",
					description = "50% chance to gain +15 oxygen or lose 2 hull.",
					effect = function(updateResource)
						local outcome = math.random()
						if outcome < 0.5 then
							updateResource("oxygen", 15)
						else
							updateResource("hull", -2)
						end
					end,
				},
				{
					text = "Salvage",
					description = "Gain +1 fuel.",
					effect = function(updateResource)
						updateResource("fuel", 1)
					end,
				},
			},
			image = "satellite.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.ResourceFind,
			handler = DefaultNodeHandler,
			question = "Sensors detect an asteroid mine.",
			choices = {
				{
					text = "Mine",
					description = "Gain +3 fuel and lose 1 hull.",
					effect = function(updateResource)
						updateResource("fuel", 3)
						updateResource("hull", -1)
					end,
				},
				{
					text = "Drill",
					description = "Lose 3 fuel and gain +20 money.",
					effect = function(updateResource)
						updateResource("fuel", -3)
						updateResource("money", 20)
					end,
				},
			},
			image = "satellite.png",
			characterImage = "assets/spaceGuy.png",
		},
	},

	[M.NODE_TYPES.EmptySpace] = {
		{
			type = M.NODE_TYPES.EmptySpace,
			handler = DefaultNodeHandler,
			question = "You drift through empty space. Nothing of note.",
			choices = {
				{
					text = "Continue",
					description = "No effect.",
					effect = function()
						print("Continuing through empty space.")
					end,
				},
			},
			image = "emptySpace.png",
			characterImage = "assets/spaceGuy.png",
		},
	},

	[M.NODE_TYPES.Story] = {
		{
			type = M.NODE_TYPES.Story,
			handler = DefaultNodeHandler,
			question = "A distress signal echoes from a nearby planet.",
			choices = {
				{
					text = "Investigate",
					description = "Gain +1 signal.",
					effect = function(updateResource)
						updateResource("signals", 1)
					end,
				},
				{
					text = "Ignore",
					description = "No effect.",
					effect = function()
						print("Ignored distress signal")
					end,
				},
			},
			image = "planet.png",
			characterImage = "assets/spaceGuy.png",
		},
	},
}

M.PLANET_RADIUS = 150

return M
