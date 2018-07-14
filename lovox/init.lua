local PATH = (...):gsub('%.init$', '')

local Lovox = {
   voxelData   = require(PATH..".voxelData"),
   depthBuffer = require(PATH..".depthBuffer"),
}

function Lovox.newModel()

end

function Lovox.draw(texture, width, height, layers, x, y, z, rotation, sx, sy, r, g, b)
   local voxelData = Lovox.voxelData(texture, width, height, layers, 1, "static")
   voxelData:updateVoxel(1, x, y, z, rotation, sx, sy, r, g, b)
   voxelData:apply()

   voxelData:draw()
end

return Lovox