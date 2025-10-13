local AnomalyNodeHandler = {
	state = "intro",
	buttons = {},
	message = "",
	outcome = nil,
	timer = 0,
	effectTriggered = false,
}

local anomalyFlavors = {
	"A Spatial Rift detected ahead - light bends like liquid glass.",
	"Scanners scream static - reality here is folded and frayed.",
	"A ripple of energy crosses the hull - sensors go haywire.",
	"Your reflection flickers outside the cockpit window.",
	"The stars shift positions... then shift back.",
}

function AnomalyNodeHandler:load(CurrentNode, modal)
	self.state = "intro"
	self.message = anomalyFlavors[math.random(#anomalyFlavors)]
	self.outcome = nil
	self.timer = 0
	self.effectTriggered = false
	self.buttons = {}

	local investigateButton = Button:new(love.graphics.getWidth() / 2 - 200, 500, "Investigate", 24, function()
		self.state = "investigating"
		self.message = "You approach the rift... Space distorts around your ship."
		self.timer = 0
	end, { showBorder = true })

	local avoidButton = Button:new(love.graphics.getWidth() / 2 + 50, 500, "Avoid", 24, function()
		self.state = "resolved"
		self.message = "You avoid the rift, though curiosity lingers..."
		self.buttons = {
			Button:new(love.graphics.getWidth() / 2 - 100, 500, "Continue", 24, function()
				markNodeAsVisited()
			end, { showBorder = true }),
		}
	end, { showBorder = true })

	table.insert(self.buttons, investigateButton)
	table.insert(self.buttons, avoidButton)
end

function AnomalyNodeHandler:update(dt)
	local mx, my = love.mouse.getPosition()
	local mousePressed = love.mouse.isDown(1)
	for _, b in ipairs(self.buttons) do
		b:update(dt, mx, my, mousePressed)
	end

	if self.state == "investigating" then
		self.timer = self.timer + dt

		-- Small delay to simulate scanning/approaching effect
		if self.timer > 1.5 and not self.effectTriggered then
			self.effectTriggered = true
			self:triggerEffect()
		end
	end
end

function AnomalyNodeHandler:triggerEffect()
	local roll = math.random()

	if roll < 0.25 then
		updateResource("signals", 1)
		updateResource("fuel", -10)
		self.message = "Engines overheat as energy surges through the hull. You manage to stabilize, but lose 10 fuel."
	elseif roll < 0.5 then
		updateResource("signals", 1)
		updateResource("oxygen", -10)
		self.message = "Oxygen systems flicker. The rift drains the air itself."
	elseif roll < 0.75 then
		updateResource("signals", 2)
		self.message = "You capture an immense burst of data from the anomaly! Signals +2."
	elseif roll < 0.99 then
		updateResource("hull", -1)
		self.message = "The rift collapses violently, scraping your ship. Hull integrity -1."
	else
		updateResource("signals", 3)
		updateResource("money", 10)
		self.message = "Through impossible geometry, you glimpse another world. +3 Signals, +10 Money!"
	end

	self.state = "resolved"
	self.buttons = {
		Button:new(love.graphics.getWidth() / 2 - 100, 500, "Continue", 24, function()
			markNodeAsVisited()
		end, { showBorder = true }),
	}
end

function AnomalyNodeHandler:draw()
	-- Draw backdrop (optional subtle fade)
	love.graphics.setColor(0, 0, 0, 0.6)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	-- Placeholder visual
	love.graphics.setColor(1, 1, 1, 1)
	local img = love.graphics.newImage("assets/planet.png")
	love.graphics.draw(img, love.graphics.getWidth() / 2 - img:getWidth() / 2, 150)

	-- Text box
	local font = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 26)
	love.graphics.setFont(font)

	local padding = 30
	local text = self.message or ""
	local textWidth = font:getWidth(text)
	local boxWidth = math.min(love.graphics.getWidth() * 0.8, textWidth + padding * 2)
	local boxX = (love.graphics.getWidth() - boxWidth) / 2
	local boxY = 320

	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", boxX, boxY - 20, boxWidth, 120, 12, 12)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(text, 0, boxY, love.graphics.getWidth(), "center")

	-- Buttons
	for _, b in ipairs(self.buttons) do
		b:draw()
	end

	-- Visual feedback (like screen shake placeholder)
	if self.state == "investigating" then
		local flicker = math.random()
		if flicker > 0.9 then
			love.graphics.setColor(1, 1, 1, 0.1)
			love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		end
	end
end

return AnomalyNodeHandler
