#pragma language glsl3

#ifdef VERTEX

uniform mat4 projection;
uniform mat4 view;

attribute vec4 MatRow1;
attribute vec4 MatRow2;
attribute vec4 MatRow3;
attribute vec4 MatRow4;

// Transforms our voxel into screen space coordinates properly
vec4 position(mat4 ortho, vec4 vertex) {
   mat4 transform = mat4(MatRow1, MatRow2, MatRow3, MatRow4);
   return ClipSpaceFromView * projection * view * transform * vertex;
}

#endif

#ifdef PIXEL

// Samples from an Image. Discards alpha values.
vec4 effect(vec4 color, sampler2D img, vec2 texture_coords, vec2 screen_coords) {
   vec4 pixel = Texel(img, texture_coords);

   if (pixel.a < 1.0f) 
      discard;

   return pixel * color;
}

#endif
