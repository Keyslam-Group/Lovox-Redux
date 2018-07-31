local Ffi = require("ffi")

local Mat4 = {}
Mat4.proto = Ffi.metatype([[
   struct {
      float mat[16];
   }
]], Mat4)
Mat4.sizeof = Ffi.sizeof(Mat4.proto)

function Mat4.new()
   return Mat4.proto()
end

function Mat4.setIdentity(a)
   local e = a.mat

   e[0],  e[1],  e[2],  e[3]  = 1, 0, 0, 0
   e[4],  e[5],  e[6],  e[7]  = 0, 1, 0, 0
   e[8],  e[9],  e[10], e[11] = 0, 0, 1, 0
   e[12], e[13], e[14], e[15] = 0, 0, 0, 1
end

function Mat4.setTranslation(a, x, y, z)
   Mat4.setIdentity(a)

   local e = a.mat

   e[12] = x or 0
   e[13] = y or 0
   e[14] = z or 0
end

function Mat4.setRotation(a, angle)
   Mat4.setIdentity(a)

   local c, s = math.cos(angle), math.sin(angle)

   local e = a.mat

   e[0] =  c
   e[4] = -s
   e[1] =  s
   e[5] =  c
end

function Mat4.setScale(a, sx, sy, sz)
   Mat4.setIdentity(a)

   local e = a.mat

   e[0]  = sx or 1
   e[5]  = sy or 1
   e[10] = sz or 1
end

local temp_translate = Mat4.new()
function Mat4.translate(a, x, y, z)
   Mat4.setTranslation(temp_translate, x, y, z)
   return Mat4.mul(a, temp_translate, a)
end

local temp_rotate = Mat4.new()
function Mat4.rotate(a, angle)
   Mat4.setRotation(temp_rotate, angle)
   return Mat4.mul(a, temp_rotate, a)
end

local temp_scale = Mat4.new()
function Mat4.scale(a, sx, sy, sz)
   Mat4.setScale(temp_scale, sx, sy, sz)
   return Mat4.mul(a, temp_scale, a)
end

local temp = Mat4.new().mat
function Mat4.mul(out, a, b)
   a, b = a.mat, b.mat

	temp[0]  = b[0]  * a[0] + b[1]  * a[4] + b[2]  * a[8]  + b[3]  * a[12]
	temp[1]  = b[0]  * a[1] + b[1]  * a[5] + b[2]  * a[9]  + b[3]  * a[13]
	temp[2]  = b[0]  * a[2] + b[1]  * a[6] + b[2]  * a[10] + b[3]  * a[14]
	temp[3]  = b[0]  * a[3] + b[1]  * a[7] + b[2]  * a[11] + b[3]  * a[15]
	temp[4]  = b[4]  * a[0] + b[5]  * a[4] + b[6]  * a[8]  + b[7]  * a[12]
	temp[5]  = b[4]  * a[1] + b[5]  * a[5] + b[6]  * a[9]  + b[7]  * a[13]
	temp[6]  = b[4]  * a[2] + b[5]  * a[6] + b[6]  * a[10] + b[7]  * a[14]
	temp[7]  = b[4]  * a[3] + b[5]  * a[7] + b[6]  * a[11] + b[7]  * a[15]
	temp[8]  = b[8]  * a[0] + b[9]  * a[4] + b[10] * a[8]  + b[11] * a[12]
	temp[9]  = b[8]  * a[1] + b[9]  * a[5] + b[10] * a[9]  + b[11] * a[13]
	temp[10] = b[8]  * a[2] + b[9]  * a[6] + b[10] * a[10] + b[11] * a[14]
	temp[11] = b[8]  * a[3] + b[9]  * a[7] + b[10] * a[11] + b[11] * a[15]
	temp[12] = b[12] * a[0] + b[13] * a[4] + b[14] * a[8]  + b[15] * a[12]
	temp[13] = b[12] * a[1] + b[13] * a[5] + b[14] * a[9]  + b[15] * a[13]
	temp[14] = b[12] * a[2] + b[13] * a[6] + b[14] * a[10] + b[15] * a[14]
	temp[15] = b[12] * a[3] + b[13] * a[7] + b[14] * a[11] + b[15] * a[15]

   do
      out = out.mat
      for i = 0, 15 do
         out[i] = temp[i]
      end
   end

	return out
end

return Mat4