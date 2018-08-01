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
      --inst:setIdentity()

      inst.r, inst.g, inst.b, inst.a = 255, 255, 255, 255
   end

   modelAttributes:setVertices(instanceData)

   return modelAttributes, instanceData, vertexBuffer
end

local function newVertices(width, height, layers)
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

   return vertices
end

local function newVertexMap(layers)
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

   return vertexMap
end

--- Creates a new mesh for voxels.
-- @param width, height, layer The dimensions of the source texture.
-- @param voxelCount The amount of voxels the mesh can hold.
-- @param usage How the mesh is supposed to be used (stream, dynamic, static).
-- @returns A new VoxelData object.
function VoxelData.new(texture, layers, voxelCount, usage)
   local vertices = newVertices(texture:getWidth() / layers, texture:getHeight(), layers)
   local modelAttributes, instanceData, vertexBuffer = newModelAttributes(voxelCount) 

   local mesh = love.graphics.newMesh(VoxelData.vertexFormat, vertices, "triangles", usage)
   mesh:setVertexMap(newVertexMap(layers))
   mesh:setTexture(texture)

   mesh:attachAttribute("MatRow1", modelAttributes, "perinstance")
   mesh:attachAttribute("MatRow2", modelAttributes, "perinstance")
   mesh:attachAttribute("MatRow3", modelAttributes, "perinstance")
   mesh:attachAttribute("MatRow4", modelAttributes, "perinstance")

   mesh:attachAttribute("VertexColor", modelAttributes, "perinstance")

   return setmetatable({
      voxelCount = voxelCount,

      mesh            = mesh,
      modelAttributes = modelAttributes,
      instanceData    = instanceData,
      vertexBuffer    = vertexBuffer,
      
      nextFreeIndex = 1,
      isDirty       = false,
   }, VoxelData)
end

--- Applies updated voxels to the mesh.
-- @returns self
function VoxelData:flush()
   self.modelAttributes:setVertices(self.instanceData)

   self.isDirty = false
   return self
end

function VoxelData:set(index, ...)
   -- TODO Check if index is < nextFreeIndex
   local instance = self.vertexBuffer[index - 1]
   
   instance:setTransformation(...)

   local r, g, b = love.graphics.getColor()
   instance.r = r * 255
   instance.g = g * 255
   instance.b = b * 255
   instance.a = 255

   self.isDirty = true
   return self
end

function VoxelData:add(...)
   -- TODO Check if the index is < voxelCount
   local index = self.nextFreeIndex

   self:set(index, ...)
   self.nextFreeIndex = index + 1

   return index
end

function VoxelData:clear()
   for i = 0, self.nextFreeIndex - 2 do
      local instance = self.vertexBuffer[i]
      instance:clear()
   end

   self.nextFreeIndex = 1

   self.isDirty = true
   return self
end

function Voxel:getCount()
   return self.nextFreeIndex - 1
end

function VoxelData:getBufferSize()
   return self.voxelCount
end

function VoxelData:attachAttribute(...)
  self.mesh:attachAttribute(...)
end

function VoxelData:getTexture()
   return self.mesh:getTexture()
end

-- function VoxelData:setTexture(texture)
--    -- Should this reevaluate the mesh?
--    -- Mesh size is static so you would need to keep the number of layers
--    self.mesh:setTexture(texture)
-- end

--- Draws a voxel.
-- @returns self
function VoxelData:draw()
   if self.isDirty then
      self:flush()
   end

   love.graphics.drawInstanced(self.mesh, self.voxelCount)

   return self
end

return setmetatable(VoxelData, {
   __call = function(_, ...) return VoxelData.new(...) end,
})