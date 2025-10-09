local DEFAULT_IMAGE = nil
local DEFAULT_NAME = "N/A"
local DEFAULT_UPGRADE_STATE = {
	Engine = {
		type = "Engine",
		name = DEFAULT_NAME,
		image = DEFAULT_IMAGE,
		unlocked = true,
	},
	Oxygen = {
		type = "Oxygen",
		name = DEFAULT_NAME,
		image = DEFAULT_IMAGE,
		unlocked = true,
	},
	Trade = {
		type = "Trade",
		name = DEFAULT_NAME,
		image = DEFAULT_IMAGE,
		unlocked = true,
	},
	Sensors = {
		type = "Sensors",
		name = DEFAULT_NAME,
		image = DEFAULT_IMAGE,
		unlocked = true,
	},
	Defense = {
		type = "Defense",
		name = DEFAULT_NAME,
		image = DEFAULT_IMAGE,
		unlocked = false,
	},
	Cosmetic = {
		type = "Cosmetic",
		name = DEFAULT_NAME,
		image = DEFAULT_IMAGE,
		unlocked = true,
	},
}

local Rocket = {
	x = 400,
	y = 300,
	speed = 150,
	animTimer = 0,
	animFrame = 1,
	upgradeMap = {},
	upgradeOptions = {
		{
			type = "Engine",
			name = "Fuel Injector",
			image = "assets/fuelInjector.png",
			cost = 5,
		},
		{
			type = "Engine",
			name = "Stabilizer",
			cost = 15,
			image = "assets/stabilizer.png",
		},
		{
			type = "Engine",
			name = "After burner",
			cost = 20,
			image = "assets/afterburner.png",
		},
	},
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
	updateResource("money", -upgradeObj.cost)
	self.upgrades[upgradeObj.type].name = upgradeObj.name
	self.upgrades[upgradeObj.type].image = upgradeObj.image

	-- register effects as well similar to passengers?
	-- or statically update values used in calcs
	-- or just update resources, straight trade for resources
end

function Rocket:reset()
	self.upgrades = DEFAULT_UPGRADE_STATE
end

function Rocket:getRandomUpgradeOptions(number)
	local randomUpgrades = {}
	while #randomUpgrades < math.min(#self.upgradeOptions, number or 2) do
		local candidate = self.upgradeOptions[math.random(1, #self.upgradeOptions)]
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
	return randomUpgrades
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
