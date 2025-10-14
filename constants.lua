local types = require("./types/main")
local PassengerNodeHandler = require("./nodes/passenger")
local DefaultNodeHandler = require("./nodes/default")
local ShopNodeHandler = require("./nodes/shop")
local ResourceNodeHandler = require("./nodes/resource")
local CombatNodeHandler = require("./nodes/enemy")
local StoryNodeHandler = require("./nodes/story")
local AnomalyNodeHandler = require("./nodes/anomaly")

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
		{ type = M.NODE_TYPES.Shop, weight = 10 },
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
			question = "You encounter a space trader.",
			characterImage = "assets/alienGuy1.png",
			-- should also just have fuel and other needs for sale
			handler = ShopNodeHandler,
		},
		{
			type = M.NODE_TYPES.Shop,
			question = "A friendly robot offers you some goods.",
			characterImage = "assets/robotGuy.png",
			handler = ShopNodeHandler,
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
			handler = AnomalyNodeHandler,
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
			image = "assets/dryPlanet.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.Anomaly,
			handler = AnomalyNodeHandler,
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
			image = "assets/dryPlanet.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			handler = AnomalyNodeHandler,
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
			image = "assets/dryPlanet.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			handler = AnomalyNodeHandler,
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
			image = "assets/dryPlanet.png",
			characterImage = "assets/spaceGuy.png",
		},
	},

	[M.NODE_TYPES.Combat] = {
		{
			type = M.NODE_TYPES.Combat,
			handler = CombatNodeHandler,
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
			image = "assets/planet.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.Combat,
			handler = CombatNodeHandler,
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
			image = "assets/planet.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.Combat,
			handler = CombatNodeHandler,
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
			image = "assets/planet.png",
			characterImage = "assets/spaceGuy.png",
		},
	},

	[M.NODE_TYPES.ResourceFind] = {
		{
			type = M.NODE_TYPES.ResourceFind,
			handler = ResourceNodeHandler,
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
			image = "assets/satellite.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.ResourceFind,
			handler = ResourceNodeHandler,
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
			image = "assets/satellite.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.ResourceFind,
			handler = ResourceNodeHandler,
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
			image = "assets/satellite.png",
			characterImage = "assets/spaceGuy.png",
		},
	},

	[M.NODE_TYPES.EmptySpace] = {
		{
			type = M.NODE_TYPES.EmptySpace,
			handler = DefaultNodeHandler,
			question = "At least you're not late for anything out here.",
			choices = {
				{
					text = "Continue",
					description = "No effect.",
					effect = function()
						print("Continuing through empty space.")
					end,
				},
			},
			image = "assets/emptySpace.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.EmptySpace,
			handler = DefaultNodeHandler,
			question = "You hum to yourself. The stars hum back.",
			choices = {
				{
					text = "Continue",
					description = "No effect.",
					effect = function()
						print("Continuing through empty space.")
					end,
				},
			},
			image = "assets/emptySpace.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.EmptySpace,
			handler = DefaultNodeHandler,
			question = "This part of the galaxy could really use a coffee shop.",
			choices = {
				{
					text = "Continue",
					description = "No effect.",
					effect = function()
						print("Continuing through empty space.")
					end,
				},
			},
			image = "assets/emptySpace.png",
			characterImage = "assets/spaceGuy.png",
		},
		{
			type = M.NODE_TYPES.EmptySpace,
			handler = DefaultNodeHandler,
			question = "The void stares back, unimpressed.",
			choices = {
				{
					text = "Continue",
					description = "No effect.",
					effect = function()
						print("Continuing through empty space.")
					end,
				},
			},
			image = "assets/emptySpace.png",
			characterImage = "assets/spaceGuy.png",
		},
	},

	[M.NODE_TYPES.Story] = {
		[0] = {
			type = M.NODE_TYPES.Story,
			handler = StoryNodeHandler,
			question = "Something faint hums through your comms...",
			segments = {
				{
					text = "You pick up a signal buried under static. Sounds like... someone trying to sing? Or cry? Hard to tell in space.",
					image = "assets/planet.png",
					choices = {
						{
							text = "Listen closer",
							description = "You turn up the gain (and regret it instantly).",
							effect = function()
								return "next"
							end,
						},
						{
							text = "Ignore the noise",
							description = "You've heard enough ghosts in the void.",
							effect = function(updateResource)
								updateResource("signals", 1)
								return "end"
							end,
						},
					},
				},
				{
					text = "A cracked voice breaks through: '...hello? Anyone out there? We... may have made a small planet-sized mistake...'.",
					image = "assets/planet.png",
					choices = {
						{
							text = "Record transmission",
							description = "You store the transmission. Could be worth something.",
							effect = function(updateResource)
								updateResource("signals", 1)
								return "end"
							end,
						},
					},
				},
			},
			image = "assets/planet.png",
			characterImage = "assets/spaceGuy.png",
		},

		[1] = {
			type = M.NODE_TYPES.Story,
			handler = StoryNodeHandler,
			question = "Your ship's radio picks up an ancient jingle.",
			segments = {
				{
					text = "'Buy one stardust smoothie, get the second free!' The ad's at least 400 years old.",
					image = "assets/planet.png",
					choices = {
						{
							text = "Sing along",
							description = "It's catchy. Too catchy.",
							effect = function()
								return "next"
							end,
						},
						{
							text = "Mute it fast",
							description = "You prefer silence over jingles from extinct smoothie chains.",
							effect = function(updateResource)
								updateResource("signals", 1)
								return "end"
							end,
						},
					},
				},
				{
					text = "Then - layered beneath the ad - a human distress call: 'Orion's Edge... survivors... bring the light... and smoothies if possible.'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Add to signal log",
							description = "Gain +1 signal.",
							effect = function(updateResource)
								updateResource("signals", 1)
								return "end"
							end,
						},
					},
				},
			},
		},

		[2] = {
			type = M.NODE_TYPES.Story,
			handler = StoryNodeHandler,
			question = "An alien podcast starts auto-playing on your ship.",
			segments = {
				{
					text = "'Welcome back to *Intergalactic Gossip Hour*! Today's hot topic - humans: extinct or just lazy?'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Keep listening",
							description = "You're mildly offended but also intrigued.",
							effect = function()
								return "next"
							end,
						},
					},
				},
				{
					text = "One host says, 'I heard they once put cheese on everything.' The other gasps. 'Even *plants*?!'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Note cultural misunderstanding",
							description = "Gain +1 signal. You chuckle quietly.",
							effect = function(updateResource)
								updateResource("signals", 1)
								if math.random() < 0.1 then
									updateResource("money", 1)
								end
								return "end"
							end,
						},
					},
				},
			},
		},

		[3] = {
			type = M.NODE_TYPES.Story,
			handler = StoryNodeHandler,
			question = "A beacon drifts by - marked 'Project HALCYON.'",
			segments = {
				{
					text = "A mechanical voice repeats, 'Please deposit your emotional baggage for re-entry clearance.'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Deposit... something?",
							description = "You toss in a half-eaten ration bar.",
							effect = function()
								return "next"
							end,
						},
					},
				},
				{
					text = "The beacon hums. 'Emotional baggage accepted. You may proceed to heal.'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Pat yourself on the back",
							description = "You feel oddly lighter. Gain +1 signal.",
							effect = function(updateResource)
								updateResource("signals", 1)
								if math.random() < 0.1 then
									updateResource("fuel", 1)
								end
								return "end"
							end,
						},
					},
				},
			},

			[4] = {
				type = M.NODE_TYPES.Story,
				handler = StoryNodeHandler,
				question = "Something is broadcasting old Earth music.",
				segments = {
					{
						text = "'Sweet Home Alabama' drifts through the void. You can't help but wonder what Alabama was.",
						image = "assets/planet.png",
						choices = {
							{
								text = "Jam out",
								description = "You tap your console like a drum.",
								effect = function()
									return "next"
								end,
							},
						},
					},
					{
						text = "After a long solo, a robotic voice says. 'This broadcast brought to you by... nobody. Everyone's gone.'",
						image = "assets/planet.png",
						choices = {
							{
								text = "Gain +1 signal",
								description = "That's the most depressing encore ever.",
								effect = function(updateResource)
									updateResource("signals", 1)
									return "end"
								end,
							},
						},
					},
				},
			},
		},
		[4] = {
			type = M.NODE_TYPES.Story,
			handler = StoryNodeHandler,
			question = "Something is broadcasting old Earth music.",
			segments = {
				{
					text = "'Sweet Home Alabama' drifts through the void. You can't help but wonder what Alabama was.",
					image = "assets/planet.png",
					choices = {
						{
							text = "Jam out",
							description = "You tap your console like a drum.",
							effect = function()
								return "next"
							end,
						},
					},
				},
				{
					text = "After a long solo, a robotic voice says, 'This broadcast brought to you by... nobody. Everyone's gone.'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Gain +1 signal",
							description = "That’s the most depressing encore ever.",
							effect = function(updateResource)
								updateResource("signals", 1)
								return "end"
							end,
						},
					},
				},
			},
		},
		[5] = {
			type = M.NODE_TYPES.Story,
			handler = StoryNodeHandler,
			question = "Your onboard AI starts talking in its sleep.",
			segments = {
				{
					text = "It mumbles something about 'saving the humans' and 'downloading a pizza recipe.'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Let it finish its dream",
							description = "You're not in the mood for digital therapy.",
							effect = function()
								return "next"
							end,
						},
					},
				},
				{
					text = "It suddenly wakes and says, 'You heard that? Uh... diagnostic complete. Totally fine.'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Pretend you didn't hear anything",
							description = "Gain +1 signal. Maybe +1 trust issues.",
							effect = function(updateResource)
								updateResource("signals", 1)
								if math.random() < 0.1 then
									updateResource("money", 1)
								end
								return "end"
							end,
						},
					},
				},
			},
		},

		[6] = {
			type = M.NODE_TYPES.Story,
			handler = StoryNodeHandler,
			question = "A transmission in an unknown language keeps repeating.",
			segments = {
				{
					text = "Your translator attempts to decode: 'Greetings from the Council of Mildly Irritated Aliens.'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Respond politely",
							description = "Never anger the mildly irritated.",
							effect = function()
								return "next"
							end,
						},
					},
				},
				{
					text = "Their reply: 'Apology accepted. Please stop crashing probes into our moons.'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Log the diplomatic win",
							description = "Gain +1 signal. Peace through confusion.",
							effect = function(updateResource)
								updateResource("signals", 1)
								if math.random() < 0.05 then
									updateResource("hull", 1)
								end
								return "end"
							end,
						},
					},
				},
			},
		},

		[7] = {
			type = M.NODE_TYPES.Story,
			handler = StoryNodeHandler,
			question = "You find an alien influencer's abandoned vlog channel.",
			segments = {
				{
					text = "'What's up starfolk! Today we're exploring abandoned human relics!' The screen shows... your ship?",
					image = "assets/planet.png",
					choices = {
						{
							text = "Subscribe",
							description = "Support alien creators.",
							effect = function()
								return "next"
							end,
						},
					},
				},
				{
					text = "'And that's how you hack their comms!' they cheer before the feed cuts out. Great.",
					image = "assets/planet.png",
					choices = {
						{
							text = "Gain +1 signal",
							description = "You feel both violated and entertained.",
							effect = function(updateResource)
								updateResource("signals", 1)
								return "end"
							end,
						},
					},
				},
			},
		},

		[8] = {
			type = M.NODE_TYPES.Story,
			handler = StoryNodeHandler,
			question = "Your ship detects a billboard in space.",
			segments = {
				{
					text = "'VISIT BEAUTIFUL ORION'S EDGE - NOW WITH 30% LESS COSMIC HORROR!'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Admire the marketing",
							description = "Can't argue with honesty.",
							effect = function()
								return "next"
							end,
						},
					},
				},
				{
					text = "Underneath the ad, faint distress pings echo - someone's still there.",
					image = "assets/planet.png",
					choices = {
						{
							text = "Mark the location",
							description = "Gain +1 signal. And a weird urge to book a vacation.",
							effect = function(updateResource)
								updateResource("signals", 1)
								if math.random() < 0.1 then
									updateResource("fuel", 1)
								end
								return "end"
							end,
						},
					},
				},
			},
		},

		[9] = {
			type = M.NODE_TYPES.Story,
			handler = StoryNodeHandler,
			question = "You reach the final broadcast.",
			segments = {
				{
					text = "A calm voice: 'If you're hearing this... humanity made it through. Barely. Please don't mess it up again.'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Send your own message back",
							description = "Something uplifting, maybe.",
							effect = function()
								return "next"
							end,
						},
					},
				},
				{
					text = "You record: 'Still here. Still weird. Still exploring.' A pause. Then: 'Good enough. Welcome home, explorer.'",
					image = "assets/planet.png",
					choices = {
						{
							text = "Smile and drift on",
							description = "Gain +1 signal. You’re part of the galaxy again.",
							effect = function(updateResource)
								updateResource("signals", 1)
								return "end"
							end,
						},
					},
				},
			},
		},
	},
}

M.PLANET_RADIUS = 150

return M
