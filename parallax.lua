-- parallax.lua
local parallax = {}

function parallax.load()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()

  parallax.layers = {
    { image = love.graphics.newImage("assets/space_background/blue-back.png"), speed = 0.02, type = "tile", scale = 4 },
    { image = love.graphics.newImage("assets/space_background/blue-stars.png"), speed = 0.03, type = "tile", scale = 4 },
    { image = love.graphics.newImage("assets/space_background/prop-planet-small.png"), speed = 0.05, type = "random" },
    { image = love.graphics.newImage("assets/space_background/prop-planet-big.png"), speed = 0.08, type = "random" },
    { image = love.graphics.newImage("assets/space_background/asteroid-1.png"), speed = 0.1, type = "random" },
    { image = love.graphics.newImage("assets/space_background/asteroid-2.png"), speed = 0.3, type = "random" },
  }

  -- Pre-generate asteroid positions
  for _, layer in ipairs(parallax.layers) do
    if layer.type == "random" then
      layer.objects = {}
      for i = 1, 25 do -- number of asteroids per layer
        table.insert(layer.objects, {
          x = math.random(0, w * 2),
          y = math.random(0, h * 2),
          rot = math.random() * math.pi * 2,
          scale = 0.5 + math.random() * 0.7,
        })
      end
    end
  end

  parallax.time = 0
  parallax.camera = { x = 0, y = 0 }
end

function parallax.update(dt, playerX, playerY)
  parallax.time = parallax.time + dt
  parallax.camera.x = playerX or parallax.camera.x
  parallax.camera.y = playerY or parallax.camera.y
end

function parallax.draw()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local camX, camY = parallax.camera.x, parallax.camera.y

  for _, layer in ipairs(parallax.layers) do
    local img = layer.image
    local speed = layer.speed
    local scale = layer.scale or 1
    local iw, ih = img:getWidth() * scale, img:getHeight() * scale

    if layer.type == "tile" then
      local xOffset = (camX * speed) % iw
      local yOffset = (camY * speed) % ih

      for x = -iw, w + iw, iw do
        for y = -ih, h + ih, ih do
          love.graphics.draw(img, x - xOffset, y - yOffset, 0, scale, scale)
        end
      end
    elseif layer.type == "random" then
      for _, obj in ipairs(layer.objects) do
        local px = obj.x - camX * speed
        local py = obj.y - camY * speed
        if px < -200 then px = px + w * 2 end
        if px > w * 2 then px = px - w * 2 end
        if py < -200 then py = py + h * 2 end
        if py > h * 2 then py = py - h * 2 end
        love.graphics.draw(img, px, py, obj.rot, obj.scale, obj.scale, img:getWidth()/2, img:getHeight()/2)
      end
    end
  end
end

return parallax
