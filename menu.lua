local loveli = require("LOVELi")

local Menu = {}

function Menu:load()
	stacklayout = loveli.StackLayout
		:new({ orientation = "vertical", spacing = 5, width = "*", height = "*", margin = loveli.Thickness.parse(10) })
		:with(loveli.Button:new({
			text = "Button 1",
			horizontaltextalignment = "start",
			verticaltextalignment = "center",
			width = 75,
			height = 23,
			horizontaloptions = "start",
		}))
		:with(loveli.Button:new({
			text = "Button 2",
			horizontaltextalignment = "center",
			verticaltextalignment = "center",
			width = 75,
			height = "*",
			horizontaloptions = "center",
		}))
		:with(loveli.Button:new({
			text = "Button 3",
			horizontaltextalignment = "end",
			verticaltextalignment = "center",
			width = 75,
			height = 23,
			horizontaloptions = "end",
		}))
	return stacklayout
end

function Menu:draw()
	stacklayout.draw()
end

function Menu:update()
	stacklayout.update()
end

return Menu
