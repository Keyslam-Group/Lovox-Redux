#pragma language glsl3

#ifdef VERTEX

uniform mat4 projection;

// Transforms our voxel into screen space coordinates properly
vec4 position(mat4 ortho, vec4 vertex) {
    //projection * vec4(x, y, z, 1) = vec4(x, y-z, y, 1)
    return ClipSpaceFromView * projection * TransformMatrix * vertex;
}
#endif

#ifdef PIXEL
uniform sampler2DArray MainTex;

// Samples from an Array image. Discards alpha values.
void effect() {
    vec4 pixel = Texel(MainTex, VaryingTexCoord.xyz);
    
    if (pixel.a == 0.0)
        discard;
    
    love_PixelColor = pixel * VaryingColor;
}
#endif