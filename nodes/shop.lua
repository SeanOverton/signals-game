local ShopProducts = {
	{
		type = "Shop",
		name = "Fuel",
		image = "assets/fuelInjector.png",
		description = "+5 fuel",
		cost = 5,
		effect = function()
			Resources.fuel = Resources.fuel + 5
		end,
	},
}

local ShopNodeHandler = {
	randomUpgradeOptions = {},
	BUTTON_SIZE_PIXELS = 240,
	buttons = {},
	genRandomItems = function(self, rocket)
		local available = rocket:getAvailableUpgrades()

		-- Append elements of list2 to list1
		for _, value in ipairs(ShopProducts) do
			table.insert(available, value)
		end

		local randomUpgrades = {}
		while #randomUpgrades < math.min(#available, number or 2) do
			local candidate = available[math.random(1, #available)]
			local alreadyChosen = false
			for _, p in ipairs(randomUpgrades) do
				if p.name == candidate.name then
					alreadyChosen = true
					break
				end
			end
			if not alreadyChosen then
				table.insert(randomUpgrades, candidate)
			end
		end

		self.randomUpgradeOptions = randomUpgrades
	end,
	load = function(self, _, _, rocket)
		self:genRandomItems(rocket)

		self.buttons = {
			Button:new(love.graphics.getWidth() / 2 - 175, 500, "Redraw (-10 money)", 24, function()
				if Resources.money >= 10 then
					updateResource("money", -10)
					self:genRandomItems(rocket)
				end
			end, { showBorder = true }),
			Button:new(love.graphics.getWidth() / 2 + 75, 500, "Skip", 24, function()
				markNodeAsVisited()
			end, { showBorder = true }),
		}
	end,
	update = function(self, dt, _, _, rocket)
		local mx, my = love.mouse.getPosition()
		local mousePressed = love.mouse.isDown(1)
		for _, button in ipairs(self.buttons) do
			button:update(dt, mx, my, mousePressed)
		end
		-- handle passenger specific updates if needed
		-- passenger choices have images
		-- event handlers for anything drawn
		-- also handle anything else specific to the node logic
		for i, upgrade in ipairs(self.randomUpgradeOptions) do
			if upgrade then
				-- handle mouse click on passenger choice
				if love.mouse.isDown(1) then
					local mx, my = love.mouse.getPosition()
					local x = love.graphics.getWidth() / 2 - self.BUTTON_SIZE_PIXELS + (i - 1) * 250
					local y = love.graphics.getHeight() / 2 - 140
					local w = self.BUTTON_SIZE_PIXELS
					local h = self.BUTTON_SIZE_PIXELS
					if mx >= x and mx <= x + w and my >= y and my <= y + h then
						if Resources.money < upgrade.cost then
							return
						end

						updateResource("money", -upgrade.cost)
						if upgrade.type ~= "Shop" then
							-- only call upgrade for non shop items which are rocket upgrades
							rocket:upgrade(upgrade)
						end

						if upgrade.effect then
							upgrade.effect()
						end

						-- if passenger.register then
						-- 	passenger:register(eventManager)
						-- end
						markNodeAsVisited()
					end
				end
			end
		end
	end,
	draw = function(self)
		-- draws node specific stuff, ie. choices here... todo move more here?
		for i, upgrade in ipairs(self.randomUpgradeOptions) do
			local img = love.graphics.newImage(upgrade.image)
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
				upgrade.name .. " $" .. upgrade.cost,
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

return ShopNodeHandler
