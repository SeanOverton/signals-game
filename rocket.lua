local DEFAULT_IMAGE = nil
local DEFAULT_NAME = "N/A"
local DEFAULT_UPGRADE_STATE = {
	Engine = {
		type = "Engine",
		name = DEFAULT_NAME,
		image = DEFAULT_IMAGE,
		index = 0,
	},
	Oxygen = {
		type = "Oxygen",
		name = DEFAULT_NAME,
		image = DEFAULT_IMAGE,
		index = 0,
	},
	Trade = {
		type = "Trade",
		name = DEFAULT_NAME,
		image = DEFAULT_IMAGE,
		index = 0,
	},
	Sensors = {
		type = "Sensors",
		name = DEFAULT_NAME,
		image = DEFAULT_IMAGE,
		index = 0,
	},
	Defense = {
		type = "Defense",
		name = DEFAULT_NAME,
		image = DEFAULT_IMAGE,
		index = 0,
	},
	Cosmetic = {
		type = "Cosmetic",
		name = DEFAULT_NAME,
		image = DEFAULT_IMAGE,
		index = 0,
	},
}

local Upgrades = {
	Engine = {
		chain = "Engine",
		tiers = {
			{
				type = "Engine",
				name = "Fuel Injector",
				image = "assets/fuelInjector.png",
				description = "Some effect",
				cost = 5,
				effect = function() end,
				index = 1,
			},
			{
				type = "Engine",
				name = "Stabilizer",
				cost = 15,
				description = "Some effect",
				effect = function() end,
				image = "assets/stabilizer.png",
				index = 2,
			},
			{
				type = "Engine",
				name = "After burner",
				description = "Some effect",
				effect = function() end,
				cost = 20,
				image = "assets/afterburner.png",
				index = 3,
			},
		},
	},
}

local Rocket = {
	x = 400,
	y = 300,
	speed = 150,
	animTimer = 0,
	animFrame = 1,
	upgradeMap = {},
	upgradeOptions = UpgradeOptions,
	upgrades = DEFAULT_UPGRADE_STATE,
}

function Rocket:load()
	self.imageIdle = love.graphics.newImage("assets/rocketIdle.png")
	self.imageMoving = {
		love.graphics.newImage("assets/rocketMoving1.png"),
		love.graphics.newImage("assets/rocketMoving2.png"),
		love.graphics.newImage("assets/rocketMoving3.png"),
	}
end

function Rocket:update(dt)
	-- Only animate if moving
	if Moving then
		self.animTimer = self.animTimer + dt
		if self.animTimer > 0.1 then
			self.animTimer = 0
			self.animFrame = self.animFrame % #self.imageMoving + 1
		end
	else
		self.animFrame = 1
		self.animTimer = 0
	end
end

function Rocket:upgrade(upgradeObj)
	self.upgrades[upgradeObj.type] = upgradeObj
	-- register effects as well similar to passengers?
	-- or statically update values used in calcs
	-- or just update resources, straight trade for resources
end

function Rocket:reset()
	self.upgrades = DEFAULT_UPGRADE_STATE
end

function Rocket:getAvailableUpgrades()
	local available = {}

	for chainName, chain in pairs(Upgrades) do
		local currentTier = self.upgrades[chainName].index or 0
		local nextTier = chain.tiers[currentTier + 1]
		if nextTier then
			table.insert(available, nextTier)
		end
	end

	return available
end

function Rocket:draw()
	local image
	if Moving then
		image = self.imageMoving[self.animFrame]
	else
		image = self.imageIdle
	end

	angle = math.pi / 2
	if Direction then
		angle = math.atan2(Direction.y, Direction.x)
	end

	-- Centered draw
	local ox, oy = image:getWidth() / 2, image:getHeight() / 2
	love.graphics.draw(image, self.x - 150, self.y, angle - math.pi / 2, 5, 5, ox, oy)
end

return Rocket
