love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBackgroundColor(0.75, 0.75, 0.75)

local Lovox = require("lovox")

local img = love.graphics.newArrayImage({
   "boat/texture.png"
})

local myVoxelData   = Lovox.voxelData(img, 64, 32, 16, 7000, "dynamic")
local myDepthBuffer = Lovox.depthBuffer()

for x = 0, 19 do
   for y = 0, 21 do
      for z = 0, 9 do
         local id = x * 220 + y * 10 + z + 1
         myVoxelData:updateVoxel(id, x * 80, y * 40, z * 40, 0, 1, 255, 255, 255)
      end
   end
   
end

function love.update(dt)
   myVoxelData:apply()
end

function love.draw()
   love.graphics.push()
   love.graphics.translate(640, 320)
   love.graphics.rotate(love.timer.getTime())
   love.graphics.translate(-640, -320)
   love.graphics.setColor(1, 1, 1, 1)
   myDepthBuffer:attach()
      myVoxelData:draw()
   myDepthBuffer:detach()

   love.graphics.pop()

   myDepthBuffer:draw()

   love.graphics.print(love.timer.getFPS())
end

function love.resize()
   myDepthBuffer:resize()
end