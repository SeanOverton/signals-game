local types = require("./types/main")
local constants = require("./constants")
local eventManager = require("./eventManager")
local passengers = require("./passengers")
local animationSystem = require("./animationSystem")
local resourceAnimations = require("./animation")

local SETTINGS = {
	-- @todo implement settings for speeds, volumes, difficulties etc.
	-- currently some are just scattered
}

-- placeholder for player ship, currently no stats or upgrades
local PlayerShip = {
	MAX_PASSENGERS = 3,
}

-- global vars/state shared between constants.luan for config
Resources = {
	fuel = constants.DEFAULT_RESOURCES.FUEL,
	oxygen = constants.DEFAULT_RESOURCES.OXYGEN,
	money = constants.DEFAULT_RESOURCES.MONEY,
	signals = constants.DEFAULT_RESOURCES.SIGNALS,
}

PlayerPassengers = {}
-- more game state vars
local PlayerPosition = { x = 0, y = 0 }
local CurrentNode = nil
local PreviouslyVisitedCoords = {}

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
local Moving = false
local Direction = nil
local NewPlanetPosition = { x = 0, y = 0 }

function markNodeAsVisited()
	table.insert(PreviouslyVisitedCoords, { x = PlayerPosition.x, y = PlayerPosition.y })
end

local PassengerNodeHandler = {
	randomPassengers = {},
	BUTTON_SIZE_PIXELS = 240,
	load = function(self)
		-- initiliases anything for the node when it is randomly selected
		-- eg. random choices or shop stuff etc.
		local randomPassengers = {}
		while #randomPassengers < math.min(#passengers, 2) do
			local candidate = passengers[math.random(1, #passengers)]
			local alreadyChosen = false
			for _, p in ipairs(randomPassengers) do
				if p.name == candidate.name then
					alreadyChosen = true
					break
				end
			end
			if not alreadyChosen then
				table.insert(randomPassengers, candidate)
			end
		end
		self.randomPassengers = randomPassengers
	end,
	update = function(self, dt)
		-- handle passenger specific updates if needed
		-- passenger choices have images
		-- event handlers for anything drawn
		-- also handle anything else specific to the node logic
		for i, passenger in ipairs(self.randomPassengers) do
			if passenger then
				-- handle mouse click on passenger choice
				if love.mouse.isDown(1) then
					local mx, my = love.mouse.getPosition()
					local x = love.graphics.getWidth() / 2 - self.BUTTON_SIZE_PIXELS + (i - 1) * 250
					local y = love.graphics.getHeight() / 2 - 140
					local w = self.BUTTON_SIZE_PIXELS
					local h = self.BUTTON_SIZE_PIXELS
					if mx >= x and mx <= x + w and my >= y and my <= y + h then
						-- add passenger to Passenger list if space
						if #PlayerPassengers >= PlayerShip.MAX_PASSENGERS then
							-- update your first passenger to new one
							local removedPassenger = table.remove(PlayerPassengers, 1)
							if removedPassenger and removedPassenger.deregister then
								removedPassenger:deregister(eventManager)
							end
						end
						table.insert(PlayerPassengers, passenger)
						if passenger.register then
							passenger:register(eventManager)
						end
						markNodeAsVisited()
					end
				end
			end
		end
	end,
	draw = function(self)
		-- draws node specific stuff, ie. choices here... todo move more here?
		for i, passenger in ipairs(self.randomPassengers) do
			local img = love.graphics.newImage(passenger.image)
			love.graphics.rectangle(
				"line",
				love.graphics.getWidth() / 2 - self.BUTTON_SIZE_PIXELS + (i - 1) * 250,
				love.graphics.getHeight() / 2 - 140,
				self.BUTTON_SIZE_PIXELS,
				self.BUTTON_SIZE_PIXELS
			)
			love.graphics.draw(
				img,
				love.graphics.getWidth() / 2 - self.BUTTON_SIZE_PIXELS + (i - 1) * 250,
				love.graphics.getHeight() / 2 - 140,
				0,
				self.BUTTON_SIZE_PIXELS / img:getWidth(),
				self.BUTTON_SIZE_PIXELS / img:getHeight()
			)
			love.graphics.printf(
				passenger.name,
				love.graphics.getWidth() / 2 - self.BUTTON_SIZE_PIXELS + (i - 1) * 250,
				love.graphics.getHeight() / 2 + 110,
				self.BUTTON_SIZE_PIXELS,
				"center"
			)
		end
	end,
}

function updateResource(resourceType, amount)
	if Resources[resourceType] then
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
	Resources.signals = constants.DEFAULT_RESOURCES.SIGNALS
	PreviouslyVisitedCoords = {}
	CurrentNode = nil
	PreviousNode = nil
	Moving = false
	PlayerPassengers = {}
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

function getRandomNode()
	local nodeType = getRandomNodeType()
	local options = constants.NODE_OPTIONS[nodeType]
	if not options or #options == 0 then
		return nil
	end
	return options[math.random(1, #options)]
end

function love.load()
	love.graphics.setDefaultFilter("nearest")
	local navController = {
		navigateTo = function(self, state)
			GameState = state
		end,
	}

	resourceAnimations.registerResourceAnimations(eventManager, animationSystem)

	-- loads once at start of game, setup game, and init/load assets etc.
	-- create new menu
	local layoutmanager = {
		hover = nil,
	}

	local largeFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 96)
	local smallFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 40)

	function layoutmanager:draw()
		love.graphics.clear(0.1, 0.1, 0.1, 1)
		drawSpaceBg()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(largeFont)
		love.graphics.printf(constants.GAME_TITLE, 0, 100, love.graphics.getWidth(), "center")

		local buttonWidth = 200
		love.graphics.rectangle(
			"line",
			love.graphics.getWidth() / 2 - (self.hover == "new_game" and 100 or 75),
			love.graphics.getHeight() / 2 - 25,
			self.hover == "new_game" and buttonWidth + 50 or buttonWidth,
			self.hover == "new_game" and 70 or 50
		)

		love.graphics.setFont(smallFont)

		if self.hover == "new_game" then
			love.graphics.setFont(love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 50))
		else
			love.graphics.setFont(smallFont)
		end
		love.graphics.printf(
			"New Game",
			love.graphics.getWidth() / 2 - 75,
			love.graphics.getHeight() / 2 - 10,
			buttonWidth,
			"center"
		)

		if self.hover == "continue" then
			love.graphics.setFont(love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 50))
		else
			love.graphics.setFont(smallFont)
		end
		love.graphics.printf(
			"Continue",
			love.graphics.getWidth() / 2 - 75,
			love.graphics.getHeight() / 2 + 100,
			buttonWidth,
			"center"
		)

		love.graphics.setFont(smallFont)
	end
	function layoutmanager:update(dt)
		local mx, my = love.mouse.getPosition()
		if
			mx >= love.graphics.getWidth() / 2 - 50
			and mx <= love.graphics.getWidth() / 2 + 50
			and my >= love.graphics.getHeight() / 2 - 25
			and my <= love.graphics.getHeight() / 2 + 25
		then
			if love.mouse.isDown(1) and Menu.navController and Menu.navController.navigateTo then
				resetGame()
				Menu.navController:navigateTo(types.GameStateType.Gameplay)
			else
				self.hover = "new_game"
			end
		elseif
			mx >= love.graphics.getWidth() / 2 - 50
			and mx <= love.graphics.getWidth() / 2 + 50
			and my >= love.graphics.getHeight() / 2 + 100
			and my <= love.graphics.getHeight() / 2 + 150
		then
			if love.mouse.isDown(1) and Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.Gameplay)
			else
				self.hover = "continue"
			end
		else
			self.hover = nil
		end
	end
	Menu.layoutmanager = layoutmanager
	Menu.navController = navController
	GameState = types.GameStateType.Menu
end

function isPreviouslyVisited(x, y)
	for _, coord in ipairs(PreviouslyVisitedCoords) do
		if coord.x == x and coord.y == y then
			return true
		end
	end
	return false
end

function love.update(dt)
	-- input handlng, game logic, calculations, updating positions etc.
	-- receives dt: deltatime arg, runs 60/ps, ie. every frame
	if GameState == types.GameStateType.Menu then
		Menu.layoutmanager:update(dt)
	elseif GameState == types.GameStateType.Gameplay then
		if PreviousNode == nil then
			CurrentNode = getRandomNode()
			PreviousNode = CurrentNode
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
			print("You have collected enough signals! You win!")
			if Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.Win)
			else
				print("NavController or navigateTo function not defined")
			end
			return
		end

		animationSystem:update(dt)

		local PLANET_SPEED = 3

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
		if not visited and CurrentNode and love.mouse.isDown(1) then
			local mx, my = love.mouse.getPosition()
			if CurrentNode.type == constants.NODE_TYPES.Passenger then
				PassengerNodeHandler:update(dt)
			else
				for i, choice in ipairs(CurrentNode.choices) do
					if
						mx >= love.graphics.getWidth() / 2 - 200 + (i - 1) * 250
						and mx <= love.graphics.getWidth() / 2 - 200 + (i - 1) * 250 + 200
						and my >= love.graphics.getHeight() / 2 + constants.PLANET_RADIUS + 60
						and my <= love.graphics.getHeight() / 2 + constants.PLANET_RADIUS + 90
					then
						-- apply choice effect
						if choice.effect then
							choice.effect(updateResource)
						end
						markNodeAsVisited()
					end
				end
			end
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

		if CurrentNode and not visited then
			-- typewriter effect for question

			timer = timer + dt

			if charIndex < #CurrentNode.question and timer >= typingSpeed then
				charIndex = charIndex + 1
				displayedText = string.sub(CurrentNode.question, 1, charIndex)
				timer = 0 -- Reset timer for the next character
			end

			-- if at a node, do not allow movement until choice made
			return
		else
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
	elseif GameState == types.GameStateType.Win or GameState == types.GameStateType.GameOver then
		if love.keyboard.isDown("escape") then
			if Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.Menu)
			else
				print("NavController or navigateTo function not defined")
			end
		end
	end
end

function handleNavigateToNewNode(direction)
	updateResource("fuel", -constants.FUEL_CONSUMPTION_PER_MOVE)

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
	if CurrentNode.type == constants.NODE_TYPES.Passenger then
		-- todo: the handler should be added to the CurrentNode object itself
		-- and implemented in the configuration file
		PassengerNodeHandler:load()
	end
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

	-- depending on node type, draw different things
	if currentNode.characterImage ~= nil then
		local CHARACTER_TALKING_SIZE_PIXELS = 200
		local characterTalking = love.graphics.newImage(currentNode.characterImage)
		love.graphics.draw(
			characterTalking,
			10,
			love.graphics.getHeight() - (CHARACTER_TALKING_SIZE_PIXELS + 10),
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

	if CurrentNode.type == constants.NODE_TYPES.Passenger then
		PassengerNodeHandler:draw()
	else
		for i, choice in ipairs(CurrentNode.choices) do
			love.graphics.rectangle(
				"line",
				love.graphics.getWidth() / 2 - 200 + (i - 1) * 250,
				love.graphics.getHeight() / 2 + constants.PLANET_RADIUS + 60,
				200,
				30
			)
			love.graphics.printf(
				choice.text,
				love.graphics.getWidth() / 2 - 200 + (i - 1) * 250,
				love.graphics.getHeight() / 2 + constants.PLANET_RADIUS + 65,
				200,
				"center"
			)
		end
	end
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

function drawCurrentPassengers()
	local SIZE = 120

	-- print current passengers at top middle of screen with names and images and empty slots
	for i = 1, PlayerShip.MAX_PASSENGERS do
		if PlayerPassengers[i] then
			local passenger = PlayerPassengers[i]
			local img = love.graphics.newImage(passenger.image)
			love.graphics.rectangle(
				"line",
				love.graphics.getWidth() / 2 - (PlayerShip.MAX_PASSENGERS * SIZE) / 2 + (i - 1) * (SIZE + 10),
				10,
				SIZE,
				SIZE
			)
			love.graphics.draw(
				img,
				love.graphics.getWidth() / 2 - (PlayerShip.MAX_PASSENGERS * SIZE) / 2 + (i - 1) * (SIZE + 10) + 5,
				15,
				0,
				(SIZE - 10) / img:getWidth(),
				(SIZE - 10) / img:getHeight()
			)
			love.graphics.printf(
				passenger.name,
				love.graphics.getWidth() / 2 - (PlayerShip.MAX_PASSENGERS * SIZE) / 2 + (i - 1) * (SIZE + 10),
				10 + SIZE + 10,
				SIZE + 10,
				"center"
			)
		else
			love.graphics.rectangle(
				"line",
				love.graphics.getWidth() / 2 - (PlayerShip.MAX_PASSENGERS * SIZE) / 2 + (i - 1) * (SIZE + 10),
				10,
				SIZE,
				SIZE
			)
			love.graphics.printf(
				"Empty",
				love.graphics.getWidth() / 2 - (PlayerShip.MAX_PASSENGERS * SIZE) / 2 + (i - 1) * (SIZE + 10),
				10 + SIZE + 10,
				SIZE + 10,
				"center"
			)
		end
	end
end

function drawSpaceBg()
	-- load bg and always spin it opposite to planet?
	local BG_ROTATION_SPEED = -0.01
	local bgTime = love.timer.getTime() * BG_ROTATION_SPEED
	local bg
	-- Safely attempt to load the background image
	local success, imageOrError = pcall(love.graphics.newImage, "bg.png")
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
	if GameState == types.GameStateType.Win then
		love.graphics.clear(0, 0.5, 0, 1)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf("You Win!", 0, love.graphics.getHeight() / 2 - 50, love.graphics.getWidth(), "center")
		love.graphics.printf(
			"Press ESC to return to Menu",
			0,
			love.graphics.getHeight() / 2 + 10,
			love.graphics.getWidth(),
			"center"
		)
	elseif GameState == types.GameStateType.GameOver then
		love.graphics.clear(0.5, 0, 0, 1)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf("Game Over!", 0, love.graphics.getHeight() / 2 - 50, love.graphics.getWidth(), "center")
		love.graphics.printf(
			"Press ESC to return to Menu",
			0,
			love.graphics.getHeight() / 2 + 10,
			love.graphics.getWidth(),
			"center"
		)
	elseif GameState == types.GameStateType.Menu then
		Menu.layoutmanager:draw()
	elseif GameState == types.GameStateType.Gameplay then
		love.graphics.clear(0, 0, 0, 1)

		drawSpaceBg()

		love.graphics.print("Press ESC to return to Menu", 10, 10)
		love.graphics.print("Use arrows to navigate", love.graphics.getWidth() / 2 - 50, love.graphics.getHeight() - 30)

		drawMinimap()

		-- print resources
		-- set bg as dark block colour rectangle behind text for readability
		love.graphics.setColor(0, 0, 0, 0.9)
		love.graphics.rectangle("fill", 0, 30, 200, 180)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 40))
		love.graphics.print("Fuel: " .. Resources.fuel, 10, 40)
		love.graphics.print("Oxygen: " .. Resources.oxygen, 10, 80)
		love.graphics.print("Money: " .. Resources.money, 10, 120)
		love.graphics.print("Signals: " .. Resources.signals .. "/" .. constants.SIGNAL_TOTAL_GOAL, 10, 160)
		love.graphics.setFont(love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 26))

		animationSystem:draw()

		drawCurrentPassengers()
		drawCurrentNode()
	end
end
