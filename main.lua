love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBackgroundColor(0.75, 0.75, 0.75)

local Lovox = require("lovox")

local img = love.graphics.newImage("boat/texture.png")

local myVoxelData   = Lovox.voxelData(love.graphics.newImage("boat/texture.png"), 64, 32, 16, 2, "dynamic")
local myDepthBuffer = Lovox.depthBuffer()

function love.update(dt)
   --myVoxelData:updateVoxel(1, 100, 100, 0, love.timer.getTime(), 4, 4, 255, 255, 255)
   --myVoxelData:updateVoxel(2, 100, 100 + math.cos(love.timer.getTime() / 3) * 50, 0.01, love.timer.getTime() * 1.2, 4, 4, 255, 255, 255)
   --myVoxelData:apply()
end

function love.draw()
   myDepthBuffer:attach()
      for i = 1, 500 do
         Lovox.draw(img, 64, 32, 16, i * 50, 100, 0, love.timer.getTime(), 4, 4, 255, 255, 255)
      end
   myDepthBuffer:detach()

   myDepthBuffer:draw()

   love.graphics.print(love.timer.getFPS())
end