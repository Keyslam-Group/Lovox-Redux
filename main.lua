love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBackgroundColor(0.75, 0.75, 0.75)

local Lovox = require("lovox")

local img = love.graphics.newImage("boat/texture.png")

local myVoxelData   = Lovox.voxelData(img, 64, 32, 16, 1000, "dynamic")
local myDepthBuffer = Lovox.depthBuffer()

for x = 0, 9 do
   for y = 0, 9 do
      for z = 0, 9 do
         local id = x * 100 + y * 10 + z + 1
         local inst = myVoxelData.vertexBuffer[id]

         inst:setIdentity()
         inst:scale(1, 1, 1)
         inst:translate(x * 64, y * 32, z * 32)
         
         
      end
   end
end
myVoxelData.modelAttributes:setVertices(myVoxelData.instanceData)

function love.update(dt)
   
end

function love.draw()
   love.graphics.rotate(0.4)
   myDepthBuffer:attach()
      myVoxelData:draw()
   myDepthBuffer:detach()
   love.graphics.rotate(-0.4)

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