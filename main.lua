local types = require("./types/main")

-- const title
local GAME_TITLE = "Signals"

local Menu = {
	navController = nil,
	layoutmanager = nil,
}

local PlayerPosition = { x = 0, y = 0 }
local MAX_WIDTH = 50
local PLAYER_RADIUS = 5;

local DEFAULT_FUEL = 100
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

local PLANET_RADIUS = 120;

function resetGame()
	PlayerPosition = { x = 0, y = 0 }
	Resources.fuel = DEFAULT_FUEL
	Resources.oxygen = DEFAULT_OXYGEN
	Resources.money = DEFAULT_MONEY
	Resources.signals = DEFAULT_SIGNALS
	CurrentNode = nil
end

-- config for choices at each planet, or spaceship or alien encounter etc.
local NODE_OPTIONS = {
	{
		question = "You encounter a friendly alien. Do you want to trade? It will cost 10 money but give you 20 fuel.",
		choices = {
			{ text = "Yes", effect = function() 
				Resources.money = Resources.money - 10
				Resources.fuel = Resources.fuel + 20
			end },
			{ text = "No", effect = function() print("Ignored alien") end },
		}
	},
	{
		question = "You find an abandoned spaceship. Do you want to scavenge it? It might have useful resources.",
		choices = {
			{ text = "Yes", effect = function() 
				local foundFuel = math.random(5, 15)
				local foundOxygen = math.random(5, 15)
				Resources.fuel = Resources.fuel + foundFuel
				Resources.oxygen = Resources.oxygen + foundOxygen
				print("Found " .. foundFuel .. " fuel and " .. foundOxygen .. " oxygen.")
			end },
			{ text = "No", effect = function() print("Left the spaceship alone") end },
		}
	},
	{
		question = "You encounter a space storm. Do you want to navigate through it? It will cost 15 fuel but save you time.",
		choices = {
			{ text = "Yes", effect = function() 
				Resources.fuel = Resources.fuel - 15
				print("Navigated through the storm, but lost 15 fuel.")
			end },
			{ text = "No", effect = function() print("Avoided the storm, took longer route.") end },
		}
	},
	{
		question = "You find a derelict space station. Do you want to dock and explore? It might have resources but could be dangerous.",
		choices = {
			{ text = "Yes", effect = function() 
				local risk = math.random()
				if risk < 0.5 then
					local foundOxygen = math.random(10, 20)
					Resources.oxygen = Resources.oxygen + foundOxygen
					print("Found " .. foundOxygen .. " oxygen in the station.")
				else
					local lostFuel = math.random(5, 15)
					Resources.fuel = Resources.fuel - lostFuel
					print("Encountered problems in the station, lost " .. lostFuel .. " fuel.")
				end
			end },
			{ text = "No", effect = function() print("Decided not to risk exploring the station.") end },
		}
	},
	{
		question = "You come across a mysterious signal. Do you want to investigate? It could lead to valuable resources or danger.",
		choices = {
			{ text = "Yes", effect = function() 
				local outcome = math.random()
				if outcome < 0.4 then
					local foundMoney = math.random(10, 30)
					Resources.money = Resources.money + foundMoney
					print("The signal led to a hidden cache! Found " .. foundMoney .. " money.")
				elseif outcome < 0.8 then
					local lostOxygen = math.random(5, 15)
					Resources.oxygen = Resources.oxygen - lostOxygen
					print("The signal was a trap! Lost " .. lostOxygen .. " oxygen.")
				else
					print("The signal was just static. Nothing happened.")
				end
			end },
			{ text = "No", effect = function() print("Ignored the mysterious signal.") end },
		}
	},
	{
		-- random chance of finding a signal
		question = "You detect a faint signal in the distance. Do you want to follow it? It might lead to something valuable.",
		choices = {
			{ text = "Yes", effect = function() 
				local foundSignal = math.random() < 0.7
				if foundSignal then
					Resources.signals = Resources.signals + 1
					print("You successfully traced the signal and collected it! Total signals: " .. Resources.signals)
				else
					print("The signal was too weak to trace. You gained nothing.")
				end
			end },
			{ text = "No", effect = function() print("Decided not to follow the faint signal.") end },
		}
	}
}

function love.load()
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
		love.graphics.printf("Start Game", love.graphics.getWidth() / 2 - 75, love.graphics.getHeight() / 2 - 10, 150, "center")
	end
	function layoutmanager:update(dt)
		if love.mouse.isDown(1) then
			local mx, my = love.mouse.getPosition()
			if mx >= love.graphics.getWidth() / 2 - 50 and mx <= love.graphics.getWidth() / 2 + 50 and
			   my >= love.graphics.getHeight() / 2 - 25 and my <= love.graphics.getHeight() / 2 + 25 then
				if Menu.navController and Menu.navController.navigateTo then
					resetGame()
					Menu.navController:navigateTo(types.GameStateType.Gameplay)
				else print("NavController or navigateTo function not defined")
				end
			end
		end
	end
	Menu.layoutmanager = layoutmanager
	Menu.navController = navController
	GameState = types.GameStateType.Menu
end



function love.update(dt)
	-- input handlng, game logic, calculations, updating positions etc.
	-- receives dt: deltatime arg, runs 60/ps, ie. every frame
	if GameState == types.GameStateType.Menu then
		Menu.layoutmanager:update(dt)
	elseif GameState == types.GameStateType.Gameplay then
		if Resources.fuel <= 0 then
			print("Out of fuel! Game Over.")
			if Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.GameOver)
			else print("NavController or navigateTo function not defined")
			end
			return
		elseif Resources.oxygen <= 0 then
			print("Out of oxygen! Game Over.")
			if Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.GameOver)
			else print("NavController or navigateTo function not defined")
			end
			return
		elseif Resources.signals >= 5 then
			print("You have collected enough signals! You win!")
			if Menu.navController and Menu.navController.navigateTo then
				Menu.navController:navigateTo(types.GameStateType.Win)
			else print("NavController or navigateTo function not defined")
			end
			return
		end

		-- handle mouse click on choices
		if CurrentNode and love.mouse.isDown(1) then
			local mx, my = love.mouse.getPosition()
			for i, choice in ipairs(CurrentNode.choices) do
				if mx >= love.graphics.getWidth() / 2 - 200 + (i-1)*250 and mx <= love.graphics.getWidth() / 2 - 200 + (i-1)*250 + 200 and
				   my >= love.graphics.getHeight() / 2 + PLANET_RADIUS + 60 and my <= love.graphics.getHeight() / 2 + PLANET_RADIUS + 90 then 
					-- apply choice effect
					if choice.effect then choice.effect() end
					CurrentNode = nil -- clear current node after making a choice
				end
			end
		end

		if love.keyboard.isDown("escape") then
			if Menu.navController and Menu.navController.navigateTo then
					Menu.navController:navigateTo(types.GameStateType.Menu)
			else print("NavController or navigateTo function not defined")
			end
		end

		if CurrentNode then
			-- if at a node, do not allow movement until choice made
			return
		end

		-- handle arrow key input
		if love.keyboard.isDown("left") then
			PlayerPosition.x = math.max(PlayerPosition.x - 1, -MAX_WIDTH+PLAYER_RADIUS);
			handleNavigateToNewNode()
			Resources.fuel = Resources.fuel - 1
		elseif love.keyboard.isDown("right") then
			PlayerPosition.x = math.min(PlayerPosition.x + 1, MAX_WIDTH-PLAYER_RADIUS);
			handleNavigateToNewNode()
			Resources.fuel = Resources.fuel - 1
		elseif love.keyboard.isDown("up") then
			PlayerPosition.y = math.max(PlayerPosition.y - 1, -MAX_WIDTH+PLAYER_RADIUS);
			handleNavigateToNewNode()
			Resources.fuel = Resources.fuel - 1
		elseif love.keyboard.isDown("down") then
			PlayerPosition.y = math.min(PlayerPosition.y + 1, MAX_WIDTH-PLAYER_RADIUS);
			handleNavigateToNewNode()
			Resources.fuel = Resources.fuel - 1
		end
	elseif GameState == types.GameStateType.Win or GameState == types.GameStateType.GameOver then
		if love.keyboard.isDown("escape") then
			if Menu.navController and Menu.navController.navigateTo then
					Menu.navController:navigateTo(types.GameStateType.Menu)
			else print("NavController or navigateTo function not defined")
			end
		end
	end
end
function handleNavigateToNewNode()
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
		love.graphics.printf("Press ESC to return to Menu", 0, love.graphics.getHeight() / 2 + 10, love.graphics.getWidth(), "center")
	elseif GameState == types.GameStateType.GameOver then
		love.graphics.clear(0.5, 0, 0, 1)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf("Game Over!", 0, love.graphics.getHeight() / 2 - 50, love.graphics.getWidth(), "center")
		love.graphics.printf("Press ESC to return to Menu", 0, love.graphics.getHeight() / 2 + 10, love.graphics.getWidth(), "center")
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
		love.graphics.circle("fill", love.graphics.getWidth() - 60 + PlayerPosition.x, 60 + PlayerPosition.y, PLAYER_RADIUS)

		-- print planet in middle of screen
		love.graphics.setColor(math.abs(PlayerPosition.x)/MAX_WIDTH, math.abs(PlayerPosition.y)/MAX_WIDTH, math.abs(PlayerPosition.x)/MAX_WIDTH, 1)
		love.graphics.circle("fill", love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, PLANET_RADIUS)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.circle("line", love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, PLANET_RADIUS)

		-- print resources
		love.graphics.print("Fuel: " .. Resources.fuel, 10, 40)
		love.graphics.print("Oxygen: " .. Resources.oxygen, 10, 70)
		love.graphics.print("Money: " .. Resources.money, 10, 100)
		love.graphics.print("Signals: " .. Resources.signals, 10, 130)

		-- if at a new node, show the question and choices under the planet
		if CurrentNode then
			love.graphics.printf(CurrentNode.question, 0, love.graphics.getHeight() / 2 + PLANET_RADIUS + 20, love.graphics.getWidth(), "center")
			for i, choice in ipairs(CurrentNode.choices) do
				love.graphics.rectangle("line", love.graphics.getWidth() / 2 - 200 + (i-1)*250, love.graphics.getHeight() / 2 + PLANET_RADIUS + 60, 200, 30)
				love.graphics.printf(choice.text, love.graphics.getWidth() / 2 - 200 + (i-1)*250, love.graphics.getHeight() / 2 + PLANET_RADIUS + 65, 200, "center")
			end
		end
	end
end
