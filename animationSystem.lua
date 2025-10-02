AnimationSystem = {
	active = {}, -- { [type] = current animation }
	queues = {}, -- { [type] = { queued animations } }
}

function AnimationSystem:enqueue(anim)
	local t = anim.type

	-- no active anim of this type? run it immediately
	if not self.active[t] then
		self.active[t] = anim
		anim:start()
	else
		-- otherwise, queue it for later
		if not self.queues[t] then
			self.queues[t] = {}
		end
		table.insert(self.queues[t], anim)
	end
end

function AnimationSystem:update(dt)
	for t, anim in pairs(self.active) do
		anim:update(dt)
		if anim:isFinished() then
			-- finished → replace with next queued anim (if any)
			if self.queues[t] and #self.queues[t] > 0 then
				local nextAnim = table.remove(self.queues[t], 1)
				self.active[t] = nextAnim
				nextAnim:start()
			else
				self.active[t] = nil
			end
		end
	end
end

function AnimationSystem:draw()
	for _, anim in pairs(self.active) do
		anim:draw()
	end
end

return AnimationSystem
