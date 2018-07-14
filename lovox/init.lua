local PATH = (...):gsub('%.init$', '')

local Lovox = {
   voxelData   = require(PATH..".voxelData"),
   depthBuffer = require(PATH..".depthBuffer"),
}

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

function Lovox.newModel()

end

function Lovox.draw(texture, width, height, layers, x, y, z, rotation, sx, sy, r, g, b)
   local voxelData = Lovox.voxelData(texture, width, height, layers, 1, "static")
   voxelData:updateVoxel(1, x, y, z, rotation, sx, sy, r, g, b)
   voxelData:apply()

   voxelData:draw()
end

return Lovox