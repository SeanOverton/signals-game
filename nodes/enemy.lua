local CombatNodeHandler = {
	buttons = {},
	state = "intro",
	lastState = nil,
	playerHP = 3,
	enemyHP = 3,
	message = "You encounter Scavenger Raiders!",
	resolved = false,
	playerAction = nil,
	playerAnim = { alpha = 0, image = "assets/rocketIdle.png" },
	enemyAnim = { alpha = 0, image = "assets/satellite.png" },
	defenseActive = false,
	timer = 0,
}

function CombatNodeHandler:load(CurrentNode, modal)
	self.state = "intro"
	self.lastState = nil
	self.resolved = false
	self.playerHP = 3
	self.enemyHP = 3
	self.defenseActive = false
	self.timer = 0
	self.message = CurrentNode.question or "An unknown ship approaches..."
	self:createButtonsForState("intro", modal)
end

function CombatNodeHandler:createButtonsForState(state, modal)
	if self.lastState == state then
		return
	end
	self.lastState = state
	self.buttons = {}

	if state == "intro" then
		local startButton = Button:new(love.graphics.getWidth() / 2 - 100, 500, "Engage", 24, function()
			self.state = "combat"
			self.message = "You prepare for battle!"
			self:createButtonsForState("combat", modal)
		end, { showBorder = true })
		table.insert(self.buttons, startButton)
	elseif state == "combat" then
		local attackButton = Button:new(love.graphics.getWidth() / 2 - 200, 500, "Attack", 24, function()
			self:defendReset()
			self:triggerPlayerAnim("attack")
			local hit = math.random() < 0.7
			if hit then
				self.enemyHP = self.enemyHP - 1
				self.message = "Direct hit! Enemy hull integrity down to " .. self.enemyHP .. "."
			else
				self.message = "Your shot missed!"
			end
			if self.enemyHP <= 0 then
				self.state = "win"
				self.message = "You defeated the raiders! You salvage +5 money."
				self:createButtonsForState("win", modal)
				return
			end
			self:enemyTurn(modal)
		end, { showBorder = true })

		local defendButton = Button:new(love.graphics.getWidth() / 2 + 50, 500, "Defend", 24, function()
			self:defendActivate()
			self:triggerPlayerAnim("defend")
			self.message = "You reinforce shields — next hit reduced!"
			self:enemyTurn(modal, true)
		end, { showBorder = true })

		table.insert(self.buttons, attackButton)
		table.insert(self.buttons, defendButton)
	elseif state == "lose" or state == "win" then
		local continueButton = Button:new(love.graphics.getWidth() / 2 - 100, 500, "Continue", 24, function()
			if self.state == "win" then
				updateResource("money", 5)
			else
				updateResource("hull", -1)
			end
			markNodeAsVisited()
			self.resolved = true
		end, { showBorder = true })
		table.insert(self.buttons, continueButton)
	end
end

function CombatNodeHandler:defendActivate()
	self.defenseActive = true
end

function CombatNodeHandler:defendReset()
	self.defenseActive = false
end

function CombatNodeHandler:triggerPlayerAnim(type)
	self.playerAction = type
	self.playerAnim.alpha = 1
	self.timer = 0
end

function CombatNodeHandler:triggerEnemyAnim(type)
	self.enemyAnim.alpha = 1
	self.timer = 0
end

function CombatNodeHandler:enemyTurn(modal)
	self:triggerEnemyAnim("attack")

	local hit = math.random() < 0.6
	if hit then
		local damage = 1
		if self.defenseActive then
			damage = 0.5
			if math.random() < 0.3 then
				self.enemyHP = self.enemyHP - 1
				self.message = self.message .. "\nYou deflect and scorch the enemy hull!"
			else
				self.message = self.message .. "\nYour shields absorb most of the damage."
			end
			self:defendReset()
		else
			self.message = self.message .. "\nEnemy lasers strike your hull!"
		end
		self.playerHP = math.max(0, self.playerHP - damage)
	else
		self.message = self.message .. "\nEnemy attack missed!"
	end

	if self.playerHP <= 0 then
		self.state = "lose"
		self.message = "Your ship is destroyed! Hull integrity failed."
		self:createButtonsForState("lose", modal)
	end
end

function CombatNodeHandler:update(dt)
	if self.resolved then
		return
	end

	-- fade animation
	if self.playerAnim.alpha > 0 then
		self.playerAnim.alpha = self.playerAnim.alpha - dt * 1.5
	end
	if self.enemyAnim.alpha > 0 then
		self.enemyAnim.alpha = self.enemyAnim.alpha - dt * 1.5
	end

	local mx, my = love.mouse.getPosition()
	local mousePressed = love.mouse.isDown(1)
	for _, b in ipairs(self.buttons) do
		b:update(dt, mx, my, mousePressed)
	end
end

function CombatNodeHandler:draw()
	-- Draw combatants
	local screenW = love.graphics.getWidth()
	local screenH = love.graphics.getHeight()
	local shipY = 180

	-- Player ship
	local playerImage = love.graphics.newImage(self.playerAnim.image)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(playerImage, screenW * 0.25 - playerImage:getWidth() / 2, shipY)

	-- Player attack flash
	if self.playerAnim.alpha > 0 then
		love.graphics.setColor(1, 0.2, 0.2, self.playerAnim.alpha)
		love.graphics.rectangle("fill", screenW * 0.25 - 50, shipY - 20, 100, 100)
	end

	-- Enemy ship
	local enemyImage = love.graphics.newImage(self.enemyAnim.image)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(enemyImage, screenW * 0.75 - enemyImage:getWidth() / 2, shipY)

	-- Enemy flash
	if self.enemyAnim.alpha > 0 then
		love.graphics.setColor(1, 0.2, 0.2, self.enemyAnim.alpha)
		love.graphics.rectangle("fill", screenW * 0.75 - 50, shipY - 20, 100, 100)
	end

	-- Reset draw color
	love.graphics.setColor(1, 1, 1, 1)

	-- Background box for text
	love.graphics.setFont(love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 26))
	local text = self.message or ""
	local font = love.graphics.getFont()
	local padding = 20
	local boxWidth = math.min(love.graphics.getWidth() * 0.8, font:getWidth(text) + padding * 2)
	local boxX = (love.graphics.getWidth() - boxWidth) / 2
	local boxY = 300

	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", boxX, boxY - padding / 2, boxWidth, 100, 12, 12)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(text, 0, boxY, love.graphics.getWidth(), "center")

	-- HP text
	love.graphics.printf("Your HP: " .. self.playerHP, 100, 100, 200, "left")
	love.graphics.printf("Enemy HP: " .. self.enemyHP, screenW - 300, 100, 200, "right")

	for _, b in ipairs(self.buttons) do
		b:draw()
	end
end

return CombatNodeHandler
