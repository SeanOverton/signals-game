local types = require("./types/main")
local menu = require("menu")

function love.load()
	-- loads once at start of game, setup game, and init/load assets etc.
	menu.load()
	GameState = types.GameStateType.Menu
end

function love.update(dt)
	-- input handlng, game logic, calculations, updating positions etc.
	-- receives dt: deltatime arg, runs 60/ps, ie. every frame
	menu.update()
end

function love.draw()
	-- update UI, drawing elements etc. after update runs
	-- runs after every love.update
	if GameState == types.GameStateType.Menu then
		love.graphics.print("lfg", 100, 300)
		-- menu.draw()
	elseif GameState == types.GameStateType.Gameplay then
		love.graphics.print("lfg", 100, 300)
	end
end
