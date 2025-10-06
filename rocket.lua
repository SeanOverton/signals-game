local Rocket = {
	x = 400,
	y = 300,
	speed = 150,
	animTimer = 0,
	animFrame = 1,
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
