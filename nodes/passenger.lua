local passengers = require("passengers")

local PassengerNodeHandler = {
	randomPassengers = {},
	BUTTON_SIZE_PIXELS = 240,
	buttons = {},
	generateRandomPassengers = function(self)
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
	load = function(self, _)
		self:generateRandomPassengers()
		self.buttons = {
			Button:new(love.graphics.getWidth() / 2 - 175, 500, "Redraw (-10 money)", 24, function()
				if Resources.money >= 10 then
					updateResource("money", -10)
					self:generateRandomPassengers()
				end
			end, { showBorder = true }),
			Button:new(love.graphics.getWidth() / 2 + 75, 500, "Skip", 24, function()
				markNodeAsVisited()
			end, { showBorder = true }),
		}
	end,
	update = function(self, dt, eventManager, passengersMenu)
		local mx, my = love.mouse.getPosition()
		local mousePressed = love.mouse.isDown(1)
		for _, button in ipairs(self.buttons) do
			button:update(dt, mx, my, mousePressed)
		end
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
						passengersMenu:unlock(passenger.name)
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

		for _, b in ipairs(self.buttons) do
			b:draw()
		end
	end,
}

return PassengerNodeHandler
