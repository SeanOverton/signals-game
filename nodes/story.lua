local StoryNodeHandler = {
	buttons = {},
	message = "",
	fullMessage = "",
	displayedChars = 0,
	charSpeed = 60,
	step = 1,
	resolved = false,
	currentNode = nil,
}

function StoryNodeHandler:load(CurrentNode, modal)
	self.buttons = {}
	self.displayedChars = 0
	self.step = 1
	self.resolved = false
	self.currentNode = CurrentNode
	self.fullMessage = CurrentNode.segments[1].text
	self.message = ""

	self:createChoiceButtons()
end

function StoryNodeHandler:createChoiceButtons()
	self.buttons = {}
	local segment = self.currentNode.segments[self.step]

	if not segment or not segment.choices then
		return
	end

	for i, choice in ipairs(segment.choices) do
		local btn = Button:new(
			love.graphics.getWidth() / 2 - (200 * #segment.choices / 2) + (i - 1) * 250,
			500,
			choice.text,
			24,
			function()
				local result = choice.effect(updateResource)
				if result == "next" then
					self.step = self.step + 1
					if self.currentNode.segments[self.step] then
						self.fullMessage = self.currentNode.segments[self.step].text
						self.displayedChars = 0
						self.buttons = {}
					else
						self.resolved = true
						markNodeAsVisited()
					end
				else
					self.resolved = true
					markNodeAsVisited()
				end
			end,
			{ showBorder = true }
		)
		table.insert(self.buttons, btn)
	end
end

function StoryNodeHandler:update(dt)
	if self.resolved then
		return
	end

	if self.displayedChars < #self.fullMessage then
		self.displayedChars = math.min(#self.fullMessage, self.displayedChars + self.charSpeed * dt)
		self.message = string.sub(self.fullMessage, 1, math.floor(self.displayedChars))
	else
		-- only display buttons once message is typed out
		self:createChoiceButtons()
	end

	local mx, my = love.mouse.getPosition()
	local mousePressed = love.mouse.isDown(1)
	for _, b in ipairs(self.buttons) do
		b:update(dt, mx, my, mousePressed)
	end
end

function StoryNodeHandler:draw()
	local segment = self.currentNode.segments[self.step]
	if segment.image then
		local img = love.graphics.newImage(segment.image)
		love.graphics.setColor(1, 1, 1, 0.8)
		love.graphics.draw(img, love.graphics.getWidth() / 2, 200, 0, 2, 2, img:getWidth() / 2, img:getHeight() / 2)
	end

	-- Text box
	love.graphics.setColor(0, 0, 0, 0.8)
	local padding = 20
	local font = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 26)
	love.graphics.setFont(font)
	local textWidth = font:getWidth(self.message)
	local textHeight = font:getHeight()
	local boxWidth = math.min(love.graphics.getWidth() * 0.8, textWidth + padding * 2)
	local boxX = (love.graphics.getWidth() - boxWidth) / 2
	local boxY = 300
	love.graphics.rectangle("fill", boxX, boxY - padding / 2, boxWidth, textHeight * 3, 12, 12)

	-- Gradual text
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(self.message, boxX, boxY, boxWidth, "center")

	for _, b in ipairs(self.buttons) do
		b:draw()
	end
end

return StoryNodeHandler
