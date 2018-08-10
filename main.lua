love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBackgroundColor(0.75, 0.75, 0.75)

local Lovox = require("lovox")

local img = love.graphics.newImage("boat/texture.png")

local myVoxelBatch = Lovox.voxelBatch(img, 16, 256, "dynamic")
local myCamera     = Lovox.camera()

for i = 1, 256 do
   myVoxelBatch:add(i * 64, 100)
end

function love.update()
end

local function draw()
   myVoxelBatch:draw()
end

function love.draw()
   myCamera:renderTo(draw)
   myCamera:render()

   love.graphics.print(love.timer.getFPS())
end

function love.resize(w, h)
   myCamera:resize(w, h)
end

function love.keypressed(key)
   if key == "q" then
      love.event.quit()
   end

   if key == "a" then
      for i = 1, 16 do
         myVoxelBatch:setTransformation(i, i * 64, 300)
      end
   end

   if key == "d" then
      myVoxelBatch:clear()
   end
end
