#pragma language glsl3

#ifdef VERTEX
 //projection * vec4(x, y, z, 1) = vec4(x, y-z, y, 1)
const mat4 projection = mat4(
    1,  0, 0, 0,
    0,  1, -1, 0,
    0,  1, 0, 0,
    0,  0, 0, 1
);

vec4 position(mat4 ortho, vec4 vertex) {
    return projection * ortho * vertex;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, sampler2D img, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(img, texture_coords);
    
    if (pixel.a == 0.0)
        discard;

    return pixel * color;
}
#endif
