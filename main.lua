local types = require("./types/main")
-- local menu = require("menu")

local Menu = {
	navController = nil,
	layoutmanager = nil,
}

function love.load()
	local navController = {
		navigateTo = function(self, state)
			print("Navigating to state:", state)
			GameState = state
		end,
	}

	-- loads once at start of game, setup game, and init/load assets etc.
	-- create new menu:w
	-- menu.load(navController)
	local layoutmanager = {}
	function layoutmanager:draw()
		love.graphics.clear(0.1, 0.1, 0.1, 1)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf("Main Menu", 0, 100, love.graphics.getWidth(), "center")
		love.graphics.rectangle("line", love.graphics.getWidth() / 2 - 50, love.graphics.getHeight() / 2 - 25, 100, 50)
		love.graphics.printf("Start Game", love.graphics.getWidth() / 2 - 50, love.graphics.getHeight() / 2 - 10, 100, "center")
	end
	function layoutmanager:update(dt)
		if love.mouse.isDown(1) then
			local mx, my = love.mouse.getPosition()
			if mx >= love.graphics.getWidth() / 2 - 50 and mx <= love.graphics.getWidth() / 2 + 50 and
			   my >= love.graphics.getHeight() / 2 - 25 and my <= love.graphics.getHeight() / 2 + 25 then
				if Menu.navController and Menu.navController.navigateTo then
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
	-- menu.update(dt)
	Menu.layoutmanager:update(dt)
end

function love.draw()
	-- update UI, drawing elements etc. after update runs
	-- runs after every love.update
	if GameState == types.GameStateType.Menu then
		-- menu.draw()
		Menu.layoutmanager:draw()
	elseif GameState == types.GameStateType.Gameplay then
		print("ste")
		love.graphics.clear(0, 0, 0, 1)
		love.graphics.print("In Gameplay State", 100, 100)
		love.graphics.print("Press ESC to return to Menu", 100, 200)
	end
end
