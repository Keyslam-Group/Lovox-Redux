local PATH = (...):gsub('%.[^%.]+$', '')

local ffi       = require("ffi")
local Mesh      = require(PATH..".mesh")

-- Define the module
local VoxelBatch = {}
VoxelBatch.__index = VoxelBatch

local ERR_FRAMETYPE = "Frame needs to be a number, was a %s"
local ERR_FRAME     = "The ArrayImage frames range from 0 to %d, frame out of bounds: %d"
local ERR_TEXTURE   = "The texture used by this VoxelBatch is not an ArrayImage"

local function checkReleased (self)
   if not self.mesh or not self.modelAttributes then
      error("This VoxelBatch has already been released and can't be used anymore", 3)
   end
end

local function checkIndex (self, index)
   local a = tonumber(index)
   if type(a) ~= "number" then
      error("Index needs to be a number, was a "..type(index), 3)
   end

   a = math.floor(a)
   if a > self.currentIndex then
      error("The provided index hasn't been added to the batch yet", 2)
   end

   return a
end

--- Creates a new mesh batch for voxels.
-- @param width, height, layer The dimensions of the source texture.
-- @param voxelCount The amount of voxels the mesh can hold.
-- @param usage How the mesh is supposed to be used (stream, dynamic, static).
-- @returns A new VoxelBatch object.
function VoxelBatch.new(texture, layers, voxelCount, usage)
   local vertices = Mesh.newVertices(texture:getWidth(), texture:getHeight() / layers, layers)
   local modelAttributes, instanceData, vertexBuffer = Mesh.newModelAttributes(voxelCount, usage)

   -- The model mesh, is a static mesh which has the different layers and the associated texture
   local mesh = Mesh.newMesh(vertices, texture, layers, modelAttributes)

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
   checkReleased(self)
   checkIndex(self, index)

   local instance = self.vertexBuffer[index - 1]

   instance:setTransformation(...)

   self.isDirty = true
   return self
end

--- Set the color of an instance in the VoxelBatch.
-- @param index The index of the instance
-- @param r, g, b The color components to use. Defaults to love.graphics.getColor()
-- @returns self
function VoxelBatch:setColor(index, r, g, b, a) -- luacheck: ignore
   checkReleased(self)
   checkIndex(self, index)

   local instance = self.vertexBuffer[index - 1]

   local cr, cg, cb, ca = love.graphics.getColor() -- luacheck: ignore
   instance.r = (r or cr) * 255
   instance.g = (g or cg) * 255
   instance.b = (b or cb) * 255
   instance.a = 255 -- (a or ca) * 255

   self.isDirty = true
   return self
end

--- Set the frame of an instance in the VoxelBatch.
-- NOTE: The texture of this VoxelBatch needs to be an ArrayImage for this method to work.
-- @param index The index of the instance
-- @param frame The frame of the ArrayImage to use (0-based)
-- @returns self
function VoxelBatch:setFrame(index, frame)
   checkReleased(self)
   checkIndex(self, index)

   if self.texture:getTextureType() == "array" then
      local f = tonumber(frame)
      if type(f) ~= "number" then
         error(ERR_FRAMETYPE:format(type(frame)), 2)
      end

      f = math.floor(f)
      if f >= 0 and f < self.texture:getLayerCount() then
         local instance = self.vertexBuffer[index - 1]

         instance.frame = math.floor(f)

         self.isDirty = true
      else
         error(ERR_FRAME:format(self.texture:getLayerCount() - 1, f), 2)
      end
   else
      error(ERR_TEXTURE, 2)
   end

   return self
end

--- Adds an instance to the VoxelBatch
-- This will use love.graphics.getColor for the model's color
-- @param
-- @return index The index of the added instance
function VoxelBatch:add(...)
   checkReleased(self)

   -- If buffer size (voxelCount) is exceeded, return 0
   if self.currentIndex == self.voxelCount then
      return 0
   end

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
   checkReleased(self)
   ffi.fill(self.instanceData:getPointer(), self.instanceData:getSize())

   self.currentIndex = 0
   self.isDirty      = true

   return self
end

--- Gets the number of instances currently active in this VoxelBatch
-- @returns count Active instances
function VoxelBatch:getCount()
   checkReleased(self)
   return self.currentIndex
end

--- Get the number of instances this VoxelBatch can hold
-- @returns size Maximum number of instances
function VoxelBatch:getBufferSize()
   checkReleased(self)
   return self.voxelCount
end

--- Attach an attribute to the VoxelBatch mesh
-- @returns self
function VoxelBatch:attachAttribute(...)
   checkReleased(self)
   self.mesh:attachAttribute(...)
end

--- Get the Texture associated with this VoxelBatch
-- @returns texture The texture bind to the VoxelBatch's mesh
function VoxelBatch:getTexture()
   checkReleased(self)
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
   checkReleased(self)

   if self.isDirty then
      self:flush()
   end

   love.graphics.drawInstanced(self.mesh, self.currentIndex)

   return self
end

function VoxelBatch:release()
   if not self.mesh then
      return false -- Already released
   end

   -- Reset all values to their default
   self.voxelCount = 0
   self.currentIndex = 0
   self.isDirty = false

   -- Let us handle the collection of vertexBuffer
   ffi.gc(self.vertexBuffer, nil)
   self.vertexBuffer = nil

   -- Release the instanceData ByteData for the VoxelBatch
   self.instanceData:release()
   self.instanceData = nil

   -- Release the modelAttributes Mesh for the VoxelBatch
   self.modelAttributes:release()
   self.modelAttributes = nil

   -- Release the model Mesh for the VoxelBatch
   self.mesh:release()
   self.mesh = nil

   -- Release the reference to the texture used by the VoxelBatch
   self.texture = nil

   return true
end

return setmetatable(VoxelBatch, {
   __call = function (_, ...) return VoxelBatch.new(...) end
})
