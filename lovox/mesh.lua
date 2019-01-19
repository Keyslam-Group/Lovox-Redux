local PATH = (...):gsub('%.[^%.]+$', '')

local Ffi = require "ffi"
local Transform = require(PATH..".transform")

local Mesh = {}

Mesh.vertexFormat = {
   {"VertexPosition", "float", 3},
   {"VertexTexCoord", "float", 2},
}

Mesh.instanceFormat = {
   {"MatRow1", "float", 4},
   {"MatRow2", "float", 4},
   {"MatRow3", "float", 4},
   {"MatRow4", "float", 4},

   {"VertexColor", "byte",  4},
   {"Frame",       "float", 1},
}

function Mesh.newModelAttributes(voxelCount, usage)
   local memoryUsage = voxelCount * Transform.instanceSize

   local instanceData    = love.data.newByteData(memoryUsage) --luacheck: ignore
   local vertexBuffer    = Transform.castInstances(instanceData:getPointer())

   Ffi.gc(vertexBuffer, function () instanceData:release() end)

   --The attribute mesh has only the per-instance attributes of the models
   local modelAttributes = love.graphics.newMesh(Mesh.instanceFormat, instanceData, "points", usage)

   return modelAttributes, instanceData, vertexBuffer
end

function Mesh.newVertices(width, height, layers)
   local uvStep = 1 / layers

   local vertices = {}
   local start_u, end_u = 0, 1

   --First layer is bottom and the last is top
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

function Mesh.applyAttributes(to, from)
   for _, v in ipairs(Mesh.instanceFormat) do
      to:attachAttribute(v[1], from, "perinstance")
   end

   return to
end

function Mesh.newMesh(vertices, texture, layers, modelAttributes)
   local mesh = love.graphics.newMesh(Mesh.vertexFormat, vertices, "triangles", "static")
   mesh:setVertexMap(Mesh.newVertexMap(layers))
   mesh:setTexture(texture)

   Mesh.applyAttributes(mesh, modelAttributes)

   return mesh
end

return Mesh