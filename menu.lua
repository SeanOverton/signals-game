local loveli = require("LOVELi")

local Menu = {}

function Menu:load()
	local font = loveli.Property.parse(love.graphics.getFont() )
	local textcolor = loveli.Property.parse(loveli.Color.parse(0xFFFFFFFF) )
	local backgroundcolor = loveli.Property.parse(loveli.Color.parse(0xDF4794FF) )
	label = loveli.Label:new{ text = "FPS: 0", font = font, textcolor = textcolor, x = 0, y = 0, width = 75, height = "auto" } 
	layoutmanager = loveli.LayoutManager:new{}
		:with(loveli.AbsoluteLayout:new{ width = "*", height = "*", margin = loveli.Thickness.parse(10) }
			:with(label)
			:with(loveli.Label:new{ text = "Press ESC to show layout lines", font = font, textcolor = loveli.Color.parse(0x00FF00FF), x = 0, y = 0, width = "auto", height = "auto", horizontaloptions = "center", verticaloptions = "end" } )
			:with(loveli.Grid:new{ rowdefinitions = { "1*" }, columndefinitions = { "1*" }, x = 0, y = 0, width = "*", height = "*" }
				:with(1, 1, loveli.StackLayout:new{ orientation = "vertical", spacing = 10, width = "auto", height = "auto", horizontaloptions = "center", verticaloptions = "center" }
					:with(loveli.Label:new{ text = "LOVELi (LOVE Layout and GUI)", font = font, textcolor = textcolor, horizontaloptions = "center" } )			
					:with(loveli.Button:new{ clicked = function(sender) print(sender:gettext() ) end, text = "New Game", font = font, textcolor = textcolor, backgroundcolor = backgroundcolor, bordercolor = textcolor, width = 150, height = 60, horizontaloptions = "center" } )
					:with(loveli.Button:new{ clicked = function(sender) print(sender:gettext() ) end, text = "Continue", font = font, textcolor = textcolor, backgroundcolor = backgroundcolor, bordercolor = textcolor, width = 150, height = 60, horizontaloptions = "center" } )
					:with(loveli.Button:new{ clicked = function(sender) print(sender:gettext() ) end, text = "Options", font = font, textcolor = textcolor, backgroundcolor = backgroundcolor, bordercolor = textcolor, width = 150, height = 60, horizontaloptions = "center" } )
					:with(loveli.Button:new{ clicked = function(sender) print(sender:gettext() ) end, text = "Credits", font = font, textcolor = textcolor, backgroundcolor = backgroundcolor, bordercolor = textcolor, width = 150, height = 60, horizontaloptions = "center" } )
					:with(loveli.Button:new{ clicked = function(sender) print(sender:gettext() ) end, text = "Exit", font = font, textcolor = textcolor, backgroundcolor = backgroundcolor, bordercolor = textcolor, width = 150, height = 60, horizontaloptions = "center" } )
				)
			)
		)
	return stacklayout
end

function Menu:draw()
	layoutmanager:draw()
end

function Menu:update(dt)
	layoutmanager:update(dt)
end

return Menu
