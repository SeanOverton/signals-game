local ShipMenuButton = {
	columns = 2,
	rows = 3, -- number of rows visible per page
	spacing = 270,
	startX = love.graphics.getWidth() / 2 - 120,
	startY = 140,
	buttonSize = 40,
	button = nil,
}

function ShipMenuButton:load(modal, rocket)
	love.graphics.print("Hull: " .. Resources.hull, 10, 200)
	self.button = Button:new(10, 240, "Ship", 36, function()
		modal:open(function()
			local largeFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 96)
			local smallFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 32)
			local extraSmallFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 26)
			love.graphics.setFont(largeFont)
			love.graphics.printf("The Ship", love.graphics.getWidth() / 2 - 250, 30, 500, "center")
			love.graphics.setFont(smallFont)
			rocket:draw()

			local col = 0
			local row = 0

			for _, upgrade in pairs(rocket.upgrades) do
				local px = self.startX + col * self.spacing
				local py = self.startY + row * 160

				local SIZE = 90

				love.graphics.setFont(smallFont)
				love.graphics.printf(upgrade.type .. ": " .. upgrade.name, px, py, 500, "left")
				if upgrade.image then
					local img = love.graphics.newImage(upgrade.image)
					love.graphics.setColor(1, 1, 1, 1)
					love.graphics.draw(img, px + 30, py + 30, 0, SIZE / img:getWidth(), SIZE / img:getHeight())
				end

				if upgrade.description then
					love.graphics.setFont(extraSmallFont)
					love.graphics.printf(upgrade.description, px, py + SIZE + 30, 500, "left")
				end

				col = col + 1
				if col >= self.columns then
					col = 0
					row = row + 1
				end
			end
		end)
	end, { showBorder = true })
end

function ShipMenuButton:update(dt)
	local mx, my = love.mouse.getPosition()
	local mousePressed = love.mouse.isDown(1) -- left click
	self.button:update(dt, mx, my, mousePressed)
end

function ShipMenuButton:draw()
	self.button:draw()
end

return ShipMenuButton
