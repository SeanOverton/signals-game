local types = require("./types/main")

local Cutscene = {
	x = 640,
	y = 280,
	angle = 0,
	speed = 8,
	driftUp = 2,
	currentIndex = 1,
	timer = 0,
	typeSpeed = 0.03,
	displayedText = "",
	textComplete = false,
	alpha = 0, -- for fade
	fadingIn = true,
	fadingOut = false,
	fadeSpeed = 1.5,
	scenes = {},
}

function Cutscene:load(menu)
	self.scenes = {
		{
			image = love.graphics.newImage("assets/startScene1.png"),
			caption = "Captain's log, day one - The mission is going perfectly. No chance anything goes wrong out here.",
		},
		{
			image = love.graphics.newImage("assets/startScene2.png"),
			caption = "Update - Minor issue. The navigation AI mistook a black hole for a parking spot.",
		},
		{
			image = love.graphics.newImage("assets/startScene3.png"),
			caption = "Now drifting somewhere beyond... Collecting cosmic signals might be the only way to call for rescue.",
		},
	}

	self.menu = menu

	self.currentIndex = 1
	self.displayedText = ""
	self.textComplete = false
	self.timer = 0
	self.alpha = 0
	self.fadingIn = true
	self.fadingOut = false
end

function Cutscene:update(dt)
	self.x = self.x - self.speed * dt
	self.y = self.y + self.driftUp * dt

	if self.y < 280 or self.y > love.graphics.getHeight() - 280 then
		self.speed = -self.speed
		self.driftUp = -self.driftUp
	end

	-- Fade control
	if self.fadingIn then
		self.alpha = math.min(self.alpha + self.fadeSpeed * dt, 1)
		if self.alpha >= 1 then
			self.fadingIn = false
		end
	elseif self.fadingOut then
		self.alpha = math.max(self.alpha - self.fadeSpeed * dt, 0)
		if self.alpha <= 0 then
			self.fadingOut = false
			self.currentIndex = self.currentIndex + 1
			if self.currentIndex > #self.scenes then
				self.menu.navController:navigateTo(types.GameStateType.Gameplay)
				return
			end
			self.timer = 0
			self.displayedText = ""
			self.textComplete = false
			self.fadingIn = true
		end
	else
		-- Typewriter effect only when not fading
		local currentScene = self.scenes[self.currentIndex]
		if not self.textComplete then
			self.timer = self.timer + dt
			local charsToShow = math.floor(self.timer / self.typeSpeed)
			self.displayedText = string.sub(currentScene.caption, 1, charsToShow)
			if #self.displayedText >= #currentScene.caption then
				self.textComplete = true
			end
		end
	end
end

function Cutscene:keypressed(key)
	if key == "space" and not self.fadingOut then
		if not self.textComplete then
			self.displayedText = self.scenes[self.currentIndex].caption
			self.textComplete = true
		else
			self.fadingOut = true
		end
	end
end

function Cutscene:draw()
	local scene = self.scenes[self.currentIndex]
	if not scene then
		return
	end

	love.graphics.setColor(1, 1, 1, self.alpha)
	local ox = scene.image:getWidth() / 2
	local oy = scene.image:getHeight() / 2
	love.graphics.draw(scene.image, self.x, self.y, self.angle, 5, 5, ox, oy)

	local margin = 40
	local textWidth = love.graphics.getWidth() - margin * 2
	local textHeight = 120
	local rectY = love.graphics.getHeight() - textHeight - 40

	love.graphics.setColor(0, 0, 0, 0.5 * self.alpha)
	love.graphics.rectangle("fill", margin, rectY, textWidth, textHeight, 12, 12)

	love.graphics.setColor(1, 1, 1, self.alpha)
	love.graphics.printf(self.displayedText, margin + 20, rectY + 20, textWidth - 40, "left")

	love.graphics.setColor(1, 1, 1, 0.6 * self.alpha)
	love.graphics.printf("Press [SPACE] to continue", 0, rectY + textHeight - 5, love.graphics.getWidth(), "center")

	love.graphics.setColor(1, 1, 1, 1)
end

function Cutscene:reset()
	self.currentIndex = 1
	self.timer = 0
	self.typeSpeed = 0.03
	self.displayedText = ""
	self.textComplete = false
	self.alpha = 0
	self.fadingIn = true
	self.fadingOut = false
	self.x = 640
	self.y = 280
	self.angle = 0
	self.speed = 8
	self.driftUp = 2
end

return Cutscene
