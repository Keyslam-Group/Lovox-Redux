local PATH = (...):gsub('%.init$', '')

local Lovox = {
   voxelBatch = require(PATH..".voxelBatch"),
   camera     = require(PATH..".camera"),
   transform  = require(PATH..".transform"),
}

local notSupported = false
do
   local supported = love.graphics.getSupported()

   if not supported.glsl3 then
      notSupported = "GLSL 3 shaders are not supported on this device"
   elseif not supported.instancing then
      notSupported = "Mesh instancing is not supported on this device"
   end

   local status = jit.status()
   if not status then
      notSupported = "FFI is not enabled"
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
   local voxelBatch = Lovox.voxelBatch(texture, layers, 1, "static")
   voxelBatch:set(1, x, y, z, rotation, sx, sy, sz, ox, oy, oz, kx, ky)
   voxelBatch:draw()
end

return Lovox