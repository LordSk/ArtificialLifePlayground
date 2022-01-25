@ctype mat4 @import("../math.zig").Mat4

// vertex
@vs vs
uniform vs_params {
    mat4 vp;
};

in vec3 vert_pos;

// instanced
in vec4 inst_pos_size;
in vec3 inst_rcz;

out vec4 color;

const float pi = 3.14159265359;

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

mat4 mat4rotZ(float a)
{
    const float sin_theta = sin(a);
    const float cos_theta = cos(a);
    const float cos_value = 1.0 - cos_theta;

    mat4 m = mat4(1.0, 0.0, 0.0, 0.0,
                  0.0, 1.0, 0.0, 0.0,
                  0.0, 0.0, 1.0, 0.0,
                  0.0, 0.0, 0.0, 1.0);
    
    m[0][0] = cos_theta;
    m[0][1] = sin_theta;
    m[1][0] = -sin_theta;
    m[1][1] = cos_theta;
    m[2][2] = cos_value + cos_theta;
    return m;
}

void main()
{
    vec3 pos = vec3(inst_pos_size.xy, inst_rcz.z);
    vec3 scale = vec3(inst_pos_size.zw, 1);
    float rot = inst_rcz.x;
    uint c4 = floatBitsToUint(inst_rcz.y);

    gl_Position = vp * mat4translate(pos) * mat4rotZ(rot) * mat4scale(scale) * vec4(vert_pos.xy, 0.0, 1.0);
    color = vec4((c4 & 0xFF) / 255.0, ((c4 >> 8) & 0xFF) / 255.0, ((c4 >> 16) & 0xFF) / 255.0, ((c4 >> 24) & 0xFF) / 255.0);
}
@end

// fragment
@fs fs
uniform sampler2D tex;

in vec4 color;

out vec4 frag_color;

void main()
{
    frag_color = color;
}
@end

// program
@program color vs fs

