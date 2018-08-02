local Ffi = require("ffi")

local Mat4   = {}
Mat4.__index = Mat4

-- Define a struct for our custom vertex format
Ffi.cdef[[
   typedef struct {
      float mat[16];
   } fm_matrix;

   typedef struct {
      float mat[16];
      unsigned char r, g, b, a;
   } fm_instance;
]]

Mat4.newMatrix = Ffi.typeof("fm_matrix")

local temp = Mat4.newMatrix()

function Mat4:clone()
   local out = Mat4.newMatrix()
   -- for i=0, 15 do
   --    out.mat[i] = self.mat[i] --Possible to Ffi.copy
   -- end
   -- return out

   return Mat4.newMatrix(self)
end

function Mat4:getMatrix()
   local e = self.mat

   return e[0], e[4], e[8],  e[12],
          e[1], e[5], e[9],  e[13],
          e[2], e[6], e[10], e[14],
          e[3], e[7], e[11], e[15]
end

local reuse = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

function Mat4:send(t)
   local e, t = self.mat, t or reuse

   t[1],  t[2],  t[3],  t[4]  = e[0], e[4], e[8],  e[12]
   t[5],  t[6],  t[7],  t[8]  = e[1], e[5], e[9],  e[13]
   t[9],  t[10], t[11], t[12] = e[2], e[6], e[10], e[14]
   t[13], t[14], t[15], t[16] = e[3], e[7], e[11], e[15]

   return t
end

function Mat4:clear()
   local e = self.mat

   --Possible to Ffi.fill
   e[0],  e[1],  e[2],  e[3]  = 0, 0, 0, 0
   e[4],  e[5],  e[6],  e[7]  = 0, 0, 0, 0
   e[8],  e[9],  e[10], e[11] = 0, 0, 0, 0
   e[12], e[13], e[14], e[15] = 0, 0, 0, 0

   return self
end

function Mat4:reset()
   local e = self.mat

   --Possible to Ffi.fill or Ffi.copy from a fixed identity matrix
   e[0],  e[1],  e[2],  e[3]  = 1, 0, 0, 0
   e[4],  e[5],  e[6],  e[7]  = 0, 1, 0, 0
   e[8],  e[9],  e[10], e[11] = 0, 0, 1, 0
   e[12], e[13], e[14], e[15] = 0, 0, 0, 1

   return self
end

function Mat4:setTranslation(x, y, z)
   local e = self:reset().mat

   e[12] = x or 0
   e[13] = y or 0
   e[14] = z or 0

   return self
end

function Mat4:setRotation(angle)
   local c, s = math.cos(angle or 0), math.sin(angle or 0)

   local e = self:reset().mat

   e[0] =  c
   e[4] = -s
   e[1] =  s
   e[5] =  c

   return self
end

function Mat4:setScale(sx, sy, sz)
   local e = self:reset().mat

   e[0]  = sx or 1
   e[5]  = sy or e[0]
   e[10] = sz or e[5]

   return self
end

function Mat4:setShear(kx, ky)
   local e = self:reset().mat

   e[1]  = kx or 0
   e[4]  = ky or 0

   return self
end

function Mat4:setTransformation(x, y, z, angle, sx, sy, sz, ox, oy, oz, kx, ky)
   local e = self:reset().mat

   local ox, oy, oz = ox or 0, oy or 0, oz or 0
   local kx, ky     = kx or 0, ky or 0
   local sx         = sx or 1
   local sy         = sy or sx
   local sz         = sz or sy

   local s, c = math.cos(angle or 0), math.sin(angle or 0)

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

function Mat4:translate(x, y, z)
   temp:setTranslation(x, y, z)
   return self:apply(temp)
end

function Mat4:rotate(angle)
   temp:setRotation(angle)
   return self:apply(temp)
end

function Mat4:scale(sx, sy, sz)
   temp:setScale(sx, sy, sz)
   return self:apply(temp)
end

function Mat4:shear(kx, ky)
   temp:setShear(kx, ky)
   return self:apply(temp)
end

function Mat4:apply(o)
   local tmp, a, b = temp.mat, self.mat, o.mat

   tmp[0]  = a[0]  * b[0] + a[1]  * b[4] + a[2]  * b[8]  + a[3]  * b[12]
   tmp[1]  = a[0]  * b[1] + a[1]  * b[5] + a[2]  * b[9]  + a[3]  * b[13]
   tmp[2]  = a[0]  * b[2] + a[1]  * b[6] + a[2]  * b[10] + a[3]  * b[14]
   tmp[3]  = a[0]  * b[3] + a[1]  * b[7] + a[2]  * b[11] + a[3]  * b[15]
   tmp[4]  = a[4]  * b[0] + a[5]  * b[4] + a[6]  * b[8]  + a[7]  * b[12]
   tmp[5]  = a[4]  * b[1] + a[5]  * b[5] + a[6]  * b[9]  + a[7]  * b[13]
   tmp[6]  = a[4]  * b[2] + a[5]  * b[6] + a[6]  * b[10] + a[7]  * b[14]
   tmp[7]  = a[4]  * b[3] + a[5]  * b[7] + a[6]  * b[11] + a[7]  * b[15]
   tmp[8]  = a[8]  * b[0] + a[9]  * b[4] + a[10] * b[8]  + a[11] * b[12]
   tmp[9]  = a[8]  * b[1] + a[9]  * b[5] + a[10] * b[9]  + a[11] * b[13]
   tmp[10] = a[8]  * b[2] + a[9]  * b[6] + a[10] * b[10] + a[11] * b[14]
   tmp[11] = a[8]  * b[3] + a[9]  * b[7] + a[10] * b[11] + a[11] * b[15]
   tmp[12] = a[12] * b[0] + a[13] * b[4] + a[14] * b[8]  + a[15] * b[12]
   tmp[13] = a[12] * b[1] + a[13] * b[5] + a[14] * b[9]  + a[15] * b[13]
   tmp[14] = a[12] * b[2] + a[13] * b[6] + a[14] * b[10] + a[15] * b[14]
   tmp[15] = a[12] * b[3] + a[13] * b[7] + a[14] * b[11] + a[15] * b[15]
 
   for i = 0, 15 do
      b[i] = tmp[i] --Possible to Ffi.copy
   end
 
   return self
end

do
   local inst = Ffi.typeof("fm_instance")
   local mat  = Ffi.typeof("fm_matrix")

   Mat4.matrixSize   = Ffi.sizeof(mat)
   Mat4.instanceSize = Ffi.sizeof(inst)

   function Mat4.castInstances(pointer)
      return Ffi.cast("fm_instance*", pointer)
   end

   Ffi.metatype(mat,  Mat4)
   Ffi.metatype(inst, Mat4)
end

return Mat4