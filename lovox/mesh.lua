local PATH = (...):gsub('%.[^%.]+$', '')

local ffi = require "ffi"
local Transform = require(PATH..".transform")

local Mesh = {}

-- The vertex format for the model mesh
Mesh.modelFormat = {
   {"VertexPosition", "float", 3},
   {"VertexTexCoord", "float", 2},
}

-- The vertex format for the model attributes mesh
Mesh.attributesFormat = {
   {"MatRow1", "float", 4},
   {"MatRow2", "float", 4},
   {"MatRow3", "float", 4},
   {"MatRow4", "float", 4},

   {"VertexColor", "byte",  4},
   {"Frame",       "float", 1},
}

--- Creates a new mesh containing the model attributes for a model.
-- @param voxelCount The number of voxels that will fit in the batch.
-- @param usage The SpriteBatchUsage used to update this mesh.
-- @returns modelAttributes A mesh containing the model attributes to be attached (applied) to the model.
-- @returns instanceData A ByteData object holding the memory space where all the data is stored.
-- @returns vertexBuffer An Array of Transforms where each element corresponds to one instance on the batch.
function Mesh.newModelAttributes(voxelCount, usage)
   local memoryUsage = voxelCount * Transform.instanceSize

   local instanceData    = love.data.newByteData(memoryUsage)
   local vertexBuffer    = Transform.castInstances(instanceData:getPointer())

   ffi.gc(vertexBuffer, function () instanceData:release() end)

   -- The attribute mesh has only the per-instance attributes of the models
   local modelAttributes = love.graphics.newMesh(Mesh.attributesFormat, instanceData, "points", usage)

   return modelAttributes, instanceData, vertexBuffer
end

--- Constructs all the vertices for the layers in a model.
-- @param width The width of each layer in pixels.
-- @param height The height of each layer in pixels.
-- @param layers The number of layers in the model.
-- @returns vertices The table containing all the vertices for the model.
function Mesh.newVertices(width, height, layers)
   local uvStep = 1 / layers

   local vertices = {}
   local start_u, end_u = 0, 1

   -- First layer is bottom and the last is top
   for layer = 0, layers - 1 do
      local start_v, end_v =  1 - (layer + 1) * uvStep, 1 - layer * uvStep
      local o = (layer * 4)

      vertices[o+1] = {-width/2, -height/2, layer, start_u, start_v} -- top-left
      vertices[o+2] = { width/2, -height/2, layer, end_u,   start_v} -- top-right
      vertices[o+3] = {-width/2,  height/2, layer, start_u, end_v  } -- bottom-left
      vertices[o+4] = { width/2,  height/2, layer, end_u,   end_v  } -- bottom-right
   end

   return vertices
end

--- Creates a new vertex map for all the quads (layers) that compose the models.
-- @param quads The number of quads (layers) on the model.
-- @returns vertexMap A vertex map to form the requested quads.
function Mesh.newVertexMap(quads)
   local vertexMap = {}

   for i = 0, quads - 1 do
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

--- Applies the model attributes to the model mesh.
-- @param model The Mesh to apply the attributes to.
-- @param attributes The Mesh containing the attributes for each instance of the model.
-- @returns model The Mesh provided as model, now with the attributes applied.
function Mesh.applyAttributes(model, attributes)
   for _, v in ipairs(Mesh.attributesFormat) do
      model:attachAttribute(v[1], attributes, "perinstance")
   end

   return model
end

--- Creates a new mesh with the provided number of vertices, texture, and model attributes.
-- @param vertices The number of vertices for the model (based on the number of layers).
-- @param texture The texture to use for this model.
-- @param layers The number of layers the model has.
-- @param modelAttributes A mesh which will hold the model attributes for this model.
-- @returns mesh The new mesh constructed from the parameters.
function Mesh.newMesh(vertices, texture, layers, modelAttributes)
   local mesh = love.graphics.newMesh(Mesh.modelFormat, vertices, "triangles", "static")
   mesh:setVertexMap(Mesh.newVertexMap(layers))
   mesh:setTexture(texture)

   Mesh.applyAttributes(mesh, modelAttributes)

   return mesh
end

return Mesh