local Ffi = require("ffi")

local sqrt, atan2 = math.sqrt, math.atan2
local cos,  sin   = math.cos,  math.sin

Ffi.cdef[[
   typedef struct {
      float x, y, z;
      float u, v, m;
      unsigned char r, g, b, a;
   } fm_vertex;
]]

local VoxelData = {
   vertexSize   = Ffi.sizeof("fm_vertex"),
   vertexFormat = {
      {"VertexPosition", "float", 3},
      {"VertexTexCoord", "float", 3},
      {"VertexColor",    "byte",  4},
   }
}
VoxelData.__index = VoxelData

function VoxelData.new(texture, width, height, layers, voxelCount, usage)
   local voxelData = setmetatable({
      hWidth      = width  / 2,
      hHeight     = height / 2,
      uvStep      = 1 / layers, -- UV Steps should be changed to quads

      texture    = texture,
      layers     = layers,
      voxelCount = voxelCount,
      usage      = usage or "dynamic",
      
      vertexCountPer = layers * 4,
      vertexCount    = voxelCount * layers * 4,
      
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

   local vertexMap = {}
   for i = 0, voxelData.voxelCount * voxelData.layers - 1 do
      local v, o = i * 6, i * 4
      
      vertexMap[v+1] = o + 1
      vertexMap[v+2] = o + 2
      vertexMap[v+3] = o + 4
      vertexMap[v+4] = o + 3
      vertexMap[v+5] = o + 4
      vertexMap[v+6] = o + 2
   end
   voxelData.mesh:setVertexMap(vertexMap)

   return voxelData
end

function VoxelData:writeVertex(offset, x, y, z, u, v, m, r, g, b)
   local vertex = self.vertices[offset]
   vertex.x, vertex.y, vertex.z = x, y, z
   vertex.u, vertex.v, vertex.m = u, v, m
   vertex.r, vertex.g, vertex.b = r or 255, g or 255, b or 255
   vertex.a = 255

   return self
end

function VoxelData:updateVoxel(id, x, y, z, rotation, sx, sy, r, g, b)
   local offset = (id - 1) * self.vertexCountPer

   local hWidth, hHeight = self.hWidth * sx, self.hHeight * sy

   local rectDiag    = sqrt(hWidth * hWidth + hHeight * hHeight)
   local rectAngle   = atan2(hHeight, hWidth)

   local rot, iRot = rectAngle + rotation, -rectAngle + rotation

   local cRot, sRot   = rectDiag * cos(rot),  rectDiag * sin(rot)
   local icRot, isRot = rectDiag * cos(iRot), rectDiag * sin(iRot)

   local tl_x, tl_y = (x -  cRot), (y -  sRot)
   local tr_x, tr_y = (x + icRot), (y + isRot)
   local bl_x, bl_y = (x - icRot), (y - isRot)
   local br_x, br_y = (x +  cRot), (y +  sRot)

   for layer = 0, self.layers - 1 do
      local start_u, end_u = layer * self.uvStep, layer * self.uvStep + self.uvStep
      local o = offset + (layer * 4)

      local z = (z + layer) * sy

      self:writeVertex(o + 0, tl_x, tl_y, z, start_u, 0, 0, r, g, b)
      self:writeVertex(o + 1, tr_x, tr_y, z, end_u,   0, 0, r, g, b)
      self:writeVertex(o + 2, br_x, br_y, z, end_u,   1, 0, r, g, b)
      self:writeVertex(o + 3, bl_x, bl_y, z, start_u, 1, 0, r, g, b)
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