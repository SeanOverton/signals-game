Animation = {}
Animation.__index = Animation

-- Shared sound memory across all animations
Animation.soundMemory = {
	sound = nil,
	lastPlayTime = {},
	pitchByType = {},
}

Animation.typeMemory = { countByType = {}, lastTime = {} }

function Animation:new(type, text, x, y, color)
	local obj = setmetatable({
		type = type, -- e.g. "fuel", "hull", "money"
		text = text,
		x = x,
		y = y,
		alpha = 1,
		lifetime = 0.5,
		timer = 0,
		color = color or { 1, 1, 1 },
	}, Animation)

	return obj
end

-- 🔊 Sound system (added)
function Animation:playSound()
	-- Lazy-load sound once
	if not Animation.soundMemory.sound then
		local ok, sound = pcall(function()
			return love.audio.newSource("audio/retro-coin.mp3", "static")
		end)
		if ok and sound then
			Animation.soundMemory.sound = sound
		else
			print("[WARN] Could not load sound: audio/retro-coin.mp3")
			return
		end
	end

	local now = love.timer.getTime()
	local t = self.type
	local pitch = 1.0

	-- If another animation of same type just played, increase pitch
	if Animation.soundMemory.lastPlayTime[t] and now - Animation.soundMemory.lastPlayTime[t] < 0.6 then
		local prevPitch = Animation.soundMemory.pitchByType[t] or 1.0
		pitch = math.min(prevPitch + 0.1, 1.5)
	end

	Animation.soundMemory.pitchByType[t] = pitch
	Animation.soundMemory.lastPlayTime[t] = now

	local s = Animation.soundMemory.sound:clone()
	s:setPitch(pitch)
	s:play()
end

function Animation:applyStackedOffset()
	local now = love.timer.getTime()
	local t = self.type

	-- previous timestamp and count
	local lastTime = Animation.typeMemory.lastTime[t] or 0
	local prevCount = Animation.typeMemory.countByType[t] or 0

	local PIXELS_SPACE = 100

	-- if another animation of same type just played within 0.6s
	if now - lastTime < 0.6 then
		prevCount = prevCount + 1
		self.x = math.min(self.x + PIXELS_SPACE * prevCount, love.graphics.getWidth() - 100)
	else
		prevCount = 0 -- reset if enough time passed
	end

	-- update memory
	Animation.typeMemory.countByType[t] = prevCount
	Animation.typeMemory.lastTime[t] = now
end

-- 🧩 Keep all your original methods
function Animation:start()
	self:playSound()
	self:applyStackedOffset()
end

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

function getResourceAnimation(animationSystem, eventName, x, y)
	local func = function(data)
		local text = (data.change > 0 and "+" or "") .. tostring(data.change) .. " " .. tostring(data.type)
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
	eventManager.on("oxygenUpdated", getResourceAnimation(animationSystem, "oxygenUpdated", 100, 80))
	eventManager.on("moneyUpdated", getResourceAnimation(animationSystem, "moneyUpdated", 100, 120))
	eventManager.on("hullUpdated", getResourceAnimation(animationSystem, "hullUpdated", 100, 160))
	eventManager.on("signalsUpdated", getResourceAnimation(animationSystem, "signalUpdated", 100, 200))
end

Animation.registerResourceAnimations = registerAnimations

return Animation
