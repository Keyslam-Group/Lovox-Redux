love.graphics.setDefaultFilter("nearest", "nearest")

local _WIDTH, _HEIGHT = love.graphics.getDimensions()

local FFI = require("ffi")

local Shader = love.graphics.newShader("shader.glsl")
local Image  = love.graphics.newImage("boat/texture.png")

local sqrt, atan2 = math.sqrt, math.atan2
local cos,  sin   = math.cos,  math.sin


local voxelCount  = 399
local vertexCount = voxelCount * 6 * 16

FFI.cdef[[
   typedef struct {
      float x, y;
      float u, v;
   } fm_vertex;
]]

local vertexSize  = FFI.sizeof("fm_vertex")
local memoryUsage = vertexCount * vertexSize

local byteData  = love.data.newByteData(memoryUsage)
local voxelData = FFI.cast("fm_vertex*", byteData:getPointer())

local Voxel_mesh = love.graphics.newMesh({
   {"VertexPosition", "float", 2},
   {"VertexTexCoord", "float", 2},
}, byteData, "triangles", "dynamic")
Voxel_mesh:setTexture(Image)

local width, height = 64, 32
local halfWidth, halfHeight = width/2, height/2
local step = 1 / 16

local rectDiag  = sqrt (halfWidth * halfWidth + halfHeight * halfHeight)
local rectAngle = atan2(halfHeight, halfWidth)

local function writeVertex(id, x, y, u, v)
   local vt = voxelData[id]
   vt.x, vt.y, vt.u, vt.v = x, y, u, v
end

function updateVoxel(id, x, y, rotation)
   local offset = id * 96

   local rot, iRot = rectAngle + rotation, -rectAngle + rotation

   local cRot, sRot   = rectDiag * cos(rot),  rectDiag * sin(rot)
   local icRot, isRot = rectDiag * cos(iRot), rectDiag * sin(iRot)

   local tl_x, tl_y = x -  cRot, y -  sRot
   local tr_x, tr_y = x + icRot, y + isRot
   local bl_x, bl_y = x - icRot, y - isRot
   local br_x, br_y = x +  cRot, y +  sRot

   for layer = 0, 15 do
      local start_u, end_u = layer * step, layer * step + step
      local o = offset + (layer * 6)

      writeVertex(o + 0, tl_x, tl_y - layer, start_u, 0)
      writeVertex(o + 1, tr_x, tr_y - layer, end_u,   0)
      writeVertex(o + 2, bl_x, bl_y - layer, start_u, 1)

      writeVertex(o + 3, br_x, br_y - layer, end_u,   1)
      writeVertex(o + 4, bl_x, bl_y - layer, start_u, 1)
      writeVertex(o + 5, tr_x, tr_y - layer, end_u,   0)
   end
end

local voxels = {}
function love.load()
   for x = 0, 1280, 64 do
      for y = 0, 720, 40 do
         local voxel = {
            x = x, y = y,
            r = love.math.random() * math.pi * 2
         }
      
         updateVoxel(#voxels, voxel.x, voxel.y, voxel.r)
         Voxel_mesh:setVertices(byteData)
      
         table.insert(voxels, voxel)
      end
   end

   Voxel_mesh:setVertices(byteData)
end

function love.update(dt)
   love.window.setTitle(love.timer.getFPS())

   for i, voxel in ipairs(voxels) do
      voxel.r = voxel.r + dt
      updateVoxel(i - 1, voxel.x, voxel.y, voxel.r)
   end

   Voxel_mesh:setVertices(byteData)
end

function love.draw()
   love.graphics.scale(1)
   --love.graphics.setShader(Shader)
      love.graphics.draw(Voxel_mesh)
   --love.graphics.setShader()
end

local c = 0
function love.mousepressed(x, y, btn)
   local voxel = {
      x = x, y = y,
      r = love.math.random() * math.pi * 2
   }

   updateVoxel(#voxels, voxel.x, voxel.y, voxel.r)
   Voxel_mesh:setVertices(byteData)

   table.insert(voxels, voxel)
end