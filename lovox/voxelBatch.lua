local PATH = (...):gsub('%.[^%.]+$', '')

local Ffi       = require("ffi")
local Transform = require(PATH..".transform")

-- Define the module, as well as the vertex format
local VoxelBatch = {}
VoxelBatch.__index = VoxelBatch

local vertexFormat = {
   {"VertexPosition", "float", 3},
   {"VertexTexCoord", "float", 2},
}

local instanceFormat = {
   {"MatRow1", "float", 4},
   {"MatRow2", "float", 4},
   {"MatRow3", "float", 4},
   {"MatRow4", "float", 4},

   {"VertexColor",    "byte",  4},
   {"AnimationFrame", "float", 1},
}

local function newModelAttributes(voxelCount, usage)
   local memoryUsage = voxelCount * Transform.instanceSize

   local instanceData    = love.data.newByteData(memoryUsage) --luacheck: ignore
   local vertexBuffer    = Transform.castInstances(instanceData:getPointer())

   --The attribute mesh has only the per-instance attributes of the models
   local modelAttributes = love.graphics.newMesh(instanceFormat, instanceData, "points", usage)

   return modelAttributes, instanceData, vertexBuffer
end

local function newVertices(width, height, layers)
   local uvStep = 1 / layers

   local vertices = {}
   local start_v, end_v = 0, 1

   --First layer is bottom and the last is top
   for layer = 0, layers - 1 do
      local start_u, end_u = layer * uvStep, (layer + 1) * uvStep
      local o = (layer * 4)

      vertices[o+1] = {-width/2, -height/2, layer, start_u, start_v} -- top-left
      vertices[o+2] = { width/2, -height/2, layer, end_u,   start_v} -- top-right
      vertices[o+3] = {-width/2,  height/2, layer, start_u, end_v  } -- bottom-left
      vertices[o+4] = { width/2,  height/2, layer, end_u,   end_v  } -- bottom-right
   end

   return vertices
end

local function newVertexMap(layers)
   local vertexMap = {}

   for i = 0, layers - 1 do
      local v, o = i * 6, i * 4

      -- 1 --- 2 For each layer there are two triangles
      -- |    /| Top-left is composed of vertices 1, 2 and 3
      -- |  /  | Bottom-right is composed of 4, 3, 2
      -- |/    | Both have clockwise winding
      -- 3 --- 4 And are pointing up in the Z axis

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

   --The model mesh, is a static mesh which has the different layers and the associated texture
   local mesh = love.graphics.newMesh(vertexFormat, vertices, "triangles", "static")
   mesh:setVertexMap(newVertexMap(layers))
   mesh:setTexture(texture)

   mesh:attachAttribute("MatRow1", modelAttributes, "perinstance")
   mesh:attachAttribute("MatRow2", modelAttributes, "perinstance")
   mesh:attachAttribute("MatRow3", modelAttributes, "perinstance")
   mesh:attachAttribute("MatRow4", modelAttributes, "perinstance")

   mesh:attachAttribute("VertexColor",    modelAttributes, "perinstance")
   mesh:attachAttribute("AnimationFrame", modelAttributes, "perinstance")

   return setmetatable({
      texture    = texture,
      voxelCount = voxelCount,

      mesh            = mesh,
      modelAttributes = modelAttributes,
      instanceData    = instanceData,
      vertexBuffer    = vertexBuffer,

      currentIndex = 0,
      isDirty      = false,
   }, VoxelBatch)
end

--- Applies updated voxels to the mesh.
-- @returns self
function VoxelBatch:flush()
   self.modelAttributes:setVertices(self.instanceData)
   self.isDirty = false

   return self
end

--- Set the transformation of an instance in the VoxelBatch
-- @param
-- @returns self
function VoxelBatch:setTransformation(index, ...)
   -- TODO: Check if index is < currentIndex
   local instance = self.vertexBuffer[index - 1]

   instance:setTransformation(...)

   self.isDirty = true
   return self
end

--- Set the color of an instance in the VoxelBatch.
-- @param index The index of the instance
-- @param r, g, b The color components to use. Defaults to love.graphics.getColor()
-- @returns self
function VoxelBatch:setColor(index, r, g, b, a) --luacheck: ignore
   -- TODO: Check if index is < currentIndex
   local instance = self.vertexBuffer[index - 1]

   local cr, cg, cb, ca = love.graphics.getColor() --luacheck: ignore
   instance.r = (r or cr) * 255
   instance.g = (g or cg) * 255
   instance.b = (b or cb) * 255
   instance.a = 255 --(a or ca) * 255

   self.isDirty = true
   return self
end

--- Set the animation frame of an instance in the VoxelBatch.
-- Note: The texture of this VoxelBatch needs to be an ArrayImage for this method to work.
-- @param index The index of the instance
-- @param frame The frame of animation to use (0-based)
-- @returns self
function VoxelBatch:setAnimationFrame(index, frame)
   -- TODO: Check if index is < currentIndex
   if self.texture:getTextureType() == "array" then
      -- TODO: Check that layers actually range from 0 to getLayers() - 1 inclusive
      if frame >= 0 and frame < self.texture:getLayers() then
         local instance = self.vertexBuffer[index - 1]

         instance.frame = math.floor(frame)

         self.isDirty = true
      -- else error
      end
   end

   return self
end

--- Adds an instance to the VoxelBatch
-- This will use love.graphics.getColor for the model's color
-- @param
-- @return index The index of the added instance
function VoxelBatch:add(...)
   -- TODO: Check if the index is < voxelCount
   local index = self.currentIndex + 1

   self.currentIndex = index
   self:setTransformation(index, ...)
   self:setColor(index)

   return index
end

--- Clears the VoxelBatch.
-- After this drawing the VoxelBatch will draw nothing, and getCount() will be 0
-- @returns self
function VoxelBatch:clear()
   Ffi.fill(self.instanceData:getPointer(), self.instanceData:getSize())

   self.currentIndex = 0
   self.isDirty      = true

   return self
end

--- Gets the number of instances currently active in this VoxelBatch
-- @returns count Active instances
function VoxelBatch:getCount()
   return self.currentIndex
end

--- Get the number of instances this VoxelBatch can hold
-- @returns size Maximum number of instances
function VoxelBatch:getBufferSize()
   return self.voxelCount
end

--- Attach an attribute to the VoxelBatch mesh
-- @returns self
function VoxelBatch:attachAttribute(...)
   self.mesh:attachAttribute(...)
end

--- Get the Texture associated with this VoxelBatch
-- @returns texture The texture bind to the VoxelBatch's mesh
function VoxelBatch:getTexture()
   return self.texture
end

-- function VoxelBatch:setTexture(texture)
--    self.texture = texture
--    self.mesh:setTexture(texture)
--
--    -- Should this reevaluate the mesh?
--    -- Mesh size is static so you would need to keep the number of layers
--    return self
-- end

--- Draws the VoxelBatch.
-- @returns self
function VoxelBatch:draw()
   if self.isDirty then
      self:flush()
   end

   love.graphics.drawInstanced(self.mesh, self.currentIndex) --luacheck: ignore

   return self
end

return setmetatable(VoxelBatch, {
   __call = function(_, ...) return VoxelBatch.new(...) end,
})
