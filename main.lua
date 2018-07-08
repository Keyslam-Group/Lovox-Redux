love.graphics.setDefaultFilter("nearest", "nearest")

local _WIDTH, _HEIGHT = love.graphics.getDimensions()

local FFI = require("ffi")

local Shader = love.graphics.newShader("shader.glsl")
local Image  = love.graphics.newImage("boat/texture.png")

local sqrt, atan2 = math.sqrt, math.atan2
local cos,  sin   = math.cos,  math.sin


local voxelCount  = 800
local vertexCount = voxelCount * 6 * 16

FFI.cdef[[
   typedef struct {
      float x, y, z;
      float u, v;
   } fm_vertex;
]]

local vertexSize  = FFI.sizeof("fm_vertex")
local memoryUsage = vertexCount * vertexSize

local byteData  = love.data.newByteData(memoryUsage)
local voxelData = FFI.cast("fm_vertex*", byteData:getPointer())

local Voxel_mesh = love.graphics.newMesh({
   {"VertexPosition", "float", 3},
   {"VertexTexCoord", "float", 2},
}, byteData, "triangles", "dynamic")
Voxel_mesh:setTexture(Image)

local width, height = 64, 32
local halfWidth, halfHeight = width/2, height/2
local step = 1 / 16

local rectDiag  = sqrt (halfWidth * halfWidth + halfHeight * halfHeight)
local rectAngle = atan2(halfHeight, halfWidth)

local function writeVertex(id, x, y, z, u, v)
   local vt = voxelData[id]
   vt.x, vt.y, vt.z = x, y, z / 32
   vt.u, vt.v       = u, v
end

function updateVoxel(id, x, y, z, rotation)
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

      writeVertex(o + 0, tl_x, tl_y, z + layer, start_u, 0)
      writeVertex(o + 1, tr_x, tr_y, z + layer, end_u,   0)
      writeVertex(o + 2, bl_x, bl_y, z + layer, start_u, 1)

      writeVertex(o + 3, br_x, br_y, z + layer, end_u,   1)
      writeVertex(o + 4, bl_x, bl_y, z + layer, start_u, 1)
      writeVertex(o + 5, tr_x, tr_y, z + layer, end_u,   0)
   end
end

local color = love.graphics.newCanvas(w, h, {format = "rgba8"})
local depth = love.graphics.newCanvas(w, h, {format = "depth24"})

local canvas = {color, depthstencil = depth}
love.graphics.setDepthMode("lequal", true)

local voxels = {}

local player = {
   id = #voxels,
   x = 20,
   y = 20,
   z = 0,
   r = 0,

   velocity = 0,
   speed    = 50,

   rotVelocity = 0,
   rotSpeed    = 2,
}

function love.load()
   for x = 0, 1280, 128 do
      for y = 0, 720, 60 do
         local voxel = {
            x = x, y = y, z = 0,
            r = 0.2
         }
      
         updateVoxel(#voxels, voxel.x, voxel.y, voxel.z, voxel.r)
         Voxel_mesh:setVertices(byteData)
      
         table.insert(voxels, voxel)
      end
   end

   Voxel_mesh:setVertices(byteData)
end

local r = 0
function love.update(dt)
   love.window.setTitle(love.timer.getFPS())

   for i, voxel in ipairs(voxels) do
      voxel.r = voxel.r + dt
      --updateVoxel(i - 1, voxel.x, voxel.y, voxel.z, voxel.r)
   end

   if love.keyboard.isDown("w") then player.velocity = player.velocity + player.speed * dt end
   if love.keyboard.isDown("s") then player.velocity = player.velocity - player.speed * dt end

   if love.keyboard.isDown("q") then player.rotVelocity = player.rotVelocity - player.rotSpeed * dt end
   if love.keyboard.isDown("e") then player.rotVelocity = player.rotVelocity + player.rotSpeed * dt end

   if love.keyboard.isDown("r") then player.z = player.z + dt * 10 end
   if love.keyboard.isDown("f") then player.z = player.z - dt * 10 end

   player.r = player.r + player.rotVelocity * dt

   player.x = player.x + player.velocity * cos(player.r) * dt
   player.y = player.y + player.velocity * sin(player.r) * dt

   player.rotVelocity = player.rotVelocity - (player.rotVelocity * 0.8 * dt)

   updateVoxel(player.id, player.x, player.y, player.z, player.r)

   Voxel_mesh:setVertices(byteData)

   r = r + dt / 4
end

function love.draw()
   
   love.graphics.setCanvas(canvas)
      love.graphics.clear(0, 0, 0, 1, true, 1)

      love.graphics.push()
      love.graphics.translate(_WIDTH/2, _HEIGHT/2)
      love.graphics.rotate(r)

      
      love.graphics.setShader(Shader)
         love.graphics.draw(Voxel_mesh)
      love.graphics.setShader()

      love.graphics.pop()
   love.graphics.setCanvas()

   love.graphics.draw(canvas[1])
end

local c = 0
function love.mousepressed(x, y, btn)
   local voxel = {
      x = x, y = y, z = 0,
      r = love.math.random() * math.pi * 2,
   }

   updateVoxel(#voxels, voxel.x, voxel.y, voxel.z, voxel.r)
   Voxel_mesh:setVertices(byteData)

   table.insert(voxels, voxel)
end