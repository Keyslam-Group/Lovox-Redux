local PATH = (...):gsub('%.[^%.]+$', '')

local Ffi       = require("ffi")
local Transform = require(PATH..".transform")

-- Define the module, as well as the vertex format
local VoxelBatch = {
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
VoxelBatch.__index = VoxelBatch

local function newModelAttributes(voxelCount, usage)
   local memoryUsage = voxelCount * Transform.instanceSize

   local instanceData    = love.data.newByteData(memoryUsage) --luacheck: ignore
   local vertexBuffer    = Transform.castInstances(instanceData:getPointer())
   local modelAttributes = love.graphics.newMesh(VoxelBatch.instanceFormat, instanceData, usage)

   modelAttributes:setVertices(instanceData)

   return modelAttributes, instanceData, vertexBuffer
end

local function newVertices(width, height, layers)
   local uvStep = 1 / layers

   local vertices = {}

   for layer = 0, layers - 1 do
      local start_u, end_u = layer * uvStep, layer * uvStep + uvStep
      local o = (layer * 4)

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
-- @returns A new VoxelBatch object.
function VoxelBatch.new(texture, layers, voxelCount, usage)
   local vertices = newVertices(texture:getWidth() / layers, texture:getHeight(), layers)
   local modelAttributes, instanceData, vertexBuffer = newModelAttributes(voxelCount, usage)

   local mesh = love.graphics.newMesh(VoxelBatch.vertexFormat, vertices, "triangles", "static")
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
   }, VoxelBatch)
end

--- Applies updated voxels to the mesh.
-- @returns self
function VoxelBatch:flush()
   self.modelAttributes:setVertices(self.instanceData)
   self.isDirty = false

   return self
end

function VoxelBatch:set(index, ...)
   -- TODO Check if index is < nextFreeIndex
   local instance = self.vertexBuffer[index - 1]

   instance:setTransformation(...)

   local r, g, b = love.graphics.getColor()
   instance.r = r * 255
   instance.g = g * 255
   instance.b = b * 255
   instance.a =     255

   self.isDirty = true
   return self
end

function VoxelBatch:add(...)
   -- TODO Check if the index is < voxelCount
   local index = self.nextFreeIndex

   self.nextFreeIndex = index + 1
   self:set(index, ...)

   return index
end

function VoxelBatch:clear()
   Ffi.fill(self.instanceData:getPointer(), self.instanceData:getSize())

   self.nextFreeIndex = 1
   self.isDirty       = true

   return self
end

function VoxelBatch:getCount()
   return self.nextFreeIndex - 1
end

function VoxelBatch:getBufferSize()
   return self.voxelCount
end

function VoxelBatch:attachAttribute(...)
   self.mesh:attachAttribute(...)
end

function VoxelBatch:getTexture()
   return self.mesh:getTexture()
end

-- function VoxelBatch:setTexture(texture)
--    -- Should this reevaluate the mesh?
--    -- Mesh size is static so you would need to keep the number of layers
--    self.mesh:setTexture(texture)
-- end

--- Draws a voxel.
-- @returns self
function VoxelBatch:draw()
   if self.isDirty then
      self:flush()
   end

   love.graphics.drawInstanced(self.mesh, self.voxelCount) --luacheck: ignore

   return self
end

return setmetatable(VoxelBatch, {
   __call = function(_, ...) return VoxelBatch.new(...) end,
})