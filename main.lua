love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBackgroundColor(0.75, 0.75, 0.75)

local Lovox = require("lovox")

local img = love.graphics.newImage("boat/texture.png")

local myVoxelData   = Lovox.voxelData(img, 16, 256, "dynamic")
local myDepthBuffer = Lovox.depthBuffer()

local s = love.timer.getTime()
for i = 1, 256 do
   myVoxelData:add(i * 64, 100)
end
print(love.timer.getTime() - s)

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

local y = 100
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

   if key == "s" then
      myVoxelData:add(x, 100, 0, love.math.random() * math.pi * 2)
      x = x + 80
   end

   if key == "d" then
      myVoxelData:flush()
   end
end