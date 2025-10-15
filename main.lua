local types = require("./types/main")
local constants = require("./constants")
local eventManager = require("./eventManager")
local passengers = require("./passengers")
local animationSystem = require("./animationSystem")
AudioManager = require("./audio/audioManager")
local resourceAnimations = require("./animation")
local Button = require("./button")
local Modal = require("./modal")
local modal = nil
local Rocket = require("./rocket")
local PassengersMenu = require("./passengersMenu")
local WinImage = require("./winImage")
local ShipMenuButton = require("./shipMenuButton")
local parallax = require("./parallax")
local StartScene = require("./startScene")

local SETTINGS = {
	-- @todo implement settings for speeds, volumes, difficulties etc.
	-- currently some are just scattered
}

-- placeholder for player ship, currently no stats or upgrades
PlayerShip = {
	MAX_PASSENGERS = 3,
}

-- global vars/state shared between constants.luan for config
Resources = {
	fuel = constants.DEFAULT_RESOURCES.FUEL,
	oxygen = constants.DEFAULT_RESOURCES.OXYGEN,
	hull = constants.DEFAULT_RESOURCES.HULL,
	money = constants.DEFAULT_RESOURCES.MONEY,
	signals = constants.DEFAULT_RESOURCES.SIGNALS,
}

PlayerPassengers = {}
-- more game state vars
local PlayerPosition = { x = 0, y = 0 }
local CurrentNode = nil
local PreviouslyVisitedCoords = {}

-- Smooth parallax movement variables
local ParallaxPosition = { x = 0, y = 0 }
local ParallaxVelocity = { x = 0.5, y = 0.3 } -- Drift speed
local ParallaxTime = 0

local Menu = {
	navController = nil,
	layoutmanager = nil,
}

-- typing effect variables (should be localised)
local charIndex = 0
local typingSpeed = 0.01 -- Time in seconds between each character
local timer = 0
local displayedText = ""

-- moving nodes variables
local PreviousNode = nil
local PrevPlanetPosition = { x = 0, y = 0 }
Moving = false
Direction = nil
local NewPlanetPosition = { x = 0, y = 0 }

function markNodeAsVisited()
	table.insert(PreviouslyVisitedCoords, { x = PlayerPosition.x, y = PlayerPosition.y })
end

function updateResource(resourceType, amount)
	if Resources[resourceType] then
		if amount == 0 then
			return
		end
		Resources[resourceType] = Resources[resourceType] + amount
		if Resources[resourceType] < 0 then
			Resources[resourceType] = 0
		end
		eventManager.emit(resourceType .. "Updated", { amount = Resources[resourceType], change = amount })
	else
		print("Invalid resource type: " .. resourceType)
	end
end

function registerResourceListener(resourceType, callback)
	eventManager.on(resourceType .. "Updated", callback)
end

function resetGame()
	-- todo should force garbage collection of old nodes, passengers etc.
	-- by adding reset function to each and calling it here?
	PlayerPosition = { x = 0, y = 0 }
	Resources.fuel = constants.DEFAULT_RESOURCES.FUEL
	Resources.oxygen = constants.DEFAULT_RESOURCES.OXYGEN
	Resources.money = constants.DEFAULT_RESOURCES.MONEY
	Resources.hull = constants.DEFAULT_RESOURCES.HULL
	Resources.signals = constants.DEFAULT_RESOURCES.SIGNALS
	PreviouslyVisitedCoords = {}
	CurrentNode = nil
	PreviousNode = nil
	Moving = false
	PlayerPassengers = {}
	Rocket:reset()
	eventManager.reset()
	StoryIndex = 0
	StartScene:reset()
end

function getRandomNodeType()
	local probabilityTable = constants.Probabilities[types.GameStateType.Gameplay]
	local totalWeight = 0
	for _, option in ipairs(probabilityTable) do
		totalWeight = totalWeight + option.weight
	end
	local rand = math.random() * totalWeight
	local cumulativeWeight = 0
	for _, option in ipairs(probabilityTable) do
		cumulativeWeight = cumulativeWeight + option.weight
		if rand <= cumulativeWeight then
			return option.type
		end
	end
	return constants.NODE_TYPES.EmptySpace -- fallback
end

StoryIndex = 0

function getRandomNode()
	local nodeType = getRandomNodeType()

	-- sequential story nodes or not?
	-- comment this out for random again
	if nodeType == constants.NODE_TYPES.Story then
		StoryIndex = math.min(StoryIndex + 1, #constants.NODE_OPTIONS[nodeType] + 1)
		return constants.NODE_OPTIONS[nodeType][StoryIndex - 1]
	end

	local options = constants.NODE_OPTIONS[nodeType]
	if not options or #options == 0 then
		return nil
	end
	return options[math.random(1, #options)]
end

function love.load()
	-- we use the os time to seed the pseudo random
	-- engine otherwise it becomes predictable
	math.randomseed(os.time())
	parallax.load()

	love.graphics.setDefaultFilter("nearest")
	local navController = {
		navigateTo = function(self, state)
			GameState = state
		end,
	}

	-- init
	modal = Modal:new()

	Rocket:load()
	WinImage:load()
	StartScene:load(Menu)
	PassengersMenu:load(passengers)
	ShipMenuButton:load(modal, Rocket)

	-- loads once at start of game, setup game, and init/load assets etc.
	-- create new menu
	local layoutmanager = {
		buttons = {
			Button:new(love.graphics.getWidth() / 2 - 80, love.graphics.getHeight() / 2, "New game", 40, function()
				if love.mouse.isDown(1) and Menu.navController and Menu.navController.navigateTo then
					resetGame()
					ShipMenuButton:load(modal, Rocket)
					resourceAnimations.registerResourceAnimations(eventManager, animationSystem)
					AudioManager.play("menuClick")
					Menu.navController:navigateTo(types.GameStateType.Start)
				end
			end, { showBorder = true }),
			Button:new(
				love.graphics.getWidth() / 2 - 75,
				love.graphics.getHeight() / 2 + 80,
				"Continue",
				40,
				function()
					if love.mouse.isDown(1) and Menu.navController and Menu.navController.navigateTo then
						AudioManager.play("menuClick")
						Menu.navController:navigateTo(types.GameStateType.Gameplay)
					end
				end
			),
			Button:new(
				love.graphics.getWidth() / 2 - 90,
				love.graphics.getHeight() / 2 + 145,
				"Passengers",
				40,
				function()
					if love.mouse.isDown(1) and Menu.navController and Menu.navController.navigateTo then
						AudioManager.play("menuClick")
						Menu.navController:navigateTo(types.GameStateType.Passengers)
					end
				end
			),
		},
	}

	local largeFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 96)
	local smallFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 40)

	function layoutmanager:draw()
		love.graphics.clear(0.1, 0.1, 0.1, 1)
		drawSpaceBg()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(largeFont)
		love.graphics.printf(constants.GAME_TITLE, 0, 100, love.graphics.getWidth(), "center")

		for _, b in ipairs(self.buttons) do
			b:draw()
		end

		love.graphics.setFont(smallFont)
	end

	function layoutmanager:update(dt)
		local mx, my = love.mouse.getPosition()
		local mousePressed = love.mouse.isDown(1) -- left click
		for _, b in ipairs(self.buttons) do
			b:update(dt, mx, my, mousePressed)
		end
	end

	Menu.layoutmanager = layoutmanager
	Menu.navController = navController
	-- initial gamestate
	GameState = types.GameStateType.Menu

	-- Defining sound effects
	local soundTable = {
		click = "audio/Clicking.wav",
		menuClick = "audio/Menu Button Clicking.wav",
		buttonClick = "audio/Menu Button Clicking.wav",
	}
	local dynamicsTable = {
		shipEngineFlare = {
			fadeIn = "audio/Engine Flare Fade In.wav",
			loop = "audio/Engine Flare Loop.wav",
			fadeOut = "audio/Engine Flare Fade Out.wav",
			volume = 0.4,
		},
		muffledSpeaking = {
			fadeInDuration = 0.2,
			loop = "audio/Muffled Speaking.wav",
			fadeOutDuration = 0.2,
			volume = 0.5,
		},
	}
	local dynamicsTable = {
		shipEngineFlare = {
			fadeIn = "audio/Engine Flare Fade In.wav",
			loop = "audio/Engine Flare Loop.wav",
			fadeOut = "audio/Engine Flare Fade Out.wav",
			volume = 0.4,
		},
		muffledSpeaking = {
			fadeInDuration = 0.2,
			loop = "audio/Muffled Speaking.wav",
			fadeOutDuration = 0.2,
			volume = 0.5,
		},
		muffledSpeaking2 = {
			fadeInDuration = 0.2,
			loop = "audio/Muffled Speaking2.wav",
			fadeOutDuration = 0.2,
			volume = 0.5,
		},
		muffledSpeaking3 = {
			fadeInDuration = 0.2,
			loop = "audio/Muffled Speaking3.wav",
			fadeOutDuration = 0.2,
			volume = 0.5,
		},
	}

	-- Defining music tracks
	local musicTable = {
		soundtrack1 = "audio/Soundtrack 1 - Night Across The Stars.wav",
		soundtrack2 = "audio/Soundtrack 2 - Flashlight Evolving.wav",
		soundtrack3 = "audio/Soundtrack 3 - Space And Serenity.mp3",
		soundtrack4 = "audio/Soundtrack 4 - Space Blueberry Picking.mp3",
	}

	-- Loading audio
	AudioManager.load(soundTable, musicTable, dynamicsTable)

	-- Setting up continuous music playlist
	local playlist = { "soundtrack1", "soundtrack2", "soundtrack3", "soundtrack4" }
	for i = #playlist, 2, -1 do
		local j = math.random(i)
		playlist[i], playlist[j] = playlist[j], playlist[i]
	end
	AudioManager.setContinuousPlaylist(playlist, true)
	AudioManager.setWaitRange(10, 20)
	AudioManager.startContinuousMusic()
end

function isPreviouslyVisited(x, y)
	for _, coord in ipairs(PreviouslyVisitedCoords) do
		if coord.x == x and coord.y == y then
			return true
		end
	end
	return false
end

local CurrentPassengers = {
	SIZE = 120,
	buttons = {},
	update = function(self, dt)
		self.buttons = {}

		for i, p in ipairs(PlayerPassengers) do
			local newButton = Button:new(
				love.graphics.getWidth() / 2
					- (PlayerShip.MAX_PASSENGERS * self.SIZE) / 2
					+ (i - 1) * (self.SIZE + 10)
					+ self.SIZE
					- 25,
				13,
				"i",
				22,
				function()
					print("passenger info clicked" .. p.name)
					modal:open(function()
						local FULL_SIZE = 300
						local img = love.graphics.newImage(p.image)
						love.graphics.draw(
							img,
							love.graphics.getWidth() / 2 - FULL_SIZE / 3,
							30,
							0,
							FULL_SIZE / img:getWidth(),
							FULL_SIZE / img:getHeight()
						)
						love.graphics.printf(
							p.name,
							love.graphics.getWidth() / 2 - FULL_SIZE / 3,
							FULL_SIZE + 60,
							FULL_SIZE,
							"center"
						)
						love.graphics.printf(
							"Effects:",
							love.graphics.getWidth() / 2 - FULL_SIZE / 3,
							FULL_SIZE + 100,
							FULL_SIZE,
							"center"
						)
						love.graphics.printf(
							p.effectsDescription,
							love.graphics.getWidth() / 2 - FULL_SIZE / 3,
							FULL_SIZE + 140,
							FULL_SIZE,
							"center"
						)
					end)
				end,
				{ showBorder = true }
			)
			table.insert(self.buttons, newButton)
		end

		local mx, my = love.mouse.getPosition()
		local mousePressed = love.mouse.isDown(1)
		for _, button in ipairs(self.buttons) do
			button:update(dt, mx, my, mousePressed)
		end
	end,
	draw = function(self)
		for _, b in ipairs(self.buttons) do
			b:draw()
		end

		local PASSENGER_BOB_SPEED = 7
		local PASSENGER_BOB_OFFSET = 1
		local time = math.sin(love.timer.getTime() * PASSENGER_BOB_SPEED) * PASSENGER_BOB_OFFSET
		-- print current passengers at top middle of screen with names and images and empty slots
		for i = 1, PlayerShip.MAX_PASSENGERS do
			if PlayerPassengers[i] then
				local passenger = PlayerPassengers[i]
				local img = love.graphics.newImage(passenger.image)
				love.graphics.rectangle(
					"line",
					love.graphics.getWidth() / 2
						- (PlayerShip.MAX_PASSENGERS * self.SIZE) / 2
						+ (i - 1) * (self.SIZE + 10),
					10,
					self.SIZE,
					self.SIZE
				)
				love.graphics.draw(
					img,
					love.graphics.getWidth() / 2
						- (PlayerShip.MAX_PASSENGERS * self.SIZE) / 2
						+ (i - 1) * (self.SIZE + 10)
						+ 5,
					15 + (time + i * 3),
					0,
					(self.SIZE - 10) / img:getWidth(),
					(self.SIZE - 10) / img:getHeight()
				)
				love.graphics.setFont(love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 26))
				love.graphics.printf(
					passenger.name,
					love.graphics.getWidth() / 2
						- (PlayerShip.MAX_PASSENGERS * self.SIZE) / 2
						+ (i - 1) * (self.SIZE + 10),
					10 + self.SIZE + 10,
					self.SIZE + 10,
					"center"
				)
			else
				love.graphics.rectangle(
					"line",
					love.graphics.getWidth() / 2
						- (PlayerShip.MAX_PASSENGERS * self.SIZE) / 2
						+ (i - 1) * (self.SIZE + 10),
					10,
					self.SIZE,
					self.SIZE
				)
				love.graphics.printf(
					"Empty",
					love.graphics.getWidth() / 2
						- (PlayerShip.MAX_PASSENGERS * self.SIZE) / 2
						+ (i - 1) * (self.SIZE + 10),
					10 + self.SIZE + 10,
					self.SIZE + 10,
					"center"
				)
			end
		end
	end,
}
function love.update(dt)
	AudioManager.update(dt)

	-- Update smooth parallax position with gentle drift
	ParallaxTime = ParallaxTime + dt

	-- If planet is moving, add extra parallax movement in the direction of travel
	if Moving and Direction then
		ParallaxPosition.x = ParallaxPosition.x + (ParallaxVelocity.x + -Direction.x * 2) * dt
		ParallaxPosition.y = ParallaxPosition.y + (ParallaxVelocity.y + -Direction.y * 2) * dt
	else
		ParallaxPosition.x = ParallaxPosition.x + ParallaxVelocity.x * dt
		ParallaxPosition.y = ParallaxPosition.y + ParallaxVelocity.y * dt
	end

	-- Add some subtle sine wave motion for more organic movement
	local sineX = math.sin(ParallaxTime * 0.3) * 0.2
	local sineY = math.cos(ParallaxTime * 0.4) * 0.15

	parallax.update(dt, (ParallaxPosition.x + sineX) * 100, (ParallaxPosition.y + sineY) * 100)

	-- input handlng, game logic, calculations, updating positions etc.
	-- receives dt: deltatime arg, runs 60/ps, ie. every frame
	if GameState == types.GameStateType.Menu then
		Menu.layoutmanager:update(dt)
	elseif GameState == types.GameStateType.Passengers then
		if modal.active then
			modal:update(dt)
			return
		end
		PassengersMenu:update(dt)
		if love.keyboard.isDown("escape") then
			if Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.Menu)
			else
				print("NavController or navigateTo function not defined")
			end
		end
	elseif GameState == types.GameStateType.Gameplay then
		if PreviousNode == nil then
			CurrentNode = getRandomNode()
			PreviousNode = CurrentNode
			CurrentNode.handler:load(CurrentNode, modal, Rocket)
		end

		if Resources.fuel <= 0 then
			print("Out of fuel! Game Over.")
			if Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.GameOver)
			else
				print("NavController or navigateTo function not defined")
			end
			return
		elseif Resources.oxygen <= 0 then
			print("Out of oxygen! Game Over.")
			if Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.GameOver)
			else
				print("NavController or navigateTo function not defined")
			end
			return
		elseif Resources.signals >= constants.SIGNAL_TOTAL_GOAL then
			if Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.Win)
			end
			return
		end

		if modal.active then
			modal:update(dt)
			return
		end

		CurrentPassengers:update(dt)
		animationSystem:update(dt)
		Rocket:update(dt)
		ShipMenuButton:update(dt)

		-- this controls the pace of the game?
		local PLANET_SPEED = 1.5

		if Moving then
			-- update positions until new planet position reached and old one off screen
			PrevPlanetPosition.x = PrevPlanetPosition.x
				+ (Direction.x * love.graphics.getWidth() - PrevPlanetPosition.x) * dt * PLANET_SPEED
			PrevPlanetPosition.y = PrevPlanetPosition.y
				+ (Direction.y * love.graphics.getHeight() - PrevPlanetPosition.y) * dt * PLANET_SPEED
			NewPlanetPosition.x = NewPlanetPosition.x
				+ (Direction.x * love.graphics.getWidth() - NewPlanetPosition.x) * dt * PLANET_SPEED
			NewPlanetPosition.y = NewPlanetPosition.y
				+ (Direction.y * love.graphics.getHeight() - NewPlanetPosition.y) * dt * PLANET_SPEED

			-- once new planet at 0 and 0, stop moving
			if math.abs(NewPlanetPosition.x) < 50 and math.abs(NewPlanetPosition.y) < 50 then
				Moving = false
				PrevPlanetPosition = { x = 0, y = 0 }
				NewPlanetPosition = { x = 0, y = 0 }
				Direction = nil
			end
			return
		end

		local visited = isPreviouslyVisited(PlayerPosition.x, PlayerPosition.y)

		-- handle mouse click on choices
		if not visited and CurrentNode then
			local mx, my = love.mouse.getPosition()
			CurrentNode.handler:update(dt, eventManager, PassengersMenu, Rocket)
		end

		if love.keyboard.isDown("escape") then
			if Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.Menu)
			else
				print("NavController or navigateTo function not defined")
			end
		end

		local visited = false
		for _, coord in ipairs(PreviouslyVisitedCoords) do
			if coord.x == PlayerPosition.x and coord.y == PlayerPosition.y then
				visited = true
				break
			end
		end

		-- Track previous writing state for muffledSpeaking audio
		if not love.update_writing_state then
			love.update_writing_state = { writing = false }
		end

		if CurrentNode and not visited then
			-- typewriter effect for question

			timer = timer + dt

			local wasWriting = love.update_writing_state.writing
			local isWriting = charIndex < #CurrentNode.question

			if not wasWriting and isWriting then
				local wordCount = 0
				for _ in string.gmatch(CurrentNode.question, "%S+") do
					wordCount = wordCount + 1
				end
				local avgWordDuration = 0.2
				local soundDuration = wordCount * avgWordDuration
				local soundOptions = { "muffledSpeaking", "muffledSpeaking2", "muffledSpeaking3" }
				local soundToPlay = soundOptions[math.random(1, #soundOptions)]
				AudioManager.play(soundToPlay, soundDuration)
			end
			love.update_writing_state.writing = isWriting

			if charIndex < #CurrentNode.question and timer >= typingSpeed then
				charIndex = charIndex + 1
				displayedText = string.sub(CurrentNode.question, 1, charIndex)
				timer = 0 -- Reset timer for the next character
			end

			-- if at a node, do not allow movement until choice made
			return
		else
			if love.update_writing_state and love.update_writing_state.writing then
				love.update_writing_state.writing = false
			end
			charIndex = 0
			displayedText = ""
		end

		-- handle arrow key input
		if love.keyboard.isDown("left") then
			-- don't let players go beyond x=0 (starting line)
			if PlayerPosition.x <= -constants.MAX_WIDTH / 2 then
				return
			end

			PlayerPosition.x = math.max(PlayerPosition.x - 1, -constants.MAX_WIDTH / 2)
			handleNavigateToNewNode({ x = 1, y = 0 })
		elseif love.keyboard.isDown("right") then
			-- don't let players go beyond x=0 (starting line)
			if PlayerPosition.x >= constants.MAX_WIDTH / 2 then
				return
			end

			PlayerPosition.x = math.min(PlayerPosition.x + 1, constants.MAX_WIDTH / 2)
			handleNavigateToNewNode({ x = -1, y = 0 })
		elseif love.keyboard.isDown("up") then
			-- don't let players go above y=0 (starting line)
			if PlayerPosition.y <= -constants.MAX_WIDTH / 2 then
				return
			end

			PlayerPosition.y = math.max(PlayerPosition.y - 1, -constants.MAX_WIDTH / 2)
			handleNavigateToNewNode({ x = 0, y = 1 })
		elseif love.keyboard.isDown("down") then
			-- don't let players go below y=0 (starting line)
			if PlayerPosition.y >= constants.MAX_WIDTH / 2 then
				return
			end

			PlayerPosition.y = math.min(PlayerPosition.y + 1, constants.MAX_WIDTH / 2)
			handleNavigateToNewNode({ x = 0, y = -1 })
		end
	elseif GameState == types.GameStateType.Start then
		StartScene:update(dt)
	elseif GameState == types.GameStateType.Win or GameState == types.GameStateType.GameOver then
		WinImage:update(dt)
		if love.keyboard.isDown("escape") then
			if Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.Menu)
			else
				print("NavController or navigateTo function not defined")
			end
		end
	end
end

function love.keypressed(key)
	StartScene:keypressed(key)
end

function love.mousepressed(x, y, button, istouch, presses)
	if button == 1 then
		AudioManager.play("click")
	end
end

local moveCount = 0

function handleNavigateToNewNode(direction)
	updateResource("fuel", -constants.FUEL_CONSUMPTION_PER_MOVE)
	-- more passengers consumes more oxygen
	updateResource("oxygen", -(constants.OXYGEN_CONSUMPTION_PER_MOVE + #PlayerPassengers))

	moveCount = moveCount + 1
	eventManager.emit("move", moveCount)

	-- animate planet sliding off screen and new one sliding in
	Moving = true
	Direction = direction
	local offset = 3
	NewPlanetPosition =
		{ x = -direction.x * love.graphics.getWidth() * offset, y = -direction.y * love.graphics.getHeight() * offset }

	if CurrentNode ~= nil then
		PreviousNode = CurrentNode
	end
	CurrentNode = getRandomNode()
	if CurrentNode and CurrentNode.type ~= nil then
		local function capitalizeFirstLetter(str)
			if not str or #str == 0 then
				return str -- Handle empty or nil strings
			end
			return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
		end
		eventManager.emit("visited" .. capitalizeFirstLetter(CurrentNode.type) .. "Node")
	end
	if not CurrentNode or CurrentNode.handler == nil then
		return
	end
	CurrentNode.handler:load(CurrentNode, modal, Rocket)
end

function drawMinimap()
	-- print minimap of the game area in the top-right corner
	love.graphics.rectangle("line", love.graphics.getWidth() - 110, 10, 100, 100)
	-- mark previously visited coords on minimap
	for _, coord in ipairs(PreviouslyVisitedCoords) do
		love.graphics.setColor(0, 1, 0, 1)
		love.graphics.circle(
			"fill",
			love.graphics.getWidth() - 60 + (coord.x * constants.PLAYER_RADIUS),
			60 + (coord.y * constants.PLAYER_RADIUS),
			constants.PLAYER_RADIUS / 2
		)
		love.graphics.setColor(1, 1, 1, 1)
	end
	-- mark current player position on minimap
	love.graphics.circle(
		"fill",
		love.graphics.getWidth() - 60 + PlayerPosition.x * constants.PLAYER_RADIUS,
		60 + PlayerPosition.y * constants.PLAYER_RADIUS,
		constants.PLAYER_RADIUS / 2
	)
end

function processDrawingNodeType(currentNode)
	-- draw a reactangle box behind text for readability
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle(
		"fill",
		0,
		love.graphics.getHeight() / 2 + constants.PLANET_RADIUS + 10,
		love.graphics.getWidth(),
		constants.PLANET_RADIUS + 100
	)
	love.graphics.setColor(1, 1, 1, 1)

	local CHARACTER_IMAGE_BOB_SPEED = 10
	local CHARACTER_IMAGE_BOB_OFFSET = 2
	-- depending on node type, draw different things
	if currentNode.characterImage ~= nil then
		local CHARACTER_TALKING_SIZE_PIXELS = 200
		local time = math.sin(love.timer.getTime() * CHARACTER_IMAGE_BOB_SPEED) * CHARACTER_IMAGE_BOB_OFFSET
		local characterTalking = love.graphics.newImage(currentNode.characterImage)
		love.graphics.draw(
			characterTalking,
			10,
			love.graphics.getHeight() - (CHARACTER_TALKING_SIZE_PIXELS + 10) + time,
			0,
			CHARACTER_TALKING_SIZE_PIXELS / characterTalking:getWidth(),
			CHARACTER_TALKING_SIZE_PIXELS / characterTalking:getHeight()
		)
	end

	-- most nodes should have some text
	love.graphics.printf(
		displayedText,
		0,
		love.graphics.getHeight() / 2 + constants.PLANET_RADIUS + 20,
		love.graphics.getWidth(),
		"center"
	)

	if not CurrentNode or not CurrentNode.handler then
		return
	end
	CurrentNode.handler:draw()
end

function drawCurrentNode()
	-- rotate planet over time and slower
	local ROTATION_SPEED = 0.1
	local time = love.timer.getTime() * ROTATION_SPEED

	if Moving then
		if PreviousNode.image then
			local prevImg = love.graphics.newImage(PreviousNode.image)
			love.graphics.draw(
				prevImg,
				love.graphics.getWidth() / 2 + PrevPlanetPosition.x,
				love.graphics.getHeight() / 2 + PrevPlanetPosition.y,
				time % (math.pi * 2),
				(constants.PLANET_RADIUS * 2) / prevImg:getWidth(),
				(constants.PLANET_RADIUS * 2) / prevImg:getHeight(),
				prevImg:getWidth() / 2,
				prevImg:getHeight() / 2
			)
		end
		if CurrentNode.image then
			local newImg = love.graphics.newImage(CurrentNode.image)
			love.graphics.draw(
				newImg,
				love.graphics.getWidth() / 2 + NewPlanetPosition.x,
				love.graphics.getHeight() / 2 + NewPlanetPosition.y,
				time % (math.pi * 2),
				(constants.PLANET_RADIUS * 2) / newImg:getWidth(),
				(constants.PLANET_RADIUS * 2) / newImg:getHeight(),
				newImg:getWidth() / 2,
				newImg:getHeight() / 2
			)
		end
	elseif CurrentNode and CurrentNode.image then
		local curImg = love.graphics.newImage(CurrentNode.image)
		love.graphics.draw(
			curImg,
			love.graphics.getWidth() / 2,
			love.graphics.getHeight() / 2,
			time % (math.pi * 2),
			(constants.PLANET_RADIUS * 2) / curImg:getWidth(),
			(constants.PLANET_RADIUS * 2) / curImg:getHeight(),
			curImg:getWidth() / 2,
			curImg:getHeight() / 2
		)
	end

	-- if at a new node, show the question and choices under the planet
	local visited = isPreviouslyVisited(PlayerPosition.x, PlayerPosition.y)

	if Moving or not CurrentNode then
		return
	end

	if visited then
		love.graphics.printf(
			"You have already visited this location.",
			0,
			love.graphics.getHeight() / 2 + constants.PLANET_RADIUS + 20,
			love.graphics.getWidth(),
			"center"
		)
		return
	end

	processDrawingNodeType(CurrentNode)
end

function drawSpaceBg()
	-- load bg and always spin it opposite to planet?
	local BG_ROTATION_SPEED = -0.01
	local bgTime = love.timer.getTime() * BG_ROTATION_SPEED
	local bg
	-- Safely attempt to load the background image
	local success, imageOrError = pcall(love.graphics.newImage, "assets/bg.png")
	if success then
		bg = imageOrError
	else
		-- fallback: draw a solid color background if image is missing
		love.graphics.clear(0, 0, 0.1, 1)
		return
	end
	-- Double the size of the image
	local scaleX = (love.graphics.getWidth() * 1.3) / bg:getWidth()
	local scaleY = (love.graphics.getWidth() * 1.3) / bg:getHeight()
	-- Offset the rotation center for a cooler effect
	local offsetX = bg:getWidth() / 2 + 5
	local offsetY = bg:getHeight() / 2 + 5
	love.graphics.draw(
		bg,
		love.graphics.getWidth() / 2,
		love.graphics.getHeight() / 2,
		bgTime % (math.pi * 2),
		scaleX,
		scaleY,
		offsetX,
		offsetY
	)
end

function love.draw()
	-- update UI, drawing elements etc. after update runs
	-- runs after every love.update
	if GameState == types.GameStateType.Start then
		StartScene:draw()
	elseif GameState == types.GameStateType.Win then
		WinImage:draw()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(
			"Press ESC for Menu",
			0,
			love.graphics.getHeight() - 60,
			love.graphics.getWidth(),
			"center"
		)
	elseif GameState == types.GameStateType.GameOver then
		love.graphics.clear(0.5, 0, 0, 1)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf("Game Over!", 0, love.graphics.getHeight() / 2 - 50, love.graphics.getWidth(), "center")
		love.graphics.printf(
			"Press ESC for Menu",
			0,
			love.graphics.getHeight() / 2 + 10,
			love.graphics.getWidth(),
			"center"
		)
	elseif GameState == types.GameStateType.Menu then
		Menu.layoutmanager:draw()
	elseif GameState == types.GameStateType.Passengers then
		PassengersMenu:draw()

		local smallFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 24)
		love.graphics.setFont(smallFont)

		love.graphics.printf(
			"Press ESC for Menu",
			0,
			love.graphics.getHeight() - 20,
			love.graphics.getWidth(),
			"center"
		)
		modal:draw()
	elseif GameState == types.GameStateType.Gameplay then
		love.graphics.clear(0, 0, 0, 1)

		-- drawSpaceBg()
		parallax.draw()

		love.graphics.setFont(love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 26))
		love.graphics.print("Press ESC for Menu", 10, 10)
		love.graphics.print(
			"Use arrows to navigate",
			love.graphics.getWidth() / 2 - 100,
			love.graphics.getHeight() - 30
		)

		drawMinimap()

		-- print resources
		-- set bg as dark block colour rectangle behind text for readability
		love.graphics.setColor(0, 0, 0, 0.9)
		love.graphics.rectangle("fill", 0, 30, 200, 220)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 40))
		love.graphics.print("Signals: " .. Resources.signals .. "/" .. constants.SIGNAL_TOTAL_GOAL, 10, 40)
		love.graphics.print("Fuel: " .. Resources.fuel, 10, 80)
		love.graphics.print("Oxygen: " .. Resources.oxygen, 10, 120)
		love.graphics.print("Money: " .. Resources.money, 10, 160)
		love.graphics.print("Hull: " .. Resources.hull, 10, 200)
		love.graphics.setFont(love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 26))

		CurrentPassengers:draw()
		Rocket:draw()
		drawCurrentNode()
		animationSystem:draw()
		ShipMenuButton:draw()
		modal:draw()
	end
end
