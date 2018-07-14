#pragma language glsl3

#ifdef VERTEX

vec4 position(mat4 ortho, vec4 vertex) {
    //projection * vec4(x, y, z, 1) = vec4(x, y-z, y, 1)

    mat4 projection = mat4(
        1,  0,  0, 0,
        0,  1, 1/love_ScreenSize.y, 0,
        0,  -1,  0, 0,
        0,  0,  0, 1
    );
    return ClipSpaceFromView * projection * TransformMatrix * vertex;
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