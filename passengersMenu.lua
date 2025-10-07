local Collectibles = {
	passengers = {},
	lockOverlay = nil,
	columns = 3,
	rows = 3, -- number of rows visible per page
	spacing = 270,
	startX = 120,
	startY = 50,
	currentPage = 1,
	totalPages = 1,
	buttonSize = 40,
	buttons = {},
}

function Collectibles:load(allPassengers)
	self.lockOverlay = love.graphics.newImage("assets/lock.png")

	-- Initialize passengers
	for _, passenger in ipairs(allPassengers) do
		self.passengers[#self.passengers + 1] = {
			data = passenger,
			unlocked = false,
		}
	end
	local screenWidth = love.graphics.getWidth()
	local screenHeight = love.graphics.getHeight()

	local leftX = screenWidth / 2 - 150
	local rightX = screenWidth / 2 + 150
	local y = screenHeight - 80

	self.buttons = {
		Button:new(leftX, y + 8, "<", 40, function()
			if self.currentPage > 1 then
				self.currentPage = self.currentPage - 1
			end
		end, { showBorder = true }),
		Button:new(rightX, y + 8, ">", 40, function()
			if self.currentPage < self.totalPages then
				self.currentPage = self.currentPage + 1
			end
		end, { showBorder = true }),
	}

	local perPage = self.columns * self.rows
	self.totalPages = math.ceil(#self.passengers / perPage)
end

function Collectibles:unlock(passengerName)
	for _, p in ipairs(self.passengers) do
		if p.data.name == passengerName then
			p.unlocked = true
			break
		end
	end
end

function Collectibles:hasUnlocked(passengerName)
	for _, p in ipairs(self.passengers) do
		if p.data.name == passengerName then
			return p.unlocked
		end
	end
	return false
end

function Collectibles:update(dt)
	local mx, my = love.mouse.getPosition()
	local mousePressed = love.mouse.isDown(1) -- left click
	for _, b in ipairs(self.buttons) do
		b:update(dt, mx, my, mousePressed)
	end
end

function Collectibles:draw()
	local perPage = self.columns * self.rows
	local startIndex = (self.currentPage - 1) * perPage + 1
	local endIndex = math.min(startIndex + perPage - 1, #self.passengers)

	local smallFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 24)
	love.graphics.setFont(smallFont)

	local col = 0
	local row = 0

	for i = startIndex, endIndex do
		local p = self.passengers[i]
		local px = self.startX + col * self.spacing
		local py = self.startY + row * 160

		local SIZE = 100

		-- Load passenger image
		local img = love.graphics.newImage(p.data.image)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(img, px, py, 0, SIZE / img:getWidth(), SIZE / img:getHeight())

		if not p.unlocked then
			-- darken and overlay lock
			love.graphics.setColor(0, 0, 0, 0.6)
			love.graphics.rectangle("fill", px, py, img:getWidth() * 0.8, img:getHeight() * 0.8)
			love.graphics.setColor(1, 1, 1, 0.8)
			love.graphics.draw(self.lockOverlay, px, py + 10, 0, 1.5, 1.5)
		else
			-- Label
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print(p.data.name, px, py + img:getHeight() + 65)
		end

		col = col + 1
		if col >= self.columns then
			col = 0
			row = row + 1
		end
	end

	-- Draw pagination buttons
	self:drawPagination()
end

function Collectibles:drawPagination()
	local screenWidth = love.graphics.getWidth()
	local screenHeight = love.graphics.getHeight()
	local y = screenHeight - 80

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(string.format("Page %d / %d", self.currentPage, self.totalPages), screenWidth / 2 - 40, y + 20)
	for _, b in ipairs(self.buttons) do
		b:draw()
	end
end

return Collectibles
