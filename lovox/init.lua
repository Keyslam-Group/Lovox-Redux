local PATH = (...):gsub('%.init$', '')

local Lovox = {
   voxelData   = require(PATH..".voxelData"),
   depthBuffer = require(PATH..".depthBuffer"),
   mat4        = require(PATH..".mat4"),
}

local notSupported = false
do
   local supported -- = love.graphics.getTextureTypes()

   -- if not supported.array then
      -- notSupported = "Array images are not supported on this device"
   -- end
  
   supported = love.graphics.getSupported()

   if not supported.glsl3 then
      notSupported = "GLSL 3 shaders are not supported on this device"
   elseif not supported.instancing then
      notSupported = "Mesh instancing is not supported on this device"
   end
end

--- Checks if Lovox is supported on the system.
-- @returns boolean true if Lovox is supported. False otherwise.
function Lovox.isSupported()
   if notSupported then
      return false, notSupported
   end

   return true
end

function Lovox.draw(texture, layers, x, y, z, rotation, sx, sy, sz, ox, oy, oz, kx, ky)
   local voxelData = Lovox.voxelData(texture, layers, 1, "static")
   voxelData:set(1, x, y, z, rotation, sx, sy, sz, ox, oy, oz, kx, ky)
   voxelData:draw()
end

return Lovox