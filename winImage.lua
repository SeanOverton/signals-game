local WinImage = {
	x = 640, -- start off-screen (left)
	y = 280, -- near bottom
	angle = 0, -- small tilt (radians)
	speed = 8, -- pixels per second
	driftUp = 2, -- upward component
	image = nil,
}

function WinImage:load()
	-- asset must be x: 256 by y: 128 pixels ratio
	self.image = love.graphics.newImage("assets/winImage1.png")
end

function WinImage:update(dt)
	-- Move right & up slightly
	self.x = self.x - self.speed * dt
	self.y = self.y + self.driftUp * dt

	-- Optional: reset once it goes off screen
	if self.y < 280 or self.y > love.graphics.getHeight() - 280 then
		self.speed = -self.speed
		self.driftUp = -self.driftUp
	end
end

function WinImage:draw()
	if not self.image then
		return
	end
	local ox = self.image:getWidth() / 2
	local oy = self.image:getHeight() / 2

	love.graphics.draw(self.image, self.x, self.y, self.angle, 5, 5, ox, oy)
end

return WinImage
