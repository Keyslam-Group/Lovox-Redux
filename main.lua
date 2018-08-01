love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBackgroundColor(0.75, 0.75, 0.75)

local Lovox = require("lovox")

local img = love.graphics.newImage("boat/texture.png")

local myVoxelData   = Lovox.voxelData(img, 16, 16, "dynamic")
local myDepthBuffer = Lovox.depthBuffer()

function love.update(dt)
   for x = 0, 3 do
      for y = 0, 3 do
         local id = x * 4 + y
         local inst = myVoxelData.vertexBuffer[id]

         inst:setIdentity()
         inst:scale(1, 1, 1)
            
         inst:translate(x * 128, y * 64, 0)
      end
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