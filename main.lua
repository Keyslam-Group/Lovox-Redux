love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBackgroundColor(0.75, 0.75, 0.75)

local Lovox = require("lovox")

local img = love.graphics.newArrayImage({
   "boat/texture.png",
   "crate_big/texture.png",
})

local myVoxelData   = Lovox.voxelData(img, 64, 32, 16, 1, "dynamic")
local myDepthBuffer = Lovox.depthBuffer()

function love.update(dt)
   myVoxelData:updateVoxel(1, 500, 300, 0, love.timer.getTime(), 2, 2, 255, 255, 255)
   myVoxelData:apply()
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