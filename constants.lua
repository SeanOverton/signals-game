local types = require("./types/main")
local M = {}

M.GAME_TITLE = "Signals"
M.MAX_WIDTH = 10
M.PLAYER_RADIUS = 10
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

-- these add effects to the resources when on board
M.Passengers = {
	{
		name = "Trader",
		effectMultipliers = {
			fuel = 1.2,
			oxygen = 1.0,
			money = 1.5,
			signals = 1.0,
		},
		image = "alien.png",
	},
	{
		name = "Scientist",
		effectMultipliers = {
			fuel = 1.0,
			oxygen = 1.2,
			money = 1.0,
			signals = 1.5,
		},
		image = "alien.png",
	},
	{
		name = "Explorer",
		effectMultipliers = {
			fuel = 1.5,
			oxygen = 1.0,
			money = 1.0,
			signals = 1.2,
		},
		image = "alien.png",
	},
}

-- config for choices at each planet, or spaceship or alien encounter etc.
M.NODE_OPTIONS = {
	[M.NODE_TYPES.Shop] = {
		{
			question = "You encounter a space trader. Do you want to buy fuel for 10 money?",
			choices = {
				{
					text = "Yes",
					effect = function()
						if Resources.money < 10 then
							print("Not enough money to buy fuel.")
							return
						end
						Resources.money = Resources.money - 10
						Resources.fuel = Resources.fuel + 20
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
            characterImage = "alien.png",
		},
	},
	[M.NODE_TYPES.Passenger] = {
		{
			type = M.NODE_TYPES.Passenger,
			question = "You encounter 2 aliens seeking passage. Which one will you let on board?",
			choices = {
				{
                    value = M.Passengers[1],
				},
				{
                    value = M.Passengers[2],
				},
				{
                    value = M.Passengers[3],
				},
			},
			image = "alien.png",
            characterImage = "alien.png",
		},
	},
	[M.NODE_TYPES.Anomaly] = {
		{
			question = "You encounter a space anomaly. Do you want to investigate?",
			choices = {
				{
					text = "Yes",
					effect = function()
						local outcome = math.random()
						if outcome < 0.5 then
							print("You found a fuel cache! +20 fuel")
							Resources.fuel = Resources.fuel + 20
						else
							print("The anomaly damaged your ship! -10 oxygen")
							Resources.oxygen = Resources.oxygen - 10
						end
					end,
				},
				{
					text = "No",
					effect = function()
						print("Ignored anomaly")
					end,
				},
			},
			image = "planet.png",
            characterImage = "alien.png",
		},
	},
	[M.NODE_TYPES.Combat] = {
		{
			question = "You are ambushed by space pirates! Do you want to fight or flee?",
			choices = {
				{
					text = "Fight",
					effect = function()
						local outcome = math.random()
						if outcome < 0.5 then
							print("You defeated the pirates! +20 money")
							Resources.money = Resources.money + 20
						else
							print("You were injured in the fight! -20 oxygen")
							Resources.oxygen = Resources.oxygen - 20
						end
					end,
				},
				{
					text = "Flee",
					effect = function()
						print("You fled but lost some fuel! -10 fuel")
						Resources.fuel = Resources.fuel - 10
					end,
				},
			},
			image = "planet.png",
            characterImage = "alien.png",
		},
	},
	[M.NODE_TYPES.ResourceFind] = {
		{
			question = "You found a derelict ship. Do you want to scavenge it?",
			choices = {
				{
					text = "Yes",
					effect = function()
						local outcome = math.random()
						if outcome < 0.5 then
							print("You found supplies! +15 oxygen")
							Resources.oxygen = Resources.oxygen + 15
						else
							print("The ship was empty.")
						end
					end,
				},
				{
					text = "No",
					effect = function()
						print("Ignored derelict ship")
					end,
				},
			},
			image = "planet.png",
            characterImage = "planet.png",
		},
	},
	[M.NODE_TYPES.EmptySpace] = {
		{
			question = "You are in empty space. Nothing happens.",
			choices = {
				{
					text = "Continue",
					effect = function()
						print("Continuing through empty space.")
					end,
				},
			},
			image = "planet.png",
            characterImage = "planet.png",
		},
	},
	[M.NODE_TYPES.Story] = {
		{
			question = "You receive a distress signal from a nearby planet. Do you want to investigate?",
			choices = {
				{
					text = "Yes",
					effect = function()
						print("You rescued survivors! +1 signal")
						Resources.signals = Resources.signals + 1
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
            characterImage = "planet.png",
		},
	},
}

M.PLANET_RADIUS = 120

return M