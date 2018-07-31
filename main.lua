love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBackgroundColor(0.75, 0.75, 0.75)

local Lovox = require("lovox")

local img = love.graphics.newImage("boat/texture.png")

local myVoxelData   = Lovox.voxelData(img, 64, 32, 16, 5, "dynamic")
local myDepthBuffer = Lovox.depthBuffer()

function love.update(dt)
   for i = 0, myVoxelData.voxelCount - 1 do
      local inst = myVoxelData.vertexBuffer[i]
      inst:translate(0, 0, 100 * dt)
   end

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
end