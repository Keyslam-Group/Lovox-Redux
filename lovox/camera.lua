local PATH = (...):gsub('%.[^%.]+$', '')

local Camera = {
   activeCamera = nil,
}
Camera.__index = Camera

local defaultShader = love.graphics.newShader(PATH.."/shader.glsl")

--- Generates a new Camera.
-- @param w, h The dimension of the Camera. Defaults to window size
-- @returns A new Camera object.
function Camera.new(w, h)
   return setmetatable({
      shader = defaultShader,
      color  = nil,
      depth  = nil,
      canvas = nil,
   }, Camera):resize(w, h)
end

--- Resizes the Camera.
-- @param w, h The dimension of the Camera. Defaults to window size
-- @returns self.
function Camera:resize(w, h)
   w, h = w or love.graphics.getWidth(), h or love.graphics.getHeight()

   self.projection = {
      1,   0,  0, 0,
      0,   1, -1, 0,
      0, 1/h,  0, 0,
      0,   0,  0, 1,
   }

   self.color = love.graphics.newCanvas(w, h, {format = "rgba8"})
   self.depth = love.graphics.newCanvas(w, h, {format = "depth16"})

   self.canvas = {self.color, depthstencil = self.depth}

   return self
end

function Camera:setShader(shader)
   self.shader = shader or defaultShader
end

function Camera:getShader()
   return self.shader
end

--- Attaches a Camera.
-- @returns self
function Camera:attach()
   love.graphics.setDepthMode("lequal", true)
   love.graphics.setCanvas(self.canvas)

   local r, g, b = love.graphics.getBackgroundColor()
   love.graphics.clear(r, g, b, 1, true, 1)

   if self.shader:hasUniform("projection") then
      self.shader:send("projection", self.projection)
   end

   love.graphics.setShader(self.shader)

   Camera.activeCamera = self

   return self
end

--- Detaches a Camera.
-- @returns self
function Camera:detach()
   love.graphics.setDepthMode()
   love.graphics.setCanvas()
   love.graphics.setShader()

   Camera.activeCamera = nil

   return self
end

--- Returns the Canvas (Texture) objects with the contents of the Camera.
-- @returns color The color texture
-- @returns depth The depth texture
function Camera:getTexture()
   return self.color, self.depth 
end

--- Renders a Camera to the screen.
-- @param x, y The position to draw the Camera at
-- @param angle The angle to rotate the image
-- @param sx The scale of the Camera in the X axis
-- @param sy The scale of the Camera in the Y axis
-- @return self
function Camera:draw(...)
   love.graphics.draw(self.color, ...)

   return self
end

return setmetatable(Camera, {
   __call = function(_, ...) return Camera.new(...) end,
})
