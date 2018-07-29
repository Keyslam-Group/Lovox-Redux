local PATH = (...):gsub('%.[^%.]+$', '')

local DepthBuffer = {
   activeBuffer = nil,
}
DepthBuffer.__index = DepthBuffer

--- Generates a new DepthBuffer.
-- @param w, h The dimension of the DepthBuffer. Defaults to window size
-- @returns A new DepthBuffer object.
function DepthBuffer.new(w, h)
   return setmetatable({
      shader = nil,
      color  = nil,
      depth  = nil,
      canvas = nil,
   }, DepthBuffer):resize(w, h)
end

--- Resizes the DepthBuffer.
-- @param w, h The dimension of the DepthBuffer. Defaults to window size
-- @returns self.
function DepthBuffer:resize(w, h)
   w, h = w or love.graphics.getWidth(), h or love.graphics.getHeight()

   self.shader = love.graphics.newShader(PATH.."/shader.glsl")
   self.projection = {
      1,   0,  0, 0,
      0,   1, -1, 0,
      0, 1/h,  0, 0,
      0,   0,  0, 1,
   }

   self.shader:send("projection", self.projection)
   self.color = love.graphics.newCanvas(w, h, {format = "rgba8"})
   self.depth = love.graphics.newCanvas(w, h, {format = "depth16"})

   self.canvas = {self.color, depthstencil = self.depth}

   return self
end

--- Attaches a DepthBuffer.
-- @returns self
function DepthBuffer:attach()
   love.graphics.setDepthMode("lequal", true)
   love.graphics.setCanvas(self.canvas)

   local r, g, b = love.graphics.getBackgroundColor()
   love.graphics.clear(r, g, b, 1, true, 1)
   love.graphics.setShader(self.shader)

   DepthBuffer.activeBuffer = self

   return self
end

--- Detaches a DepthBuffer.
-- @returns self
function DepthBuffer:detach()
   love.graphics.setDepthMode()
   love.graphics.setCanvas()
   love.graphics.setShader()

   DepthBuffer.activeBuffer = nil

   return self
end

--- Renders a DepthBuffer to the screen.
-- @param x, y The position to draw the DepthBuffer at
-- @param scale The scale of the DepthBuffer
-- @return self
function DepthBuffer:draw(x, y, scale)
   love.graphics.draw(self.canvas[1], x, y, nil, scale, scale)

   return self
end

return setmetatable(DepthBuffer, {
   __call = function(_, ...) return DepthBuffer.new(...) end,
})
