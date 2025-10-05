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
}
M.SIGNAL_TOTAL_GOAL = 5

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
			question = "You encounter a space trader. Do you want to buy fuel (+20) for 10 money (-10)?",
			choices = {
				{
					text = "Yes",
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
					text = "No",
					effect = function()
						print("Ignored trader")
					end,
				},
			},
			image = "alien.png",
			characterImage = "alien2.png",
			handler = DefaultNodeHandler,
		},
	},
	[M.NODE_TYPES.Passenger] = {
		{
			type = M.NODE_TYPES.Passenger,
			question = "You encounter 2 aliens seeking passage. Let one on board?",
			characterImage = "alien.png",
			handler = PassengerNodeHandler,
		},
	},
	[M.NODE_TYPES.Anomaly] = {
		{
			type = M.NODE_TYPES.Anomaly,
			handler = DefaultNodeHandler,
			question = "Spacial Rift",
			choices = {
				{
					text = "Investigate",
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
					effect = function()
						print("Ignored anomaly")
					end,
				},
			},
			image = "dryPlanet.png",
			characterImage = "alien2.png",
		},
		{
			type = M.NODE_TYPES.Anomaly,
			handler = DefaultNodeHandler,
			question = "Temporal echo...",
			choices = {
				{
					text = "Merge timelines",
					effect = function(updateResource)
						updateResource("fuel", -10)
						updateResource("signal", 1)
					end,
				},
				{
					text = "Ignore",
					effect = function()
						print("Ignored anomaly")
					end,
				},
			},
			image = "dryPlanet.png",
			characterImage = "alien2.png",
		},
		{
			handler = DefaultNodeHandler,
			type = M.NODE_TYPES.Anomaly,
			question = "Quantum storm",
			choices = {
				{
					text = "Stabilize with thrusters",
					effect = function(updateResource)
						updateResource("fuel", -5)
						updateResource("oxygen", 5)
					end,
				},
				{
					text = "Ride it out",
					effect = function()
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
			characterImage = "alien2.png",
		},
		{
			handler = DefaultNodeHandler,
			type = M.NODE_TYPES.Anomaly,
			question = "Graviton well",
			choices = {
				{
					text = "Escape (burn fuel)",
					effect = function(updateResource)
						updateResource("fuel", -5)
						updateResource("signal", 1)
					end,
				},
				{
					text = "Ride it out",
					effect = function()
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
			characterImage = "alien2.png",
		},
	},
	[M.NODE_TYPES.Combat] = {
		{
			type = M.NODE_TYPES.Combat,
			handler = DefaultNodeHandler,
			question = "You encounter Scavenger raiders!",
			choices = {
				{
					text = "Pay (-2 money)",
					effect = function(updateResource)
						local outcome = math.random()
						updateResource("money", -2)
					end,
				},
				{
					text = "Fight (-2 fuel, 50% -1 hull or 50% +3 money)",
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
					text = "Flee (-2 fuel, 50% -1 hull)",
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
			characterImage = "alien.png",
		},
		{
			type = M.NODE_TYPES.Combat,
			handler = DefaultNodeHandler,
			question = "You are ambushed by symbiotes",
			choices = {
				{
					text = "Accept merger (+10 oxygen, but O(2) drains faster -1 each jump)",
					effect = function(updateResource)
						local outcome = math.random()
						updateResource("oxygen", 10)
					end,
				},
				{
					text = "Burn it off (-5 fuel, -5 money)",
					effect = function(updateResource)
						updateResource("money", -5)
						updateResource("fuel", -5)
					end,
				},
			},
			image = "planet.png",
			characterImage = "alien.png",
		},
		{
			type = M.NODE_TYPES.Combat,
			handler = DefaultNodeHandler,
			question = "A space warload blocks your trajectory...",
			choices = {
				{
					text = "Duel (-3 fuel, -1 hull, +7 money)",
					effect = function(updateResource)
						updateResource("money", 7)
						updateResource("hull", -1)
						updateResource("fuel", -3)
					end,
				},
				{
					text = "Bribe (-3 money)",
					effect = function(updateResource)
						updateResource("money", -3)
					end,
				},
				{
					text = "Run (-3 fuel, 50% -2 hull)",
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
			characterImage = "alien.png",
		},
	},
	[M.NODE_TYPES.ResourceFind] = {
		{
			type = M.NODE_TYPES.ResourceFind,
			handler = DefaultNodeHandler,
			question = "You found a derelict ship.",
			choices = {
				{
					text = "Salvage",
					effect = function(updateResource)
						local outcome = math.random()
						updateResource("money", 3)
						if outcome < 0.3 then
							updateResource("hull", -1)
						end
					end,
				},
				{
					text = "Repair beacon",
					effect = function()
						updateResource("fuel", -3)
						updateResource("signal", 1)
					end,
				},
			},
			image = "satellite.png",
			characterImage = "alien2.png",
		},
		{
			type = M.NODE_TYPES.ResourceFind,
			handler = DefaultNodeHandler,
			question = "A broken shuttle drifts in the void",
			choices = {
				{
					text = "Board",
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
					text = "Salvage shell",
					effect = function()
						updateResource("fuel", 1)
					end,
				},
			},
			image = "satellite.png",
			characterImage = "alien2.png",
		},
		{
			type = M.NODE_TYPES.ResourceFind,
			handler = DefaultNodeHandler,
			question = "Sensors find asteroid mine",
			choices = {
				{
					text = "Mine",
					effect = function(updateResource)
						updateResource("fuel", 3)
						updateResource("hull", -1)
					end,
				},
				{
					text = "Power drill",
					effect = function()
						updateResource("fuel", -3)
						updateResource("money", 20)
					end,
				},
			},
			image = "satellite.png",
			characterImage = "alien2.png",
		},
	},
	[M.NODE_TYPES.EmptySpace] = {
		{
			type = M.NODE_TYPES.EmptySpace,
			handler = DefaultNodeHandler,
			question = "You are in empty space. Nothing happens.",
			choices = {
				{
					text = "Continue",
					effect = function()
						print("Continuing through empty space.")
					end,
				},
			},
			image = "emptySpace.png",
			characterImage = "alien2.png",
		},
	},
	[M.NODE_TYPES.Story] = {
		{
			type = M.NODE_TYPES.Story,
			handler = DefaultNodeHandler,
			question = "You receive a distress signal from a nearby planet. Do you want to investigate?",
			choices = {
				{
					text = "Yes",
					effect = function(updateResource)
						updateResource("signals", 1)
					end,
				},
				{
					text = "No",
					effect = function()
						print("Ignored distress signal")
					end,
				},
			},
			image = "planet.png",
			characterImage = "alien.png",
		},
	},
}

M.PLANET_RADIUS = 150

return M
