local Ffi = require("ffi")

local Transform   = {}
Transform.__index = Transform

-- NOTE: Once Ffi.metatype is called (at the end of this file) Transform can't be changed
-- NOTE: Transform objects are (internally) arrays of floats, representing matrices in COLUMN-MAJOR format.

-- Localize 'cos' and 'sin' for a bit more performance
local cos = math.cos
local sin = math.sin

-- Define a struct for our custom matrix and instances
Ffi.cdef[[
   typedef struct {
      float mat[16];
   } lovox_matrix;

   typedef struct {
      float mat[16];
      unsigned char r, g, b, a;
      float frame;
   } lovox_instance;
]]

--- Create a new Transform object.
-- @returns Transform
local new = Ffi.typeof("lovox_matrix")

-- This temporary variable is filled by the different methods
local temp = new()

--- Clones the Transform.
-- @returns new A copy of the Transform
function Transform:clone()
   -- local out = new()
   -- for i=0, 15 do
   --    out.mat[i] = self.mat[i]
   -- end
   -- return out

   return new(self)
end

--- Get the internal transformation matrix stored by this Transform.
-- @returns e1_1, e1_2, ..., e4_4 The 16 components of the Matrix, in ROW-MAJOR order (eROW_COLUMN)
function Transform:getMatrix()
   local e = self.mat

   return e[0], e[4], e[8],  e[12],
          e[1], e[5], e[9],  e[13],
          e[2], e[6], e[10], e[14],
          e[3], e[7], e[11], e[15]
end

--- Directly sets the Transform's internal 4x4 transformation matrix.
-- @param layout Order of the matrix element arguments, "row" for ROW-MAJOR (default), or "column" for COLUMN-MAJOR
-- @param e1_1, e1_2, ..., e4_4 The 16 components of the Matrix in the order specified with layout
function Transform:setMatrix(layout, ...)
   if type(layout) == "number" then
      self:setMatrix(nil, ...)
   end

   local e = self.mat

   if layout == "column" then
      e[0],  e[1],  e[2],  e[3],
      e[4],  e[5],  e[6],  e[7],
      e[8],  e[9],  e[10], e[11],
      e[12], e[13], e[14], e[15] = ...
   elseif layout == "row" or layout == nil then
      e[0], e[4], e[8],  e[12],
      e[1], e[5], e[9],  e[13],
      e[2], e[6], e[10], e[14],
      e[3], e[7], e[11], e[15] = ...
   else
      error("Invalid layout, expected one of 'row' or 'column'", 2)
   end

   return self
end

local reuse = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

--- Fills a table with the components of the transformation matrix for this Transform.
-- This table can then be sent to a Shader safely.
-- @param tab The table to fill. Defaults to a reusable table (don't store this, it may change)
-- @returns matrix The filled table
function Transform:send(tab)
   local e, t = self.mat, tab or reuse

   t[1],  t[2],  t[3],  t[4]  = e[0], e[4], e[8],  e[12]
   t[5],  t[6],  t[7],  t[8]  = e[1], e[5], e[9],  e[13]
   t[9],  t[10], t[11], t[12] = e[2], e[6], e[10], e[14]
   t[13], t[14], t[15], t[16] = e[3], e[7], e[11], e[15]

   return t
end

--- Sets all the components of the Transform's transformation matrix to 0.
-- @returns self
function Transform:clear()
   local e = self.mat

   e[0],  e[1],  e[2],  e[3]  = 0, 0, 0, 0
   e[4],  e[5],  e[6],  e[7]  = 0, 0, 0, 0
   e[8],  e[9],  e[10], e[11] = 0, 0, 0, 0
   e[12], e[13], e[14], e[15] = 0, 0, 0, 0

   return self
end

--- Resets the Transform to an identity state.
-- This erases previous transformations
-- @returns self
function Transform:reset()
   local e = self.mat

   e[0],  e[1],  e[2],  e[3]  = 1, 0, 0, 0
   e[4],  e[5],  e[6],  e[7]  = 0, 1, 0, 0
   e[8],  e[9],  e[10], e[11] = 0, 0, 1, 0
   e[12], e[13], e[14], e[15] = 0, 0, 0, 1

   return self
end

--- Resets the Transform to the specified transformation parameters.
-- @param x, y, z Amount to translate on the X, Y and Z axis
-- @param angle Rotation of the Transform in radians
-- @param sx, sy, sz Scale factors on the X, Y and Z axis
-- @param ox, oy, oz Origin offset in the X, Y and Z axis
-- @param kx, ky Shearing/skew factors on the X and Y axis
-- @returns self
function Transform:setTransformation(x, y, z, angle, sx, sy, sz, ox, oy, oz, kx, ky)
   local e = self:reset().mat

   ox, oy, oz = ox or 0, oy or 0, oz or 0
   kx, ky     = kx or 0, ky or 0
   sx         = sx or 1
   sy         = sy or sx
   sz         = sz or sy

   local s, c = sin(angle or 0), cos(angle or 0)

   -- matrix multiplication carried out on paper:
   -- |1 0 0 x| |c -s 0 0| |sx  0 0 0| | 1 ky 0 0| |1 0 0 -ox|
   -- |0 1 0 y| |s  c 0 0| | 0 sy 0 0| |kx  1 0 0| |0 1 0 -oy|
   -- |0 0 1 z| |0  0 1 0| | 0  0 1 0| | 0  0 1 0| |0 0 1 -oz|
   -- |0 0 0 1| |0  0 0 1| | 0  0 0 1| | 0  0 0 1| |0 0 0  1 |
   -- move      rotate        scale       skew       origin
   e[0]  = c*sx - s*sy*kx
   e[4]  = c*sx*ky - s*sy
   e[1]  = s*sx + c*sy*kx
   e[5]  = s*sx*ky + c*sy
   e[10] = sz or 0

   e[12] = -ox*e[0] -oy*e[4] +(x or 0)
   e[13] = -ox*e[1] -oy*e[5] +(y or 0)
   e[14] = -oz*e[10]         +(z or 0)

   return self
end

--This functions sets a matrix to a translation matrix
local function setTranslation(self, x, y, z)
   local e = self:reset().mat

   e[12] = x or 0
   e[13] = y or 0
   e[14] = z or 0

   return self
end

--- Applies a translation to the Transform's coordinate system.
-- @param x, y, z The ammount to translate on the X, Y and Z axis
-- @returns self
function Transform:translate(x, y, z)
   setTranslation(temp, x, y, z)
   return self:apply(temp)
end

--This functions sets a matrix to a rotation matrix
local function setRotation(self, angle)
   local c, s = cos(angle or 0), sin(angle or 0)

   local e = self:reset().mat

   e[0] =  c
   e[4] = -s
   e[1] =  s
   e[5] =  c

   return self
end

--- Applies a rotation to the Transform's coordinate system.
-- This rotation happens in the XY plane.
-- @param angle Angle of the rotation applied
-- @returns self
function Transform:rotate(angle)
   setRotation(temp, angle)
   return self:apply(temp)
end

--This functions sets a matrix to a scaling matrix
local function setScale(self, sx, sy, sz)
   local e = self:reset().mat

   e[0]  = sx or 1
   e[5]  = sy or e[0]
   e[10] = sz or e[5]

   return self
end

--- Scales the Transform's coordinate system.
-- @param sx, sy, sz Relative scale factors along the X, Y and Z axis
-- @returns self
function Transform:scale(sx, sy, sz)
   setScale(temp, sx, sy, sz)
   return self:apply(temp)
end

--This functions sets a matrix to a shearing matrix
local function setShear(self, kx, ky)
   local e = self:reset().mat

   e[1]  = kx or 0
   e[4]  = ky or 0

   return self
end

--- Applies a shear factor (skew) to the Transform's coordinate system.
-- The shearing is applied on the XY plane
-- @param kx, ky The shear factor along the X and Y axis
-- @returns self
function Transform:shear(kx, ky)
   setShear(temp, kx, ky)
   return self:apply(temp)
end

--- Applies the given other Transform object to this one.
-- @param other The other Transform object to apply to this Transform.
-- @returns self
function Transform:apply(other)
   local t, a = temp.mat, self.mat

   --Unpack the matrix (This makes this method compatible with LÖVE's Transforms)
   local b0,b4,b8,b12,b1,b5,b9,b13,b2,b6,b10,b14,b3,b7,b11,b15 = other:getMatrix()

   --Matrix multiplication code
   t[0]  = a[0] * b0  + a[4] * b1  + a[8]  * b2  + a[12] * b3
   t[4]  = a[0] * b4  + a[4] * b5  + a[8]  * b6  + a[12] * b7
   t[8]  = a[0] * b8  + a[4] * b9  + a[8]  * b10 + a[12] * b11
   t[12] = a[0] * b12 + a[4] * b13 + a[8]  * b14 + a[12] * b15

   t[1]  = a[1] * b0  + a[5] * b1  + a[9]  * b2  + a[13] * b3
   t[5]  = a[1] * b4  + a[5] * b5  + a[9]  * b6  + a[13] * b7
   t[9]  = a[1] * b8  + a[5] * b9  + a[9]  * b10 + a[13] * b11
   t[13] = a[1] * b12 + a[5] * b13 + a[9]  * b14 + a[13] * b15

   t[2]  = a[2] * b0  + a[6] * b1  + a[10] * b2  + a[14] * b3
   t[6]  = a[2] * b4  + a[6] * b5  + a[10] * b6  + a[14] * b7
   t[10] = a[2] * b8  + a[6] * b9  + a[10] * b10 + a[14] * b11
   t[14] = a[2] * b12 + a[6] * b13 + a[10] * b14 + a[14] * b15

   t[3]  = a[3] * b0  + a[7] * b1  + a[11] * b2  + a[15] * b3
   t[7]  = a[3] * b4  + a[7] * b5  + a[11] * b6  + a[15] * b7
   t[11] = a[3] * b8  + a[7] * b9  + a[11] * b10 + a[15] * b11
   t[15] = a[3] * b12 + a[7] * b13 + a[11] * b14 + a[15] * b15

   for i = 0, 15 do
      a[i] = t[i] --Fill self with the temporary variable
   end

   return self
end

--- Calculates the inverse Transform to this one.
-- @param output Optional Transform to fill with the inverse Transform.
-- @returns inverse The inverse Transform (output, if provided)
function Transform:inverse(output)
   output = output or new()
   local t, e = output.mat, self.mat

   --Inverse matrix code
   t[0]  =  e[5]  * e[10] * e[15] - e[5]  * e[11] * e[14] - e[9]  * e[6]  * e[15] +
            e[9]  * e[7]  * e[14] + e[13] * e[6]  * e[11] - e[13] * e[7]  * e[10]
   t[4]  = -e[4]  * e[10] * e[15] + e[4]  * e[11] * e[14] + e[8]  * e[6]  * e[15] -
            e[8]  * e[7]  * e[14] - e[12] * e[6]  * e[11] + e[12] * e[7]  * e[10]
   t[8]  =  e[4]  * e[9]  * e[15] - e[4]  * e[11] * e[13] - e[8]  * e[5]  * e[15] +
            e[8]  * e[7]  * e[13] + e[12] * e[5]  * e[11] - e[12] * e[7]  * e[9]
   t[12] = -e[4]  * e[9]  * e[14] + e[4]  * e[10] * e[13] + e[8]  * e[5]  * e[14] -
            e[8]  * e[6]  * e[13] - e[12] * e[5]  * e[10] + e[12] * e[6]  * e[9]
   t[1]  = -e[1]  * e[10] * e[15] + e[1]  * e[11] * e[14] + e[9]  * e[2]  * e[15] -
            e[9]  * e[3]  * e[14] - e[13] * e[2]  * e[11] + e[13] * e[3]  * e[10]
   t[5]  =  e[0]  * e[10] * e[15] - e[0]  * e[11] * e[14] - e[8]  * e[2]  * e[15] +
            e[8]  * e[3]  * e[14] + e[12] * e[2]  * e[11] - e[12] * e[3]  * e[10]
   t[9]  = -e[0]  * e[9]  * e[15] + e[0]  * e[11] * e[13] + e[8]  * e[1]  * e[15] -
            e[8]  * e[3]  * e[13] - e[12] * e[1]  * e[11] + e[12] * e[3]  * e[9]
   t[13] =  e[0]  * e[9]  * e[14] - e[0]  * e[10] * e[13] - e[8]  * e[1]  * e[14] +
            e[8]  * e[2]  * e[13] + e[12] * e[1]  * e[10] - e[12] * e[2]  * e[9]
   t[2]  =  e[1]  * e[6]  * e[15] - e[1]  * e[7]  * e[14] - e[5]  * e[2]  * e[15] +
            e[5]  * e[3]  * e[14] + e[13] * e[2]  * e[7]  - e[13] * e[3]  * e[6]
   t[6]  = -e[0]  * e[6]  * e[15] + e[0]  * e[7]  * e[14] + e[4]  * e[2]  * e[15] -
            e[4]  * e[3]  * e[14] - e[12] * e[2]  * e[7]  + e[12] * e[3]  * e[6]
   t[10] =  e[0]  * e[5]  * e[15] - e[0]  * e[7]  * e[13] - e[4]  * e[1]  * e[15] +
            e[4]  * e[3]  * e[13] + e[12] * e[1]  * e[7]  - e[12] * e[3]  * e[5]
   t[14] = -e[0]  * e[5]  * e[14] + e[0]  * e[6]  * e[13] + e[4]  * e[1]  * e[14] -
            e[4]  * e[2]  * e[13] - e[12] * e[1]  * e[6]  + e[12] * e[2]  * e[5]
   t[3]  = -e[1]  * e[6]  * e[11] + e[1]  * e[7]  * e[10] + e[5]  * e[2]  * e[11] -
            e[5]  * e[3]  * e[10] - e[9]  * e[2]  * e[7]  + e[9]  * e[3]  * e[6]
   t[7]  =  e[0]  * e[6]  * e[11] - e[0]  * e[7]  * e[10] - e[4]  * e[2]  * e[11] +
            e[4]  * e[3]  * e[10] + e[8]  * e[2]  * e[7]  - e[8]  * e[3]  * e[6]
   t[11] = -e[0]  * e[5]  * e[11] + e[0]  * e[7]  * e[9]  + e[4]  * e[1]  * e[11] -
            e[4]  * e[3]  * e[9]  - e[8]  * e[1]  * e[7]  + e[8]  * e[3]  * e[5]
   t[15] =  e[0]  * e[5]  * e[10] - e[0]  * e[6]  * e[9]  - e[4]  * e[1]  * e[10] +
            e[4]  * e[2]  * e[9]  + e[8]  * e[1]  * e[6]  - e[8]  * e[2]  * e[5]

   local det = e[0] * t[0] + e[1] * t[4] + e[2] * t[8] + e[3] * t[12]
   local invdet = 1/det

   for i=0, 15 do
      t[i] = t[i] * invdet
   end

   return output
end

--- Applies the Transform to an specific point.
-- @param x, y, z The X, Y, Z coordinate of the point to transform.
-- @returns x, y, z The transformed point.
function Transform:transformPoint(x, y, z)
   local e = self.mat

   local nx = (e[0] * x) + (e[4] * y) + (e[8]  * z) + e[12]
   local ny = (e[1] * x) + (e[5] * y) + (e[9]  * z) + e[13]
   local nz = (e[2] * x) + (e[6] * y) + (e[10] * z) + e[14]

   return nx, ny, nz
end

do
   local mat  = Ffi.typeof("lovox_matrix")
   local inst = Ffi.typeof("lovox_instance")

   -- Size of lovox_matrix and lovox_instance ctypes (in bytes)
   Transform.matrixSize   = Ffi.sizeof(mat)
   Transform.instanceSize = Ffi.sizeof(inst)

   --- Cast a pointer (from a Data object) to an "array" of lovox_instances
   -- @param pointer The pointer to cast
   -- @returns cdata The cdata object corresponding to the casted array
   function Transform.castInstances(pointer)
      return Ffi.cast("lovox_instance*", pointer)
   end

   -- Apply the metatypes to lovox_instance/matrix objects
   -- Equivalent to setmetatable but for ctypes
   Ffi.metatype(mat,  Transform)
   Ffi.metatype(inst, Transform)

   -- From this point on changing Transform won't have any effect
end

return new
