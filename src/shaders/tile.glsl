@ctype mat4 @import("../math.zig").Mat4

// vertex
@vs vs
uniform vs_params {
    mat4 vp;
};

in vec3 vert_pos;
in vec2 vert_uv;
in uvec3 tile; // instanced

out vec2 uv;
out vec3 color;

const float TILE_SIZE = 32.0;

mat4 mat4translate(vec3 v)
{
    mat4 m = mat4(1.0, 0.0, 0.0, 0.0,
                  0.0, 1.0, 0.0, 0.0,
                  0.0, 0.0, 1.0, 0.0,
                  v.x, v.y, v.z, 1.0);
    return m;
}

mat4 mat4scale(vec3 s)
{
    mat4 m = mat4(s.x, 0.0, 0.0, 0.0,
                  0.0, s.y, 0.0, 0.0,
                  0.0, 0.0, s.z, 0.0,
                  0.0, 0.0, 0.0, 1.0);
    return m;
}

void main()
{
    uint tx = tile.x & 0xFFFF;
    uint ty = (tile.x >> 16) & 0xFFFF;
    uint ti = tile.y & 0xFFFF;
    uint tw = (tile.y >> 16) & 0xFF;
    uint th = (tile.y >> 24) & 0xFF;
    uint tcol = tile.z;
    float ix = ti % tw;
    float iy = ti / th;

    vec3 pos = vec3(tx * TILE_SIZE, ty * TILE_SIZE, 0);
    vec3 scale = vec3(TILE_SIZE, TILE_SIZE, 1);

    gl_Position = vp * mat4translate(pos) * mat4scale(scale) * vec4(vert_pos.xy, 0.0, 1.0);
    uv = vec2(ix/tw + vert_uv.x * (1.0/tw), iy/th + vert_uv.y * (1.0)/th);
    color = vec3((tcol & 0xFF) / 255.0, ((tcol >> 8) & 0xFF) / 255.0, ((tcol >> 16) & 0xFF) / 255.0);
}
@end

// fragment
@fs fs
uniform sampler2D tex;

in vec2 uv;
in vec3 color;

out vec4 frag_color;

void main()
{
    frag_color = texture(tex, uv) * vec4(color, 1.0);
    //frag_color = vec4(uv, 0.0, 1.0);
}
@end

// program
@program color vs fs

