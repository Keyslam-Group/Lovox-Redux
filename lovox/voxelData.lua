local Ffi = require("ffi")

-- Localize 'cos' and 'sin' for a bit more performance in VoxelData:updateVoxel
local cos = math.cos
local sin = math.sin

-- Define a struct for our custom vertex format
Ffi.cdef[[
   typedef struct {
      float x, y, z;
      float u, v, m;
      unsigned char r, g, b, a;
   } fm_vertex;
]]

-- Define the module, as well as the vertex format
local VoxelData = {
   vertexSize   = Ffi.sizeof("fm_vertex"),
   vertexFormat = {
      {"VertexPosition", "float", 3},
      {"VertexTexCoord", "float", 3},
      {"VertexColor",    "byte",  4},
   }
}
VoxelData.__index = VoxelData

--- Creates a mesh to be used by the VoxelData.
-- @param voxelCount The amount of voxels the mesh can hold
-- @param layers The amount of layers a voxel has
-- @param texture The texture to use
-- @returns mesh The creates mesh that can be rendered
-- @returns byteData Used to update the mesh
-- @returns vertices A table that holds the vertices
local function newVoxelMesh(voxelCount, layers, texture)
   -- Calculate some relevant numbers
   local vertexCount = voxelCount  * layers * 4
   local memoryUsage = vertexCount * VoxelData.vertexSize

   -- Create all our objects needed for efficient mesh manipulation
   local byteData = love.data.newByteData(memoryUsage)
   local vertices = Ffi.cast("fm_vertex*", byteData:getPointer())
   local mesh     = love.graphics.newMesh(VoxelData.vertexFormat, byteData, "triangles", usage)
   
   -- Set the texture
   mesh:setTexture(texture)

   -- Generate a vertex map to reuse vertices
   -- Vertices are stored in order: TL, TR, BR, BL
   -- Vertex map is in the order: TL, TR, BL, BR, BL, TR
   local vertexMap = {}
   for i = 0, voxelCount * layers - 1 do
      local v, o = i * 6, i * 4
      
      vertexMap[v+1] = o + 1
      vertexMap[v+2] = o + 2
      vertexMap[v+3] = o + 4
      vertexMap[v+4] = o + 3
      vertexMap[v+5] = o + 4
      vertexMap[v+6] = o + 2
   end
   mesh:setVertexMap(vertexMap)

   -- Return all our objects
   return mesh, byteData, vertices
end

--- Creates a new mesh for voxels.
-- @param width, height, layer The dimensions of the source texture.
-- @param voxelCount The amount of voxels the mesh can hold.
-- @param usage How the mesh is supposed to be used (stream, dynamic, static).
-- @returns A new VoxelData object.
function VoxelData.new(texture, width, height, layers, voxelCount, usage)
   local mesh, byteData, vertices = newVoxelMesh(voxelCount, layers, texture)
   
   local voxelData = setmetatable({
      rectDiag  = math.sqrt (width/2 * width/2 + height/2 * height/2),
      rectAngle = math.atan2(height/2, width/2),
      uvStep    = 1 / layers, -- UV Steps should be changed to quads

      layers         = layers,
      voxelCount     = voxelCount,
      vertexCountPer = layers * 4,

      mesh        = mesh,
      byteData    = byteData,
      vertices    = vertices,
      
      isDirty = false,
   }, VoxelData)

   return voxelData
end

--- Writes the data for a specific vertex.
-- @param offset The ID of the vertex.
-- @param x, y, z The position of the vertex.
-- @param u, v, m The UV values of the vertex.
-- @param r, g, b The colors of the vertex.
-- @returns self.
function VoxelData:writeVertex(offset, x, y, z, u, v, m, r, g, b)
   local vertex = self.vertices[offset]
   vertex.x, vertex.y, vertex.z = x, y, z
   vertex.u, vertex.v, vertex.m = u, v, m
   vertex.r, vertex.g, vertex.b = r or 255, g or 255, b or 255
   vertex.a = 255

   return self
end

--- Writes the data for a specific voxel.
-- @param offset The ID of the voxel.
-- @param x, y, z The position of the voxel.
-- @param rotation The rotation factor of the voxel.
-- @param scale The scale factor of the voxel.
-- @param r, g, b The colors of the vertex
-- @returns self.
function VoxelData:updateVoxel(id, x, y, z, rotation, scale, r, g, b)
   -- Localized for extra to save a few lookups
   local rectAngle, rectDiag = self.rectAngle, self.rectDiag * scale
   local uvStep, layers      = self.uvStep, self.layers

   local offset = (id - 1) * self.vertexCountPer

   -- Magic to calculate the 4 points of a rectangle
   local rot, iRot = rectAngle + rotation, -rectAngle + rotation

   local cRot, sRot   = rectDiag * cos(rot),  rectDiag * sin(rot)
   local icRot, isRot = rectDiag * cos(iRot), rectDiag * sin(iRot)

   local tl_x, tl_y = (x -  cRot), (y -  sRot)
   local tr_x, tr_y = (x + icRot), (y + isRot)
   local bl_x, bl_y = (x - icRot), (y - isRot)
   local br_x, br_y = (x +  cRot), (y +  sRot)

   -- Iterate over all the layers, and set the vertices accordingly
   for layer = 0, layers - 1 do
      local start_u, end_u = layer * uvStep, layer * uvStep + uvStep
      local o = offset + ((layers - layer - 1) * 4)

      local z = layer * scale + z

      self:writeVertex(o + 0, tl_x, tl_y, z, start_u, 0, 0, r, g, b)
      self:writeVertex(o + 1, tr_x, tr_y, z, end_u,   0, 0, r, g, b)
      self:writeVertex(o + 2, br_x, br_y, z, end_u,   1, 0, r, g, b)
      self:writeVertex(o + 3, bl_x, bl_y, z, start_u, 1, 0, r, g, b)
   end

   self.isDirty = true

   return self
end

--- Applies updated voxels to the mesh.
-- @returns self
function VoxelData:apply()
   self.mesh:setVertices(self.byteData)
   self.isDirty = false

   return self
end

--- Draws a voxel.
-- @returns self
function VoxelData:draw()
   if self.isDirty then
      self:apply()
   end

   love.graphics.draw(self.mesh)

   return self
end

return setmetatable(VoxelData, {
   __call = function(_, ...) return VoxelData.new(...) end,
})