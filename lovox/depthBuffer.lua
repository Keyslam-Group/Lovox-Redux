local PATH = (...):gsub('%.[^%.]+$', '')

local DepthBuffer = {
   activeBuffer = nil,
}
DepthBuffer.__index = DepthBuffer

function DepthBuffer.new(w, h)
   return setmetatable({
      shader = nil,
      color  = nil,
      depth  = nil,
      canvas = nil,
   }, DepthBuffer):resize(w, h)
end

function DepthBuffer:resize(w, h)
   w, h = w or love.graphics.getWidth(), h or love.graphics.getHeight()

   self.shader = love.graphics.newShader(PATH.."/shader.glsl")

   self.color = love.graphics.newCanvas(w, h, {format = "rgba8"})
   self.depth = love.graphics.newCanvas(w, h, {format = "depth24"})

   self.canvas = {self.color, depthstencil = self.depth}

   return self
end

function DepthBuffer:attach()
   love.graphics.setDepthMode("lequal", true)
   love.graphics.setCanvas(self.canvas)

   local r, g, b = love.graphics.getBackgroundColor()
   love.graphics.clear(r, g, b, 1, true, 1)
   love.graphics.setShader(self.shader)

   DepthBuffer.activeBuffer = self

   return self
end

function DepthBuffer.detach()
   love.graphics.setDepthMode()
   love.graphics.setCanvas()
   love.graphics.setShader()

   DepthBuffer.activeBuffer = nil
end

function DepthBuffer:draw(...)
   love.graphics.draw(self.canvas[1], ...)
end

return setmetatable(DepthBuffer, {
   __call = function(_, ...) return DepthBuffer.new(...) end,
})
