local PATH = (...):gsub('%.init$', '')

local Lovox = {
   voxelData   = require(PATH..".voxelData"),
   depthBuffer = require(PATH..".depthBuffer"),
   mat4        = require(PATH..".mat4"),
}

--- Checks if Lovox is supported on the system.
-- @returns boolean true if Lovox is supported. False otherwise.
function Lovox.isSupported()
   if not love.graphics.getTextureTypes().array then
      return false, "Array images are not supported on this device"
   end

   if not love.graphics.getSupported().glsl3 then
      return false, "GLSL 3 shaders are not supported on this device"
   end

   if not love.graphics.getSupported().instancing then
      return false, "Mesh instancing is not supported on this device"
   end

   -- Should be supported if GLSL3 is supported
   if not love.graphics.getSupported().multicanvasformates then
      return false, "Multiple canvases are not supported on this device"
   end

   return true
end

function Lovox.draw(texture, layers, x, y, z, rotation, sx, sy, sz, ox, oy, oz, kx, ky)
   local voxelData = Lovox.voxelData(texture, layers, 1, "static")
   voxelData:set(1, x, y, z, rotation, sx, sy, sz, ox, oy, oz, kx, ky)
   voxelData:draw()
end

return Lovox