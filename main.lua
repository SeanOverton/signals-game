local types = require("./types/main")

-- const title
local GAME_TITLE = "Signals"

local Menu = {
	navController = nil,
	layoutmanager = nil,
}

local PlayerPosition = { x = 0, y = 0 }
local MAX_WIDTH = 50
local PLAYER_RADIUS = 5

local DEFAULT_FUEL = 30
local DEFAULT_OXYGEN = 100
local DEFAULT_MONEY = 50
local DEFAULT_SIGNALS = 0

local Resources = {
	fuel = DEFAULT_FUEL,
	oxygen = DEFAULT_OXYGEN,
	money = DEFAULT_MONEY,
	signals = DEFAULT_SIGNALS,
}
local CurrentNode = nil

local PLANET_RADIUS = 120
local PreviouslyVisitedCoords = {}

function resetGame()
	PlayerPosition = { x = 0, y = 0 }
	Resources.fuel = DEFAULT_FUEL
	Resources.oxygen = DEFAULT_OXYGEN
	Resources.money = DEFAULT_MONEY
	Resources.signals = DEFAULT_SIGNALS
	PreviouslyVisitedCoords = {}
	CurrentNode = nil
	PreviousNode = nil
end

-- config for choices at each planet, or spaceship or alien encounter etc.
local NODE_OPTIONS = {
	{
		question = "You encounter a friendly alien. Do you want to trade? It will cost 15 money but give you 10 fuel.",
		choices = {
			{
				text = "Yes",
				effect = function()
					if Resources.money < 15 then
						print("Not enough money to trade with alien.")
						return
					end
					Resources.money = Resources.money - 15
					Resources.fuel = Resources.fuel + 10
				end,
			},
			{
				text = "No",
				effect = function()
					print("Ignored alien")
				end,
			},
		},
		image = "alien.png",
	},
	{
		question = "You find a derelict spaceship. Do you want to scavenge it? It might have useful supplies.",
		choices = {
			{
				text = "Yes",
				effect = function()
					local foundFuel = math.random(5, 15)
					local foundOxygen = math.random(10, 30)
					local foundMoney = math.random(20, 50)
					Resources.fuel = Resources.fuel + foundFuel
					Resources.oxygen = Resources.oxygen + foundOxygen
					Resources.money = Resources.money + foundMoney
					print(
						"Scavenged spaceship and found "
							.. foundFuel
							.. " fuel, "
							.. foundOxygen
							.. " oxygen, and "
							.. foundMoney
							.. " money."
					)
				end,
			},
			{
				text = "No",
				effect = function()
					print("Ignored derelict spaceship")
				end,
			},
		},
		image = "planet.png",
	},
	{
		question = "You detect a weak signal nearby. Do you want to investigate? It might be a distress signal.",
		choices = {
			{
				text = "Yes",
				effect = function()
					local success = math.random() < 0.7 -- 70% chance to find signal
					if success then
						Resources.signals = Resources.signals + 1
						print("Successfully investigated signal and gained 1 signal.")
					else
						print("Investigated signal but found nothing.")
					end
				end,
			},
			{
				text = "No",
				effect = function()
					print("Ignored weak signal")
				end,
			},
		},
		image = "planet.png",
	},
	-- planet
	{
		question = "You land on a small planet. Do you want to explore it? It might have resources.",
		choices = {
			{
				text = "Yes",
				effect = function()
					local foundFuel = math.random(0, 10)
					local foundOxygen = math.random(0, 20)
					local foundMoney = math.random(10, 30)
					Resources.fuel = Resources.fuel + foundFuel
					Resources.oxygen = Resources.oxygen + foundOxygen
					Resources.money = Resources.money + foundMoney
					print(
						"Explored planet and found "
							.. foundFuel
							.. " fuel, "
							.. foundOxygen
							.. " oxygen, and "
							.. foundMoney
							.. " money."
					)
				end,
			},
			{
				text = "No",
				effect = function()
					print("Ignored planet")
				end,
			},
		},
		image = "planet.png",
	},
}

function love.load()
	love.graphics.setDefaultFilter("nearest")
	local navController = {
		navigateTo = function(self, state)
			GameState = state
		end,
	}

	-- loads once at start of game, setup game, and init/load assets etc.
	-- create new menu
	local layoutmanager = {}

	local largeFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 64)
	local smallFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 24)

	function layoutmanager:draw()
		love.graphics.clear(0.1, 0.1, 0.1, 1)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(largeFont)
		love.graphics.printf(GAME_TITLE, 0, 100, love.graphics.getWidth(), "center")
		love.graphics.rectangle("line", love.graphics.getWidth() / 2 - 75, love.graphics.getHeight() / 2 - 25, 150, 50)
		love.graphics.setFont(smallFont)
		love.graphics.printf(
			"New Game",
			love.graphics.getWidth() / 2 - 75,
			love.graphics.getHeight() / 2 - 10,
			150,
			"center"
		)
		love.graphics.printf(
			"Continue",
			love.graphics.getWidth() / 2 - 75,
			love.graphics.getHeight() / 2 + 100,
			150,
			"center"
		)
	end
	function layoutmanager:update(dt)
		if love.mouse.isDown(1) then
			local mx, my = love.mouse.getPosition()
			if
				mx >= love.graphics.getWidth() / 2 - 50
				and mx <= love.graphics.getWidth() / 2 + 50
				and my >= love.graphics.getHeight() / 2 - 25
				and my <= love.graphics.getHeight() / 2 + 25
			then
				if Menu.navController and Menu.navController.navigateTo then
					resetGame()
					Menu.navController:navigateTo(types.GameStateType.Gameplay)
				else
					print("NavController or navigateTo function not defined")
				end
			end
			if
				mx >= love.graphics.getWidth() / 2 - 50
				and mx <= love.graphics.getWidth() / 2 + 50
				and my >= love.graphics.getHeight() / 2 + 100
				and my <= love.graphics.getHeight() / 2 + 150
			then
				if Menu.navController and Menu.navController.navigateTo then
					Menu.navController:navigateTo(types.GameStateType.Gameplay)
				else
					print("NavController or navigateTo function not defined")
				end
			end
		end
	end
	Menu.layoutmanager = layoutmanager
	Menu.navController = navController
	GameState = types.GameStateType.Menu
end

-- typing effect variables
local charIndex = 0
local typingSpeed = 0.01 -- Time in seconds between each character
local timer = 0
local displayedText = ""

-- moving planet variables
local PreviousNode = nil
local PrevPlanetPosition = { x = 0, y = 0 }
local Moving = false
local Direction = nil
local NewPlanetPosition = { x = 0, y = 0 }

function love.update(dt)
	-- input handlng, game logic, calculations, updating positions etc.
	-- receives dt: deltatime arg, runs 60/ps, ie. every frame
	if GameState == types.GameStateType.Menu then
		Menu.layoutmanager:update(dt)
	elseif GameState == types.GameStateType.Gameplay then
		if PreviousNode == nil then
			CurrentNode = NODE_OPTIONS[math.random(1, #NODE_OPTIONS)]
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
		elseif Resources.signals >= 5 then
			print("You have collected enough signals! You win!")
			if Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.Win)
			else
				print("NavController or navigateTo function not defined")
			end
			return
		end

		if Moving then
			-- update positions until new planet position reached and old one off screen
			PrevPlanetPosition.x = PrevPlanetPosition.x
				+ (Direction.x * love.graphics.getWidth() - PrevPlanetPosition.x) * dt
			PrevPlanetPosition.y = PrevPlanetPosition.y
				+ (Direction.y * love.graphics.getHeight() - PrevPlanetPosition.y) * dt
			NewPlanetPosition.x = NewPlanetPosition.x
				+ (Direction.x * love.graphics.getWidth() - NewPlanetPosition.x) * dt
			NewPlanetPosition.y = NewPlanetPosition.y
				+ (Direction.y * love.graphics.getHeight() - NewPlanetPosition.y) * dt

			-- once new planet at 0 and 0, stop moving
			if math.abs(NewPlanetPosition.x) < 50 and math.abs(NewPlanetPosition.y) < 50 then
				Moving = false
				PrevPlanetPosition = { x = 0, y = 0 }
				NewPlanetPosition = { x = 0, y = 0 }
				Direction = nil
			end
			return
		end

		local visited = false
		for _, coord in ipairs(PreviouslyVisitedCoords) do
			if coord.x == PlayerPosition.x and coord.y == PlayerPosition.y then
				visited = true
				break
			end
		end

		-- handle mouse click on choices
		if not visited and CurrentNode and love.mouse.isDown(1) then
			local mx, my = love.mouse.getPosition()
			for i, choice in ipairs(CurrentNode.choices) do
				if
					mx >= love.graphics.getWidth() / 2 - 200 + (i - 1) * 250
					and mx <= love.graphics.getWidth() / 2 - 200 + (i - 1) * 250 + 200
					and my >= love.graphics.getHeight() / 2 + PLANET_RADIUS + 60
					and my <= love.graphics.getHeight() / 2 + PLANET_RADIUS + 90
				then
					-- apply choice effect
					if choice.effect then
						choice.effect()
					end
					table.insert(PreviouslyVisitedCoords, { x = PlayerPosition.x, y = PlayerPosition.y })
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
			PlayerPosition.x = math.max(PlayerPosition.x - 1, -MAX_WIDTH + PLAYER_RADIUS)
			handleNavigateToNewNode({ x = 1, y = 0 })
			Resources.fuel = Resources.fuel - 1
		elseif love.keyboard.isDown("right") then
			PlayerPosition.x = math.min(PlayerPosition.x + 1, MAX_WIDTH - PLAYER_RADIUS)
			handleNavigateToNewNode({ x = -1, y = 0 })
			Resources.fuel = Resources.fuel - 1
		elseif love.keyboard.isDown("up") then
			PlayerPosition.y = math.max(PlayerPosition.y - 1, -MAX_WIDTH + PLAYER_RADIUS)
			handleNavigateToNewNode({ x = 0, y = 1 })
			Resources.fuel = Resources.fuel - 1
		elseif love.keyboard.isDown("down") then
			PlayerPosition.y = math.min(PlayerPosition.y + 1, MAX_WIDTH - PLAYER_RADIUS)
			handleNavigateToNewNode({ x = 0, y = -1 })
			Resources.fuel = Resources.fuel - 1
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
	-- animate planet sliding off screen and new one sliding in
	Moving = true
	Direction = direction
	NewPlanetPosition =
		{ x = -direction.x * love.graphics.getWidth() * 3, y = -direction.y * love.graphics.getHeight() * 3 }

	if CurrentNode ~= nil then
		PreviousNode = CurrentNode
	end
	CurrentNode = NODE_OPTIONS[math.random(1, #NODE_OPTIONS)]
	return { math.random(), math.random(), math.random(), 1 }
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
		love.graphics.print("Press ESC to return to Menu", 10, 10)
		-- draw a button in each corner with 'navigate' text and arrow pointing to that corner
		love.graphics.print("<", 10, love.graphics.getHeight() / 2 - 10)
		love.graphics.print(">", love.graphics.getWidth() - 30, love.graphics.getHeight() / 2 - 10)
		love.graphics.print("^", love.graphics.getWidth() / 2 - 10, 10)
		love.graphics.print("v", love.graphics.getWidth() / 2 - 10, love.graphics.getHeight() - 30)
		-- draw rectangles around the arrows
		love.graphics.rectangle("line", 10, love.graphics.getHeight() / 2 - 25, 20, 50)
		love.graphics.rectangle("line", love.graphics.getWidth() - 30, love.graphics.getHeight() / 2 - 25, 20, 50)
		love.graphics.rectangle("line", love.graphics.getWidth() / 2 - 25, 10, 50, 20)
		love.graphics.rectangle("line", love.graphics.getWidth() / 2 - 25, love.graphics.getHeight() - 30, 50, 20)

		-- print minimap of the game area in the top-right corner
		love.graphics.rectangle("line", love.graphics.getWidth() - 110, 10, 100, 100)
		-- mark previously visited coords on minimap
		for _, coord in ipairs(PreviouslyVisitedCoords) do
			love.graphics.setColor(0, 1, 0, 1)
			love.graphics.circle("fill", love.graphics.getWidth() - 60 + coord.x, 60 + coord.y, PLAYER_RADIUS)
			love.graphics.setColor(1, 1, 1, 1)
		end
		love.graphics.circle(
			"fill",
			love.graphics.getWidth() - 60 + PlayerPosition.x,
			60 + PlayerPosition.y,
			PLAYER_RADIUS
		)

		-- rotate planet over time and slower
		local ROTATION_SPEED = 0.1
		local time = love.timer.getTime() * ROTATION_SPEED

		if Moving then
			local prevImg = love.graphics.newImage(PreviousNode.image)
			local newImg = love.graphics.newImage(CurrentNode.image)
			love.graphics.draw(
				prevImg,
				love.graphics.getWidth() / 2 + PrevPlanetPosition.x,
				love.graphics.getHeight() / 2 + PrevPlanetPosition.y,
				time % (math.pi * 2),
				(PLANET_RADIUS * 2) / prevImg:getWidth(),
				(PLANET_RADIUS * 2) / prevImg:getHeight(),
				prevImg:getWidth() / 2,
				prevImg:getHeight() / 2
			)
			love.graphics.draw(
				newImg,
				love.graphics.getWidth() / 2 + NewPlanetPosition.x,
				love.graphics.getHeight() / 2 + NewPlanetPosition.y,
				time % (math.pi * 2),
				(PLANET_RADIUS * 2) / newImg:getWidth(),
				(PLANET_RADIUS * 2) / newImg:getHeight(),
				newImg:getWidth() / 2,
				newImg:getHeight() / 2
			)
		elseif CurrentNode then
			local curImg = love.graphics.newImage(CurrentNode.image)
			love.graphics.draw(
				curImg,
				love.graphics.getWidth() / 2,
				love.graphics.getHeight() / 2,
				time % (math.pi * 2),
				(PLANET_RADIUS * 2) / curImg:getWidth(),
				(PLANET_RADIUS * 2) / curImg:getHeight(),
				curImg:getWidth() / 2,
				curImg:getHeight() / 2
			)
		end

		-- print resources
		love.graphics.print("Fuel: " .. Resources.fuel, 10, 40)
		love.graphics.print("Oxygen: " .. Resources.oxygen, 10, 70)
		love.graphics.print("Money: " .. Resources.money, 10, 100)
		love.graphics.print("Signals: " .. Resources.signals, 10, 130)

		-- if at a new node, show the question and choices under the planet
		-- check if player position in previously visited coords
		local visited = false
		for _, coord in ipairs(PreviouslyVisitedCoords) do
			if coord.x == PlayerPosition.x and coord.y == PlayerPosition.y then
				visited = true
				break
			end
		end

		if not Moving and not visited and CurrentNode then
			-- print alien in bottom left corner
			local alien = love.graphics.newImage("alien.png")
			love.graphics.draw(
				alien,
				10,
				love.graphics.getHeight() - 110,
				0,
				100 / alien:getWidth(),
				100 / alien:getHeight()
			)

			-- print question text
			love.graphics.printf(
				displayedText,
				0,
				love.graphics.getHeight() / 2 + PLANET_RADIUS + 20,
				love.graphics.getWidth(),
				"center"
			)
			for i, choice in ipairs(CurrentNode.choices) do
				love.graphics.rectangle(
					"line",
					love.graphics.getWidth() / 2 - 200 + (i - 1) * 250,
					love.graphics.getHeight() / 2 + PLANET_RADIUS + 60,
					200,
					30
				)
				love.graphics.printf(
					choice.text,
					love.graphics.getWidth() / 2 - 200 + (i - 1) * 250,
					love.graphics.getHeight() / 2 + PLANET_RADIUS + 65,
					200,
					"center"
				)
			end
		else
			love.graphics.printf(
				"You've already been here",
				0,
				love.graphics.getHeight() / 2 + PLANET_RADIUS + 20,
				love.graphics.getWidth(),
				"center"
			)
		end
	end
end
