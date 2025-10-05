local Modal = {}
Modal.__index = Modal

function Modal:new()
	local self = setmetatable({}, Modal)
	self.active = false
	self.closeButton = { x = 0, y = 0, size = 24 }
	self.onClose = nil
	self.contentDrawFunc = nil
	return self
end

-- Open modal and pass a draw function
function Modal:open(drawFunc, onClose)
	self.active = true
	self.contentDrawFunc = drawFunc
	self.onClose = onClose or function() end
end

-- Close modal
function Modal:close()
	self.active = false
	if self.onClose then
		self.onClose()
	end
end

-- Update input (mouse + ESC)
function Modal:update(dt)
	if not self.active then
		return
	end

	local mx, my = love.mouse.getPosition()
	local s = self.closeButton.size
	local bx, by = love.graphics.getWidth() - s - 16, 16
	self.closeButton.x, self.closeButton.y = bx, by

	-- Hover + click detection
	if love.mouse.isDown(1) and mx > bx and mx < bx + s and my > by and my < by + s then
		self:close()
	end
end

function Modal:keypressed(key)
	if not self.active then
		return
	end
	if key == "escape" then
		self:close()
	end
end

function Modal:draw()
	if not self.active then
		return
	end

	local w, h = love.graphics.getWidth(), love.graphics.getHeight()

	-- Background overlay
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, 0, w, h)

	-- Close button
	local bx, by, s = self.closeButton.x, self.closeButton.y, self.closeButton.size
	love.graphics.setColor(1, 1, 1)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", bx, by, s, s)
	love.graphics.line(bx + 4, by + 4, bx + s - 4, by + s - 4)
	love.graphics.line(bx + 4, by + s - 4, bx + s - 4, by + 4)

	-- Custom content draw
	if self.contentDrawFunc then
		self.contentDrawFunc()
	end
end

return Modal
