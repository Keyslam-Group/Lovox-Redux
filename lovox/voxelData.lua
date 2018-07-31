local PATH = (...):gsub('%.[^%.]+$', '')

local Ffi  = require("ffi")
local Mat4 = require(PATH..".mat4")

-- Localize 'cos' and 'sin' for a bit more performance in VoxelData:updateVoxel
local cos = math.cos
local sin = math.sin

-- Define the module, as well as the vertex format
local VoxelData = {
   vertexFormat = {
      {"VertexPosition", "float", 3},
      {"VertexTexCoord", "float", 2},
   },

   instanceFormat = {
      {"MatRow1", "float", 4},
      {"MatRow2", "float", 4},
      {"MatRow3", "float", 4},
      {"MatRow4", "float", 4},

      {"VertexColor", "byte", 4}
   }
}
VoxelData.__index = VoxelData

local function newModelAttributes(voxelCount)
   local memoryUsage = voxelCount * Mat4.instanceSize

   local instanceData    = love.data.newByteData(memoryUsage)
   local vertexBuffer    = Mat4.castInstances(instanceData:getPointer())
   local modelAttributes = love.graphics.newMesh(VoxelData.instanceFormat, instanceData, usage)

   for i = 0, voxelCount - 1 do
      local inst = vertexBuffer[i]

      inst:setRotation(0.5)

      inst.r, inst.g, inst.b, inst.a = 255, 255, 255, 255
   end

   modelAttributes:setVertices(instanceData)

   return modelAttributes, instanceData, vertexBuffer
end

--- Creates a new mesh for voxels.
-- @param width, height, layer The dimensions of the source texture.
-- @param voxelCount The amount of voxels the mesh can hold.
-- @param usage How the mesh is supposed to be used (stream, dynamic, static).
-- @returns A new VoxelData object.
function VoxelData.new(texture, width, height, layers, voxelCount, usage)
   local uvStep = 1 / layers
   
   local vertices = {}
   for layer = 0, layers - 1 do
      local start_u, end_u = layer * uvStep, layer * uvStep + uvStep
      local o = (layer * 4)

      local z = layer

      vertices[o+1] = {-width/2, -height/2, layer, start_u, 0}
      vertices[o+2] = { width/2, -height/2, layer, end_u,   0}
      vertices[o+3] = {-width/2,  height/2, layer, start_u, 1}
      vertices[o+4] = { width/2,  height/2, layer, end_u,   1}
   end

   local modelAttributes, instanceData, vertexBuffer = newModelAttributes(voxelCount) 


   local voxelData = setmetatable({
      layers         = layers,
      voxelCount     = voxelCount,
      vertexCountPer = layers * 4,

      modelAttributes = modelAttributes,
      instanceData = instanceData,
      vertexBuffer = vertexBuffer,

      mesh = love.graphics.newMesh(VoxelData.vertexFormat, vertices, "triangles", usage),
      
      isDirty = false,
   }, VoxelData)

   local vertexMap = {}
   for i = 0, layers - 1 do
      local v, o = i * 6, i * 4
      
      vertexMap[v+1] = o + 1
      vertexMap[v+2] = o + 2
      vertexMap[v+3] = o + 3
      vertexMap[v+4] = o + 4
      vertexMap[v+5] = o + 3
      vertexMap[v+6] = o + 2
   end
   voxelData.mesh:setVertexMap(vertexMap)
   voxelData.mesh:setTexture(texture)

   voxelData.mesh:attachAttribute("MatRow1", modelAttributes, "perinstance")
   voxelData.mesh:attachAttribute("MatRow2", modelAttributes, "perinstance")
   voxelData.mesh:attachAttribute("MatRow3", modelAttributes, "perinstance")
   voxelData.mesh:attachAttribute("MatRow4", modelAttributes, "perinstance")

   --voxelData.mesh:attachAttribute("VertexColor", modelAttributes)

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
      --self:apply()
   end

   love.graphics.drawInstanced(self.mesh, self.voxelCount, 100, 100)

   return self
end

return setmetatable(VoxelData, {
   __call = function(_, ...) return VoxelData.new(...) end,
})