Button = {}
Button.__index = Button

function Button:new(x, y, text, fontSize, onClick, opts)
	local obj = {
		x = x,
		y = y,
		text = text,
		baseFontSize = fontSize or 16,
		scale = 1,
		onClick = onClick,
		opts = opts or {},
		isHovered = false,
		padding = 10,
		wasMousePressed = false, -- track previous mouse state
	}
	obj.font = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", obj.baseFontSize)
	obj.w = obj.font:getWidth(text) + obj.padding * 2
	obj.h = obj.font:getHeight() + obj.padding * 2
	setmetatable(obj, Button)
	return obj
end

function Button:update(dt, mx, my, mousePressed)
	-- hitbox grows with scale
	local w = self.w * self.scale
	local h = self.h * self.scale
	local x = self.x - (w - self.w) / 2
	local y = self.y - (h - self.h) / 2

	self.isHovered = mx >= x and mx <= x + w and my >= y and my <= y + h

	if self.isHovered then
		self.scale = math.min(self.scale + dt * 5, 1.2) -- grow
		self.font = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", self.baseFontSize * 1.2)
		-- Only fire onClick on mouse press, not hold, and only once until mouse is released
		if mousePressed and not self.wasMousePressed and self.onClick then
			self.onClick()
		end
	else
		self.scale = math.max(self.scale - dt * 5, 1) -- shrink back
		self.font = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", self.baseFontSize)
	end

	self.wasMousePressed = mousePressed
end

function Button:draw()
	local w = self.w * self.scale
	local h = self.h * self.scale
	local x = self.x - (w - self.w) / 2
	local y = self.y - (h - self.h) / 2

	-- background (optional rectangle border)
	if self.opts.showBorder then
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", x, y, w, h, 6, 6)
	end

	-- text
	love.graphics.setFont(self.font)
	local tx = x + w / 2 - self.font:getWidth(self.text) / 2
	local ty = y + h / 2 - self.font:getHeight() / 2
	love.graphics.print(self.text, tx, ty)
end

return Button
