#pragma language glsl3
varying float VaryingFrame;

#ifdef VERTEX

uniform mat4 projection;
uniform mat4 view;

attribute vec4  MatRow1;
attribute vec4  MatRow2;
attribute vec4  MatRow3;
attribute vec4  MatRow4;
attribute float AnimationFrame;

// Transforms our voxel into screen space coordinates properly
vec4 position(mat4 ortho, vec4 vertex) {
   mat4 transform = mat4(MatRow1, MatRow2, MatRow3, MatRow4);

   VaryingFrame = AnimationFrame;
   return ClipSpaceFromView * projection * view * transform * vertex;
}

#endif

#ifdef PIXEL

uniform ArrayImage MainTex;

// Samples from an ArrayImage. Discards alpha values
void effect () {
   vec4 pixel = Texel(MainTex, vec3(VaryingTexCoord.xy, VaryingFrame));

   if (pixel.a < 1.0f) 
      discard;
   
   love_PixelColor = pixel * VaryingColor;
}

#endif
