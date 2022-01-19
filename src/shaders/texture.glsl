@ctype mat4 @import("../math.zig").Mat4

// vertex
@vs vs
uniform vs_params {
    mat4 mvp;
};

in vec3 position;
in vec2 uv0;

out vec2 uv;

void main() {
    gl_Position = mvp * vec4(position.xy, 0.0, 1.0);
    uv = uv0;
}
@end

// fragment
@fs fs
uniform sampler2D tex;
uniform fs_params {
    vec3 color;
};

in vec2 uv;

out vec4 frag_color;

void main() {
    frag_color = texture(tex, uv) * vec4(color, 1.0);
}
@end

// program
@program color vs fs

