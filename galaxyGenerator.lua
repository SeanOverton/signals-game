local M = {}

M.storyIndex = 0

-- pass in your NODE_TYPES, Probabilities, NODE_OPTIONS tables
function M.generateGalaxy(nodeTypes, probabilities, nodeOptions, size)
	size = size or 10
	local grid = {}

	-- Flatten weighted probabilities into a helper function
	local weightedList = {}
	local totalWeight = 0
	for _, entry in ipairs(probabilities) do
		totalWeight = totalWeight + entry.weight
		table.insert(weightedList, { type = entry.type, cumulative = totalWeight })
	end

	local function getRandomNodeType()
		local r = math.random() * totalWeight
		for _, entry in ipairs(weightedList) do
			if r <= entry.cumulative then
				return entry.type
			end
		end
		return nodeTypes.EmptySpace
	end

	-- Helper: choose a random variant from NODE_OPTIONS
	local function getNodeConfig(nodeType)
		-- sequential story nodes or not?
		-- comment this out for random again
		if nodeType == nodeTypes.Story then
			-- note: when these are generated up front now... the will no longer be in order?
			-- but it does still guarruntee one of each?
			M.storyIndex = math.min(M.storyIndex + 1, #nodeOptions[nodeType] + 1)
			return nodeOptions[nodeType][M.storyIndex - 1]
		end

		local options = nodeOptions[nodeType]
		if not options or #options == 0 then
			return nil
		end

		return options[math.random(1, #options)]
	end

	-- Main grid generation loop
	for y = 1, size do
		grid[y] = {}
		for x = 1, size do
			local nodeType = getRandomNodeType()
			local nodeConfig = getNodeConfig(nodeType)

			grid[y][x] = {
				x = x,
				y = y,
				type = nodeType,
				config = nodeConfig,
				visited = false,
				discovered = false, -- can reveal later with scans/hints
			}
		end
	end

	return grid
end

function M.printGalaxy(grid)
	if not grid or #grid == 0 then
		print("Galaxy grid is empty or not generated yet.")
		return
	end

	print("=== GALAXY MAP ===")
	for y = 1, #grid do
		local rowStr = ""
		for x = 1, #grid[y] do
			local node = grid[y][x]
			if node and node.type then
				-- make it short for readability
				local typeStr = tostring(node.type)
				typeStr = typeStr:gsub("M%.NODE_TYPES%.", ""):sub(1, 3) -- shorten to first 3 chars
				rowStr = rowStr .. string.format("[%s]", typeStr)
			else
				rowStr = rowStr .. "[---]"
			end
		end
		print(rowStr)
	end
	print("==================")
end

return M
