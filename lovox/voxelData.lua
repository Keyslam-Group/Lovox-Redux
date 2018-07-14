local Ffi = require("ffi")

local sqrt, atan2 = math.sqrt, math.atan2
local cos,  sin   = math.cos,  math.sin

Ffi.cdef[[
   typedef struct {
      float x, y, z;
      float u, v;
      unsigned char r, g, b, a;
   } fm_vertex;
]]

local VoxelData = {
   vertexSize   = Ffi.sizeof("fm_vertex"),
   vertexFormat = {
      {"VertexPosition", "float", 3},
      {"VertexTexCoord", "float", 2},
      {"VertexColor",    "byte",  4},
   }
}
VoxelData.__index = VoxelData

function VoxelData.new(texture, width, height, layers, voxelCount, usage)
   local voxelData = setmetatable({
      rectDiag    = sqrt(width/2 * width/2 + height/2 * height/2),
      rectAngle   = atan2(height/2, width/2),
      uvStep      = 1 / layers, -- UV Steps should be changed to quads

      texture    = texture,
      layers     = layers,
      voxelCount = voxelCount,
      usage      = usage or "dynamic",
      
      vertexCountPer = layers * 6,
      vertexCount    = voxelCount * layers * 6,
      
      memoryUsage = nil,
      byteData    = nil,
      vertices    = nil,
      mesh        = nil,
   }, VoxelData)

   voxelData.memoryUsage = voxelData.vertexCount * VoxelData.vertexSize
   voxelData.byteData    = love.data.newByteData(voxelData.memoryUsage)
   voxelData.vertices    = Ffi.cast("fm_vertex*", voxelData.byteData:getPointer())
   voxelData.mesh        = love.graphics.newMesh(VoxelData.vertexFormat, voxelData.byteData, "triangles", voxelData.usage)

   voxelData.mesh:setTexture(voxelData.texture)

   return voxelData
end

function VoxelData:writeVertex(offset, x, y, z, u, v, r, g, b)
   local vertex = self.vertices[offset]
   vertex.x, vertex.y, vertex.z = x, y, z
   vertex.u, vertex.v           = u, v
   vertex.r, vertex.g, vertex.b = r or 255, g or 255, b or 255
   vertex.a                     = 255

   return self
end

function VoxelData:updateVoxel(id, x, y, z, rotation, sx, sy, r, g, b)
   local offset = (id - 1) * self.vertexCountPer

   local rot, iRot = self.rectAngle + rotation, -self.rectAngle + rotation

   local cRot, sRot   = self.rectDiag * cos(rot),  self.rectDiag * sin(rot)
   local icRot, isRot = self.rectDiag * cos(iRot), self.rectDiag * sin(iRot)

   local tl_x, tl_y = (x -  cRot) * sx, (y -  sRot) * sy
   local tr_x, tr_y = (x + icRot) * sx, (y + isRot) * sy
   local bl_x, bl_y = (x - icRot) * sx, (y - isRot) * sy
   local br_x, br_y = (x +  cRot) * sx, (y +  sRot) * sy

   for layer = 0, self.layers - 1 do
      local start_u, end_u = layer * self.uvStep, layer * self.uvStep + self.uvStep
      local o = offset + (layer * 6)

      local z = (z + layer) * sy

      self:writeVertex(o + 0, tl_x, tl_y, z, start_u, 0, r, g, b)
      self:writeVertex(o + 1, tr_x, tr_y, z, end_u,   0, r, g, b)
      self:writeVertex(o + 2, bl_x, bl_y, z, start_u, 1, r, g, b)

      self:writeVertex(o + 3, br_x, br_y, z, end_u,   1, r, g, b)
      self:writeVertex(o + 4, bl_x, bl_y, z, start_u, 1, r, g, b)
      self:writeVertex(o + 5, tr_x, tr_y, z, end_u,   0, r, g, b)
   end

   return self
end

function VoxelData:apply()
   self.mesh:setVertices(self.byteData)
end

function VoxelData:draw()
   love.graphics.draw(self.mesh)
end

return setmetatable(VoxelData, {
   __call = function(_, ...) return VoxelData.new(...) end,
})