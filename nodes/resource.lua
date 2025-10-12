local ResourceNodeHandler = {
	buttons = {},
	state = "intro",
	collected = 0,
	risk = 0.1,
	message = "You find a derelict ship drifting in the void...",
	resolved = false,
	pulseTimer = 0,
}

function ResourceNodeHandler:load(CurrentNode, modal)
	self.buttons = {}
	self.state = "intro"
	self.collected = 0
	self.risk = 0.1
	self.resolved = false
	self.message = CurrentNode.question or "A mysterious resource cache floats nearby."

	local startButton = Button:new(love.graphics.getWidth() / 2 - 100, 500, "Start Salvage", 24, function()
		self.state = "salvaging"
		self.message = "You begin salvaging the wreckage..."
		self:createSalvageButtons(modal)
	end, { showBorder = true })

	table.insert(self.buttons, startButton)
end

function ResourceNodeHandler:createSalvageButtons(modal)
	self.buttons = {}

	local collectButton = Button:new(love.graphics.getWidth() / 2 - 220, 500, "Collect More", 24, function()
		local roll = math.random()
		if roll < self.risk then
			self.state = "failed"
			self.message = string.format(
				"💥 You pushed too far! The wreck detonates. You lose %d monet and take hull damage!",
				self.collected
			)
			updateResource("hull", -1 * math.random(1, 2))
			self.collected = 0
			markNodeAsVisited()
			self.buttons = {}
			local okButton = Button:new(love.graphics.getWidth() / 2 - 100, 500, "Continue", 24, function()
				self.resolved = true
			end, { showBorder = true })
			table.insert(self.buttons, okButton)
		else
			local gain = math.random(2, 5)
			self.collected = self.collected + gain
			self.risk = math.min(self.risk + 0.15, 0.95)
			self.message =
				string.format("You pry open more wreckage... You’ve gathered %d unbanked money!", self.collected)
		end
	end, { showBorder = true })

	local stopButton = Button:new(love.graphics.getWidth() / 2 + 50, 500, "Stop & Leave", 24, function()
		self.state = "success"
		self.message = string.format("You bank your haul safely. Recovered %d money.", self.collected)
		updateResource("money", self.collected)
		markNodeAsVisited()
		self.buttons = {}
		local okButton = Button:new(love.graphics.getWidth() / 2 - 100, 500, "Continue", 24, function()
			self.resolved = true
		end, { showBorder = true })
		table.insert(self.buttons, okButton)
	end, { showBorder = true })

	table.insert(self.buttons, collectButton)
	table.insert(self.buttons, stopButton)
end

function ResourceNodeHandler:update(dt)
	if self.resolved then
		return
	end
	local mx, my = love.mouse.getPosition()
	local mousePressed = love.mouse.isDown(1)
	for _, button in ipairs(self.buttons) do
		button:update(dt, mx, my, mousePressed)
	end

	-- Pulse animation for risk highlight
	self.pulseTimer = (self.pulseTimer + dt * 3) % (2 * math.pi)
end

function ResourceNodeHandler:draw()
	for _, b in ipairs(self.buttons) do
		b:draw()
	end

	love.graphics.setFont(love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 26))
	if self.state == "intro" then
		return
	end

	local text = self.message or ""
	local font = love.graphics.getFont()
	local textWidth = font:getWidth(text)
	local textHeight = font:getHeight()
	local padding = 20
	local boxWidth = math.min(love.graphics.getWidth() * 0.8, textWidth + padding * 2)
	local boxX = (love.graphics.getWidth() - boxWidth) / 2
	local boxY = 280

	-- Text background
	love.graphics.setColor(0, 0, 0, 0.75)
	love.graphics.rectangle("fill", boxX, boxY - padding / 2, boxWidth, textHeight * 5 + 80, 12, 12)

	-- Main message
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(text, 0, 300, love.graphics.getWidth(), "center")

	-- Highlight unbanked loot
	if self.state == "salvaging" and self.collected > 0 then
		local pulse = 0.6 + 0.4 * math.sin(self.pulseTimer)
		love.graphics.setColor(1, pulse, 0.1, 1)
		local bigFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 64)
		love.graphics.setFont(bigFont)
		love.graphics.printf("Risking " .. self.collected .. " money!", 0, 330, love.graphics.getWidth(), "center")
		love.graphics.setFont(font)
	end

	-- Risk bar
	if self.state == "salvaging" then
		local barWidth = 250
		local x = love.graphics.getWidth() / 2 - barWidth / 2
		local y = 420
		local pulse = 0.6 + 0.4 * math.sin(self.pulseTimer)
		love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
		love.graphics.rectangle("fill", x, y, barWidth, 20)
		love.graphics.setColor(1, pulse * 0.2, pulse * 0.2, 0.9)
		love.graphics.rectangle("fill", x, y, barWidth * self.risk, 20)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(
			"Risk: " .. math.floor(self.risk * 100) .. "%",
			0,
			y - 25,
			love.graphics.getWidth(),
			"center"
		)
	end
end

return ResourceNodeHandler
