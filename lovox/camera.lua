local PATH = (...):gsub('%.[^%.]+$', '')

local Transform = require (PATH .. '.transform')

local Camera = {
   basicShader = love.graphics.newShader(PATH:gsub('%.', '/').."/basicShader.glsl"),
   frameShader = love.graphics.newShader(PATH:gsub('%.', '/').."/frameShader.glsl"),
}
Camera.__index = Camera

--- Generates a new Camera.
-- @param w, h The dimension of the Camera. Defaults to window size
-- @returns A new Camera object.
function Camera.new(w, h)
   local transform = Transform():reset()
   return setmetatable({
      shader    = Camera.basicShader,
      color     = nil,
      depth     = nil,
      canvas    = nil,
      rendering = false,
      transform = transform,

      dirtyTransform    = false,
      inverseTransform  = transform:inverse()
   }, Camera):resize(w, h)
end

local function sendCamera(self)
   if self.rendering then -- If the user is rendering to the camera

      -- Send the projection matrix to the shader
      if self.shader:hasUniform("projection") then
         self.shader:send("projection", self.projection)
      end

      -- Send the view matrix to the shader
      if self.shader:hasUniform("view") then
         self.shader:send("view", self.transform:send())
      end
   end

   return self
end

--- Resizes the Camera.
-- @param w, h The dimension of the Camera. Defaults to window size
-- @returns self.
function Camera:resize(w, h)
   if self.rendering then
      error("You can't resize the Camera while you are drawing to it", 2)
   end

   w, h = w or love.graphics.getWidth(), h or love.graphics.getHeight()

   self.projection = {
      1,   0,  0, 0,
      0,   1, -1, 0,
      0, 1/h,  0, 0,
      0,   0,  0, 1,
   }

   self.color = love.graphics.newCanvas(w, h, {format = "rgba8"})
   self.depth = love.graphics.newCanvas(w, h, {format = "depth24"})

   self.canvas = {self.color, depthstencil = self.depth}

   return self
end

--- Set the active shader for the Camera.
-- @param shader The shader to use. Defaults to the Lovox shader
-- @returns self
function Camera:setShader(shader)
   if shader == "frame" then
      self.shader = Camera.frameShader
   elseif shader == "basic" or shader == nil then
      self.shader = Camera.basicShader
   else
      self.shader = shader
   end

   if self.rendering then
      love.graphics.setShader(self.shader)
   end

   return sendCamera(self)
end

--- Get the active shader for the Camera.
-- @returns shader The shader object for the active shader
function Camera:getShader()
   return self.shader
end

function Camera:setTransformation(...)
   self.transform:setTransformation(...)
   self.dirtyTransform = true
   return sendCamera(self)
end

--- Translates the Camera
-- @param tx, ty, tz Amount to translate in the x, y, z axis respectively
-- @returns self
function Camera:translate(tx, ty, tz)
   self.transform:translate(tx, ty, tz)
   self.dirtyTransform = true
   return sendCamera(self)
end

--- Scales the Camera.
-- @param sx, sy, sz Scale factors for x, y, z axis respectively
-- @returns self
function Camera:scale(sx, sy, sz)
   self.transform:scale(sx, sy, sz)
   self.dirtyTransform = true
   return sendCamera(self)
end

--- Rotates the Camera.
-- @param angle The angle (in radians) to rotate
-- @returns self
function Camera:rotate(angle)
   self.transform:rotate(angle)
   self.dirtyTransform = true
   return sendCamera(self)
end

--- Shears the Camera.
-- @param kx, ky Shearing factors for X and Y
-- @returns self
function Camera:shear(kx, ky)
   self.transform:shear(kx, ky)
   self.dirtyTransform = true
   return sendCamera(self)
end

--- Resets the Camera's transformation.
-- @returns self
function Camera:origin()
   self.transform:reset()
   self.dirtyTransform = true
   return sendCamera(self)
end

function Camera:transformPoint(x, y, z)
   return self.transform:transformPoint(x, y, z)
end

function Camera:inverseTransformPoint(x, y, z)
   if self.dirtyTransform then
      self.transform:inverse(self.inverse)
      self.dirty = false
   end

   return self.inverse:transformPoint(x, y, z)
end

local function clear(self, r, g, b, a)
   self:clear(r, g, b, a)
end

--- Clear the Camera's canvas to a specific color.
-- @param r, g, b, a The r, g, b, a components for the color. Defaults to love.graphics.getBackgroundColor()
-- @returns self
function Camera:clear(r, g, b, a)
   if self.rendering then
      local br, bg, bb = love.graphics.getBackgroundColor()
      love.graphics.clear(r or br, g or bg, b or bb, a or 1, true, 1)
   else
      self:renderTo(clear, self, r, g, b, a)
   end

   return self
end

--- Render to the Camera's canvas.
-- @param func The function that will render to the canvas
-- @param ... Any extra argument will be passed to func
-- @returns self
function Camera:renderTo(func, ...)
   love.graphics.setDepthMode("lequal", true) --luacheck: ignore
   love.graphics.setCanvas(self.canvas)
   love.graphics.setShader(self.shader)

   self.rendering = true
   sendCamera(self)

   func(...) --Should probably pcall or xpcall

   love.graphics.setDepthMode() --luacheck: ignore
   love.graphics.setCanvas()
   love.graphics.setShader()

   self.rendering = false

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
function Camera:render(...)
   if self.rendering then
      error("Can't render a Camera to itself", 2)
   end

   love.graphics.draw(self.color, ...)

   return self
end

return setmetatable(Camera, {
   __call = function(_, ...) return Camera.new(...) end,
})
