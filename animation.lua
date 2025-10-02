Animation = {}
Animation.__index = Animation

function Animation:new(type, text, x, y, color)
	return setmetatable({
		type = type, -- e.g. "fuel", "hull", "money"
		text = text,
		x = x,
		y = y,
		alpha = 1,
		lifetime = 0.5,
		timer = 0,
		color = color or { 1, 1, 1 },
	}, Animation)
end

function Animation:start() end

function Animation:update(dt)
	self.timer = self.timer + dt
	self.y = self.y - 20 * dt
	self.alpha = 1 - (self.timer / self.lifetime)
end

function Animation:isFinished()
	return self.timer >= self.lifetime
end

function Animation:draw()
	love.graphics.setFont(love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 64))
	love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)
	love.graphics.print(self.text, self.x, self.y)
	love.graphics.setFont(love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 26))
	love.graphics.setColor(1, 1, 1, 1)
end

local M = {}

function getResourceAnimation(animationSystem, eventName, x, y)
	local func = function(data)
		local text = (data.change > 0 and "+" or "") .. tostring(data.change)
		local color = { 0, 1, 0 }
		if data.change < 0 then
			color = { 1, 0, 0 }
		end
		animationSystem:enqueue(Animation:new(eventName, text, x, y, color))
	end
	return func
end

function registerAnimations(eventManager, animationSystem)
	eventManager.on("fuelUpdated", getResourceAnimation(animationSystem, "fuelUpdated", 100, 40))
	eventManager.on("moneyUpdated", getResourceAnimation(animationSystem, "moneyUpdated", 100, 80))
	eventManager.on("oxygenUpdated", getResourceAnimation(animationSystem, "oxygenUpdated", 100, 120))
	eventManager.on("signalsUpdated", getResourceAnimation(animationSystem, "signalUpdated", 100, 160))
end

M.registerResourceAnimations = registerAnimations

return M
