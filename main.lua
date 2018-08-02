love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBackgroundColor(0.75, 0.75, 0.75)

local Lovox = require("lovox")

local img = love.graphics.newImage("boat/texture.png")

local myVoxelData   = Lovox.voxelData(img, 16, 16, "dynamic")
local myDepthBuffer = Lovox.depthBuffer()

function love.update(dt)
   myVoxelData.modelAttributes:setVertices(myVoxelData.instanceData)
end

function love.draw()
   myDepthBuffer:attach()
      myVoxelData:draw()
   myDepthBuffer:detach()

   myDepthBuffer:draw()

   love.graphics.print(love.timer.getFPS())
end

function love.resize()
   myDepthBuffer:resize()
end

local x = 0
function love.keypressed(key)
   if key == "q" then
      love.event.quit()
   end

   if key == "a" then
      for x = 0, 3 do
         for y = 0, 3 do
            local id = x * 4 + y + 1
            myVoxelData:set(id, 200 + x * 160, 200 + y * 160, 0, love.math.random() * math.pi * 2)
         end
      end
   end

   if key == "s" then
      myVoxelData:add(x, 100, 0, love.math.random() * math.pi * 2)
      x = x + 80
   end

   if key == "d" then
      myVoxelData:flush()
   end
end