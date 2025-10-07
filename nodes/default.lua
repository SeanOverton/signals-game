local DefaultNodeHandler = {
	buttons = {},
	load = function(self, CurrentNode, modal)
		self.buttons = {}
		-- configure buttons from the choices
		for i, choice in ipairs(CurrentNode.choices) do
			local newButton = Button:new(
				love.graphics.getWidth() / 2 - (200 * #CurrentNode.choices / 2) + (i - 1) * 250,
				500,
				choice.text,
				24,
				function()
					choice.effect(updateResource)
					markNodeAsVisited()
				end,
				{ showBorder = true }
			)
			table.insert(self.buttons, newButton)
			if choice.description then
				local infoButton = Button:new(
					love.graphics.getWidth() / 2 - (200 * #CurrentNode.choices / 2) - 30 + (i - 1) * 250,
					500,
					"i",
					20,
					function()
						print(choice.description)
						modal:open(function()
							local FULL_SIZE = 300

							local largeFont = love.graphics.newFont("chonky-bits-font/ChonkyBitsFontRegular.otf", 48)
							love.graphics.setFont(largeFont)

							love.graphics.printf(
								"Effects:",
								love.graphics.getWidth() / 2 - FULL_SIZE / 2,
								love.graphics.getHeight() / 2 - 40,
								FULL_SIZE,
								"center"
							)
							love.graphics.printf(
								choice.description,
								love.graphics.getWidth() / 2 - FULL_SIZE / 2,
								love.graphics.getHeight() / 2,
								FULL_SIZE,
								"center"
							)
						end)
					end,
					{ showBorder = true }
				)
				table.insert(self.buttons, infoButton)
			end
		end
	end,
	update = function(self, dt, _)
		local mx, my = love.mouse.getPosition()
		local mousePressed = love.mouse.isDown(1)
		for _, button in ipairs(self.buttons) do
			button:update(dt, mx, my, mousePressed)
		end
	end,
	draw = function(self)
		for _, b in ipairs(self.buttons) do
			b:draw()
		end
	end,
}

return DefaultNodeHandler
