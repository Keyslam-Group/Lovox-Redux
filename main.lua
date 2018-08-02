love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBackgroundColor(0.75, 0.75, 0.75)

local Lovox = require("lovox")

local img = love.graphics.newImage("boat/texture.png")

local myVoxelData   = Lovox.voxelData(img, 16, 256, "dynamic")
local myDepthBuffer = Lovox.depthBuffer()

for i = 1, 256 do
   myVoxelData:add(i * 64, 100)
end

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

function love.keypressed(key)
   if key == "q" then
      love.event.quit()
   end

   if key == "a" then
      y = y + 64
      for i = 1, 16 do
         myVoxelData:add(i * 64, y)
      end
   end

   if key == "d" then
      myVoxelData:flush()
   end
end