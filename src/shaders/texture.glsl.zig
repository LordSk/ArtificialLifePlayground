const sg = @import("sokol").gfx;
//
//  #version:1# (machine generated, don't edit!)
//
//  Generated by sokol-shdc (https://github.com/floooh/sokol-tools)
//
//  Cmdline: sokol-shdc -i texture.glsl -o texture.glsl.zig -l glsl330:metal_macos:hlsl4 -f sokol_zig
//
//  Overview:
//
//      Shader program 'color':
//          Get shader desc: shd.colorShaderDesc(sg.queryBackend());
//          Vertex shader: vs
//              Attribute slots:
//                  ATTR_vs_position = 0
//                  ATTR_vs_uv0 = 1
//              Uniform block 'vs_params':
//                  C struct: vs_params_t
//                  Bind slot: SLOT_vs_params = 0
//          Fragment shader: fs
//              Uniform block 'fs_params':
//                  C struct: fs_params_t
//                  Bind slot: SLOT_fs_params = 0
//              Image 'tex':
//                  Type: ._2D
//                  Component Type: .FLOAT
//                  Bind slot: SLOT_tex = 0
//
//
pub const ATTR_vs_position = 0;
pub const ATTR_vs_uv0 = 1;
pub const SLOT_tex = 0;
pub const SLOT_vs_params = 0;
pub const VsParams = extern struct {
    mvp: @import("../math.zig").Mat4 align(16),
    tile: [3]i32,
    _pad_76: [4]u8 = undefined,
};
pub const SLOT_fs_params = 0;
pub const FsParams = extern struct {
    color: [3]f32 align(16),
    _pad_12: [4]u8 = undefined,
};
//
// #version 330
// 
// struct vs_params
// {
//     mat4 mvp;
//     ivec3 tile;
// };
// 
// uniform vs_params _22;
// 
// layout(location = 0) in vec3 position;
// out vec2 uv;
// layout(location = 1) in vec2 uv0;
// 
// void main()
// {
//     gl_Position = _22.mvp * vec4(position.xy, 0.0, 1.0);
//     float _64 = float(_22.tile.y);
//     float _80 = float(_22.tile.z);
//     uv = vec2((float(_22.tile.x % _22.tile.y) / _64) + (uv0.x * (1.0 / _64)), (float(_22.tile.x / _22.tile.z) / _80) + (uv0.y / _80));
// }
// 
//
const vs_source_glsl330 = [458]u8 {
    0x23,0x76,0x65,0x72,0x73,0x69,0x6f,0x6e,0x20,0x33,0x33,0x30,0x0a,0x0a,0x73,0x74,
    0x72,0x75,0x63,0x74,0x20,0x76,0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x0a,0x7b,
    0x0a,0x20,0x20,0x20,0x20,0x6d,0x61,0x74,0x34,0x20,0x6d,0x76,0x70,0x3b,0x0a,0x20,
    0x20,0x20,0x20,0x69,0x76,0x65,0x63,0x33,0x20,0x74,0x69,0x6c,0x65,0x3b,0x0a,0x7d,
    0x3b,0x0a,0x0a,0x75,0x6e,0x69,0x66,0x6f,0x72,0x6d,0x20,0x76,0x73,0x5f,0x70,0x61,
    0x72,0x61,0x6d,0x73,0x20,0x5f,0x32,0x32,0x3b,0x0a,0x0a,0x6c,0x61,0x79,0x6f,0x75,
    0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x30,0x29,0x20,
    0x69,0x6e,0x20,0x76,0x65,0x63,0x33,0x20,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,
    0x3b,0x0a,0x6f,0x75,0x74,0x20,0x76,0x65,0x63,0x32,0x20,0x75,0x76,0x3b,0x0a,0x6c,
    0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,
    0x20,0x31,0x29,0x20,0x69,0x6e,0x20,0x76,0x65,0x63,0x32,0x20,0x75,0x76,0x30,0x3b,
    0x0a,0x0a,0x76,0x6f,0x69,0x64,0x20,0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,0x7b,0x0a,
    0x20,0x20,0x20,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,
    0x3d,0x20,0x5f,0x32,0x32,0x2e,0x6d,0x76,0x70,0x20,0x2a,0x20,0x76,0x65,0x63,0x34,
    0x28,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x2e,0x78,0x79,0x2c,0x20,0x30,0x2e,
    0x30,0x2c,0x20,0x31,0x2e,0x30,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,
    0x61,0x74,0x20,0x5f,0x36,0x34,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x28,0x5f,
    0x32,0x32,0x2e,0x74,0x69,0x6c,0x65,0x2e,0x79,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,
    0x66,0x6c,0x6f,0x61,0x74,0x20,0x5f,0x38,0x30,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,
    0x74,0x28,0x5f,0x32,0x32,0x2e,0x74,0x69,0x6c,0x65,0x2e,0x7a,0x29,0x3b,0x0a,0x20,
    0x20,0x20,0x20,0x75,0x76,0x20,0x3d,0x20,0x76,0x65,0x63,0x32,0x28,0x28,0x66,0x6c,
    0x6f,0x61,0x74,0x28,0x5f,0x32,0x32,0x2e,0x74,0x69,0x6c,0x65,0x2e,0x78,0x20,0x25,
    0x20,0x5f,0x32,0x32,0x2e,0x74,0x69,0x6c,0x65,0x2e,0x79,0x29,0x20,0x2f,0x20,0x5f,
    0x36,0x34,0x29,0x20,0x2b,0x20,0x28,0x75,0x76,0x30,0x2e,0x78,0x20,0x2a,0x20,0x28,
    0x31,0x2e,0x30,0x20,0x2f,0x20,0x5f,0x36,0x34,0x29,0x29,0x2c,0x20,0x28,0x66,0x6c,
    0x6f,0x61,0x74,0x28,0x5f,0x32,0x32,0x2e,0x74,0x69,0x6c,0x65,0x2e,0x78,0x20,0x2f,
    0x20,0x5f,0x32,0x32,0x2e,0x74,0x69,0x6c,0x65,0x2e,0x7a,0x29,0x20,0x2f,0x20,0x5f,
    0x38,0x30,0x29,0x20,0x2b,0x20,0x28,0x75,0x76,0x30,0x2e,0x79,0x20,0x2f,0x20,0x5f,
    0x38,0x30,0x29,0x29,0x3b,0x0a,0x7d,0x0a,0x0a,0x00,
};
//
// #version 330
// 
// uniform vec4 fs_params[1];
// uniform sampler2D tex;
// 
// layout(location = 0) out vec4 frag_color;
// in vec2 uv;
// 
// void main()
// {
//     frag_color = texture(tex, uv) * vec4(fs_params[0].xyz, 1.0);
// }
// 
//
const fs_source_glsl330 = [203]u8 {
    0x23,0x76,0x65,0x72,0x73,0x69,0x6f,0x6e,0x20,0x33,0x33,0x30,0x0a,0x0a,0x75,0x6e,
    0x69,0x66,0x6f,0x72,0x6d,0x20,0x76,0x65,0x63,0x34,0x20,0x66,0x73,0x5f,0x70,0x61,
    0x72,0x61,0x6d,0x73,0x5b,0x31,0x5d,0x3b,0x0a,0x75,0x6e,0x69,0x66,0x6f,0x72,0x6d,
    0x20,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x32,0x44,0x20,0x74,0x65,0x78,0x3b,0x0a,
    0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,
    0x20,0x3d,0x20,0x30,0x29,0x20,0x6f,0x75,0x74,0x20,0x76,0x65,0x63,0x34,0x20,0x66,
    0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x69,0x6e,0x20,0x76,0x65,
    0x63,0x32,0x20,0x75,0x76,0x3b,0x0a,0x0a,0x76,0x6f,0x69,0x64,0x20,0x6d,0x61,0x69,
    0x6e,0x28,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x72,0x61,0x67,0x5f,0x63,
    0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x28,0x74,
    0x65,0x78,0x2c,0x20,0x75,0x76,0x29,0x20,0x2a,0x20,0x76,0x65,0x63,0x34,0x28,0x66,
    0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x5b,0x30,0x5d,0x2e,0x78,0x79,0x7a,0x2c,
    0x20,0x31,0x2e,0x30,0x29,0x3b,0x0a,0x7d,0x0a,0x0a,0x00,
};
//
// cbuffer vs_params : register(b0)
// {
//     row_major float4x4 _22_mvp : packoffset(c0);
//     int3 _22_tile : packoffset(c4);
// };
// 
// 
// static float4 gl_Position;
// static float3 position;
// static float2 uv;
// static float2 uv0;
// 
// struct SPIRV_Cross_Input
// {
//     float3 position : TEXCOORD0;
//     float2 uv0 : TEXCOORD1;
// };
// 
// struct SPIRV_Cross_Output
// {
//     float2 uv : TEXCOORD0;
//     float4 gl_Position : SV_Position;
// };
// 
// #line 17 "texture.glsl"
// void vert_main()
// {
// #line 17 "texture.glsl"
//     gl_Position = mul(float4(position.xy, 0.0f, 1.0f), _22_mvp);
// #line 18 "texture.glsl"
// #line 19 "texture.glsl"
// #line 20 "texture.glsl"
//     float _64 = float(_22_tile.y);
//     float _80 = float(_22_tile.z);
//     uv = float2((float(_22_tile.x % _22_tile.y) / _64) + (uv0.x * (1.0f / _64)), (float(_22_tile.x / _22_tile.z) / _80) + (uv0.y / _80));
// }
// 
// SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
// {
//     position = stage_input.position;
//     uv0 = stage_input.uv0;
//     vert_main();
//     SPIRV_Cross_Output stage_output;
//     stage_output.gl_Position = gl_Position;
//     stage_output.uv = uv;
//     return stage_output;
// }
//
const vs_source_hlsl4 = [1091]u8 {
    0x63,0x62,0x75,0x66,0x66,0x65,0x72,0x20,0x76,0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,
    0x73,0x20,0x3a,0x20,0x72,0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x62,0x30,0x29,
    0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x72,0x6f,0x77,0x5f,0x6d,0x61,0x6a,0x6f,0x72,
    0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x78,0x34,0x20,0x5f,0x32,0x32,0x5f,0x6d,0x76,
    0x70,0x20,0x3a,0x20,0x70,0x61,0x63,0x6b,0x6f,0x66,0x66,0x73,0x65,0x74,0x28,0x63,
    0x30,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x69,0x6e,0x74,0x33,0x20,0x5f,0x32,0x32,
    0x5f,0x74,0x69,0x6c,0x65,0x20,0x3a,0x20,0x70,0x61,0x63,0x6b,0x6f,0x66,0x66,0x73,
    0x65,0x74,0x28,0x63,0x34,0x29,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x0a,0x73,0x74,0x61,
    0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x67,0x6c,0x5f,0x50,0x6f,
    0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x33,0x20,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,
    0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,
    0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,
    0x75,0x76,0x30,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x53,0x50,0x49,
    0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,0x0a,0x7b,
    0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x33,0x20,0x70,0x6f,0x73,0x69,
    0x74,0x69,0x6f,0x6e,0x20,0x3a,0x20,0x54,0x45,0x58,0x43,0x4f,0x4f,0x52,0x44,0x30,
    0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,0x30,
    0x20,0x3a,0x20,0x54,0x45,0x58,0x43,0x4f,0x4f,0x52,0x44,0x31,0x3b,0x0a,0x7d,0x3b,
    0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,
    0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,
    0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,0x20,0x3a,0x20,0x54,0x45,
    0x58,0x43,0x4f,0x4f,0x52,0x44,0x30,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,
    0x61,0x74,0x34,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,
    0x3a,0x20,0x53,0x56,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x7d,
    0x3b,0x0a,0x0a,0x23,0x6c,0x69,0x6e,0x65,0x20,0x31,0x37,0x20,0x22,0x74,0x65,0x78,
    0x74,0x75,0x72,0x65,0x2e,0x67,0x6c,0x73,0x6c,0x22,0x0a,0x76,0x6f,0x69,0x64,0x20,
    0x76,0x65,0x72,0x74,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,0x7b,0x0a,0x23,0x6c,
    0x69,0x6e,0x65,0x20,0x31,0x37,0x20,0x22,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x2e,
    0x67,0x6c,0x73,0x6c,0x22,0x0a,0x20,0x20,0x20,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,
    0x69,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x6d,0x75,0x6c,0x28,0x66,0x6c,0x6f,0x61,
    0x74,0x34,0x28,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x2e,0x78,0x79,0x2c,0x20,
    0x30,0x2e,0x30,0x66,0x2c,0x20,0x31,0x2e,0x30,0x66,0x29,0x2c,0x20,0x5f,0x32,0x32,
    0x5f,0x6d,0x76,0x70,0x29,0x3b,0x0a,0x23,0x6c,0x69,0x6e,0x65,0x20,0x31,0x38,0x20,
    0x22,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x2e,0x67,0x6c,0x73,0x6c,0x22,0x0a,0x23,
    0x6c,0x69,0x6e,0x65,0x20,0x31,0x39,0x20,0x22,0x74,0x65,0x78,0x74,0x75,0x72,0x65,
    0x2e,0x67,0x6c,0x73,0x6c,0x22,0x0a,0x23,0x6c,0x69,0x6e,0x65,0x20,0x32,0x30,0x20,
    0x22,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x2e,0x67,0x6c,0x73,0x6c,0x22,0x0a,0x20,
    0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x20,0x5f,0x36,0x34,0x20,0x3d,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x28,0x5f,0x32,0x32,0x5f,0x74,0x69,0x6c,0x65,0x2e,0x79,0x29,
    0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x20,0x5f,0x38,0x30,0x20,
    0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x28,0x5f,0x32,0x32,0x5f,0x74,0x69,0x6c,0x65,
    0x2e,0x7a,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x75,0x76,0x20,0x3d,0x20,0x66,0x6c,
    0x6f,0x61,0x74,0x32,0x28,0x28,0x66,0x6c,0x6f,0x61,0x74,0x28,0x5f,0x32,0x32,0x5f,
    0x74,0x69,0x6c,0x65,0x2e,0x78,0x20,0x25,0x20,0x5f,0x32,0x32,0x5f,0x74,0x69,0x6c,
    0x65,0x2e,0x79,0x29,0x20,0x2f,0x20,0x5f,0x36,0x34,0x29,0x20,0x2b,0x20,0x28,0x75,
    0x76,0x30,0x2e,0x78,0x20,0x2a,0x20,0x28,0x31,0x2e,0x30,0x66,0x20,0x2f,0x20,0x5f,
    0x36,0x34,0x29,0x29,0x2c,0x20,0x28,0x66,0x6c,0x6f,0x61,0x74,0x28,0x5f,0x32,0x32,
    0x5f,0x74,0x69,0x6c,0x65,0x2e,0x78,0x20,0x2f,0x20,0x5f,0x32,0x32,0x5f,0x74,0x69,
    0x6c,0x65,0x2e,0x7a,0x29,0x20,0x2f,0x20,0x5f,0x38,0x30,0x29,0x20,0x2b,0x20,0x28,
    0x75,0x76,0x30,0x2e,0x79,0x20,0x2f,0x20,0x5f,0x38,0x30,0x29,0x29,0x3b,0x0a,0x7d,
    0x0a,0x0a,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,
    0x74,0x70,0x75,0x74,0x20,0x6d,0x61,0x69,0x6e,0x28,0x53,0x50,0x49,0x52,0x56,0x5f,
    0x43,0x72,0x6f,0x73,0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,0x20,0x73,0x74,0x61,0x67,
    0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x70,
    0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,
    0x69,0x6e,0x70,0x75,0x74,0x2e,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,
    0x20,0x20,0x20,0x20,0x75,0x76,0x30,0x20,0x3d,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,
    0x69,0x6e,0x70,0x75,0x74,0x2e,0x75,0x76,0x30,0x3b,0x0a,0x20,0x20,0x20,0x20,0x76,
    0x65,0x72,0x74,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,
    0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,
    0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x3b,
    0x0a,0x20,0x20,0x20,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,
    0x74,0x2e,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,
    0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x2e,0x75,0x76,
    0x20,0x3d,0x20,0x75,0x76,0x3b,0x0a,0x20,0x20,0x20,0x20,0x72,0x65,0x74,0x75,0x72,
    0x6e,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x3b,0x0a,
    0x7d,0x0a,0x00,
};
//
// cbuffer fs_params : register(b0)
// {
//     float3 _25_color : packoffset(c0);
// };
// 
// Texture2D<float4> tex : register(t0);
// SamplerState _tex_sampler : register(s0);
// 
// static float4 frag_color;
// static float2 uv;
// 
// struct SPIRV_Cross_Input
// {
//     float2 uv : TEXCOORD0;
// };
// 
// struct SPIRV_Cross_Output
// {
//     float4 frag_color : SV_Target0;
// };
// 
// #line 16 "texture.glsl"
// void frag_main()
// {
// #line 16 "texture.glsl"
//     frag_color = tex.Sample(_tex_sampler, uv) * float4(_25_color, 1.0f);
// }
// 
// SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
// {
//     uv = stage_input.uv;
//     frag_main();
//     SPIRV_Cross_Output stage_output;
//     stage_output.frag_color = frag_color;
//     return stage_output;
// }
//
const fs_source_hlsl4 = [679]u8 {
    0x63,0x62,0x75,0x66,0x66,0x65,0x72,0x20,0x66,0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,
    0x73,0x20,0x3a,0x20,0x72,0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x62,0x30,0x29,
    0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x33,0x20,0x5f,0x32,
    0x35,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3a,0x20,0x70,0x61,0x63,0x6b,0x6f,0x66,
    0x66,0x73,0x65,0x74,0x28,0x63,0x30,0x29,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x54,0x65,
    0x78,0x74,0x75,0x72,0x65,0x32,0x44,0x3c,0x66,0x6c,0x6f,0x61,0x74,0x34,0x3e,0x20,
    0x74,0x65,0x78,0x20,0x3a,0x20,0x72,0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x74,
    0x30,0x29,0x3b,0x0a,0x53,0x61,0x6d,0x70,0x6c,0x65,0x72,0x53,0x74,0x61,0x74,0x65,
    0x20,0x5f,0x74,0x65,0x78,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x20,0x3a,0x20,
    0x72,0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x73,0x30,0x29,0x3b,0x0a,0x0a,0x73,
    0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x66,0x72,0x61,
    0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,0x63,0x20,
    0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,
    0x63,0x74,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x49,
    0x6e,0x70,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,
    0x32,0x20,0x75,0x76,0x20,0x3a,0x20,0x54,0x45,0x58,0x43,0x4f,0x4f,0x52,0x44,0x30,
    0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x53,0x50,0x49,
    0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x0a,
    0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x66,0x72,0x61,
    0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3a,0x20,0x53,0x56,0x5f,0x54,0x61,0x72,
    0x67,0x65,0x74,0x30,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x23,0x6c,0x69,0x6e,0x65,0x20,
    0x31,0x36,0x20,0x22,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x2e,0x67,0x6c,0x73,0x6c,
    0x22,0x0a,0x76,0x6f,0x69,0x64,0x20,0x66,0x72,0x61,0x67,0x5f,0x6d,0x61,0x69,0x6e,
    0x28,0x29,0x0a,0x7b,0x0a,0x23,0x6c,0x69,0x6e,0x65,0x20,0x31,0x36,0x20,0x22,0x74,
    0x65,0x78,0x74,0x75,0x72,0x65,0x2e,0x67,0x6c,0x73,0x6c,0x22,0x0a,0x20,0x20,0x20,
    0x20,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x74,0x65,
    0x78,0x2e,0x53,0x61,0x6d,0x70,0x6c,0x65,0x28,0x5f,0x74,0x65,0x78,0x5f,0x73,0x61,
    0x6d,0x70,0x6c,0x65,0x72,0x2c,0x20,0x75,0x76,0x29,0x20,0x2a,0x20,0x66,0x6c,0x6f,
    0x61,0x74,0x34,0x28,0x5f,0x32,0x35,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x2c,0x20,0x31,
    0x2e,0x30,0x66,0x29,0x3b,0x0a,0x7d,0x0a,0x0a,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,
    0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x20,0x6d,0x61,0x69,0x6e,
    0x28,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x49,0x6e,0x70,
    0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x29,0x0a,
    0x7b,0x0a,0x20,0x20,0x20,0x20,0x75,0x76,0x20,0x3d,0x20,0x73,0x74,0x61,0x67,0x65,
    0x5f,0x69,0x6e,0x70,0x75,0x74,0x2e,0x75,0x76,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,
    0x72,0x61,0x67,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,
    0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,
    0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x3b,
    0x0a,0x20,0x20,0x20,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,
    0x74,0x2e,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x66,
    0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x20,0x20,0x20,0x20,0x72,
    0x65,0x74,0x75,0x72,0x6e,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,
    0x75,0x74,0x3b,0x0a,0x7d,0x0a,0x00,
};
//
// #include <metal_stdlib>
// #include <simd/simd.h>
// 
// using namespace metal;
// 
// struct vs_params
// {
//     float4x4 mvp;
//     int3 tile;
// };
// 
// struct main0_out
// {
//     float2 uv [[user(locn0)]];
//     float4 gl_Position [[position]];
// };
// 
// struct main0_in
// {
//     float3 position [[attribute(0)]];
//     float2 uv0 [[attribute(1)]];
// };
// 
// #line 17 "texture.glsl"
// vertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _22 [[buffer(0)]])
// {
//     main0_out out = {};
// #line 17 "texture.glsl"
//     out.gl_Position = _22.mvp * float4(in.position.xy, 0.0, 1.0);
// #line 18 "texture.glsl"
// #line 19 "texture.glsl"
// #line 20 "texture.glsl"
//     float _64 = float(_22.tile.y);
//     float _80 = float(_22.tile.z);
//     out.uv = float2((float(_22.tile.x % _22.tile.y) / _64) + (in.uv0.x * (1.0 / _64)), (float(_22.tile.x / _22.tile.z) / _80) + (in.uv0.y / _80));
//     return out;
// }
// 
//
const vs_source_metal_macos = [849]u8 {
    0x23,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,0x20,0x3c,0x6d,0x65,0x74,0x61,0x6c,0x5f,
    0x73,0x74,0x64,0x6c,0x69,0x62,0x3e,0x0a,0x23,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,
    0x20,0x3c,0x73,0x69,0x6d,0x64,0x2f,0x73,0x69,0x6d,0x64,0x2e,0x68,0x3e,0x0a,0x0a,
    0x75,0x73,0x69,0x6e,0x67,0x20,0x6e,0x61,0x6d,0x65,0x73,0x70,0x61,0x63,0x65,0x20,
    0x6d,0x65,0x74,0x61,0x6c,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x76,
    0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x34,0x78,0x34,0x20,0x6d,0x76,0x70,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x69,0x6e,0x74,0x33,0x20,0x74,0x69,0x6c,0x65,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,
    0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x6f,0x75,0x74,
    0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,
    0x20,0x5b,0x5b,0x75,0x73,0x65,0x72,0x28,0x6c,0x6f,0x63,0x6e,0x30,0x29,0x5d,0x5d,
    0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x67,0x6c,0x5f,
    0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x5b,0x5b,0x70,0x6f,0x73,0x69,0x74,
    0x69,0x6f,0x6e,0x5d,0x5d,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,
    0x74,0x20,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x69,0x6e,0x0a,0x7b,0x0a,0x20,0x20,0x20,
    0x20,0x66,0x6c,0x6f,0x61,0x74,0x33,0x20,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,
    0x20,0x5b,0x5b,0x61,0x74,0x74,0x72,0x69,0x62,0x75,0x74,0x65,0x28,0x30,0x29,0x5d,
    0x5d,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,
    0x30,0x20,0x5b,0x5b,0x61,0x74,0x74,0x72,0x69,0x62,0x75,0x74,0x65,0x28,0x31,0x29,
    0x5d,0x5d,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x23,0x6c,0x69,0x6e,0x65,0x20,0x31,0x37,
    0x20,0x22,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x2e,0x67,0x6c,0x73,0x6c,0x22,0x0a,
    0x76,0x65,0x72,0x74,0x65,0x78,0x20,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x6f,0x75,0x74,
    0x20,0x6d,0x61,0x69,0x6e,0x30,0x28,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x69,0x6e,0x20,
    0x69,0x6e,0x20,0x5b,0x5b,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x5d,0x5d,0x2c,
    0x20,0x63,0x6f,0x6e,0x73,0x74,0x61,0x6e,0x74,0x20,0x76,0x73,0x5f,0x70,0x61,0x72,
    0x61,0x6d,0x73,0x26,0x20,0x5f,0x32,0x32,0x20,0x5b,0x5b,0x62,0x75,0x66,0x66,0x65,
    0x72,0x28,0x30,0x29,0x5d,0x5d,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x6d,0x61,
    0x69,0x6e,0x30,0x5f,0x6f,0x75,0x74,0x20,0x6f,0x75,0x74,0x20,0x3d,0x20,0x7b,0x7d,
    0x3b,0x0a,0x23,0x6c,0x69,0x6e,0x65,0x20,0x31,0x37,0x20,0x22,0x74,0x65,0x78,0x74,
    0x75,0x72,0x65,0x2e,0x67,0x6c,0x73,0x6c,0x22,0x0a,0x20,0x20,0x20,0x20,0x6f,0x75,
    0x74,0x2e,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,
    0x5f,0x32,0x32,0x2e,0x6d,0x76,0x70,0x20,0x2a,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,
    0x28,0x69,0x6e,0x2e,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x2e,0x78,0x79,0x2c,
    0x20,0x30,0x2e,0x30,0x2c,0x20,0x31,0x2e,0x30,0x29,0x3b,0x0a,0x23,0x6c,0x69,0x6e,
    0x65,0x20,0x31,0x38,0x20,0x22,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x2e,0x67,0x6c,
    0x73,0x6c,0x22,0x0a,0x23,0x6c,0x69,0x6e,0x65,0x20,0x31,0x39,0x20,0x22,0x74,0x65,
    0x78,0x74,0x75,0x72,0x65,0x2e,0x67,0x6c,0x73,0x6c,0x22,0x0a,0x23,0x6c,0x69,0x6e,
    0x65,0x20,0x32,0x30,0x20,0x22,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x2e,0x67,0x6c,
    0x73,0x6c,0x22,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x20,0x5f,0x36,
    0x34,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x28,0x5f,0x32,0x32,0x2e,0x74,0x69,
    0x6c,0x65,0x2e,0x79,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,
    0x20,0x5f,0x38,0x30,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x28,0x5f,0x32,0x32,
    0x2e,0x74,0x69,0x6c,0x65,0x2e,0x7a,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x6f,0x75,
    0x74,0x2e,0x75,0x76,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x28,0x28,0x66,
    0x6c,0x6f,0x61,0x74,0x28,0x5f,0x32,0x32,0x2e,0x74,0x69,0x6c,0x65,0x2e,0x78,0x20,
    0x25,0x20,0x5f,0x32,0x32,0x2e,0x74,0x69,0x6c,0x65,0x2e,0x79,0x29,0x20,0x2f,0x20,
    0x5f,0x36,0x34,0x29,0x20,0x2b,0x20,0x28,0x69,0x6e,0x2e,0x75,0x76,0x30,0x2e,0x78,
    0x20,0x2a,0x20,0x28,0x31,0x2e,0x30,0x20,0x2f,0x20,0x5f,0x36,0x34,0x29,0x29,0x2c,
    0x20,0x28,0x66,0x6c,0x6f,0x61,0x74,0x28,0x5f,0x32,0x32,0x2e,0x74,0x69,0x6c,0x65,
    0x2e,0x78,0x20,0x2f,0x20,0x5f,0x32,0x32,0x2e,0x74,0x69,0x6c,0x65,0x2e,0x7a,0x29,
    0x20,0x2f,0x20,0x5f,0x38,0x30,0x29,0x20,0x2b,0x20,0x28,0x69,0x6e,0x2e,0x75,0x76,
    0x30,0x2e,0x79,0x20,0x2f,0x20,0x5f,0x38,0x30,0x29,0x29,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x72,0x65,0x74,0x75,0x72,0x6e,0x20,0x6f,0x75,0x74,0x3b,0x0a,0x7d,0x0a,0x0a,
    0x00,
};
//
// #include <metal_stdlib>
// #include <simd/simd.h>
// 
// using namespace metal;
// 
// struct fs_params
// {
//     float3 color;
// };
// 
// struct main0_out
// {
//     float4 frag_color [[color(0)]];
// };
// 
// struct main0_in
// {
//     float2 uv [[user(locn0)]];
// };
// 
// #line 16 "texture.glsl"
// fragment main0_out main0(main0_in in [[stage_in]], constant fs_params& _25 [[buffer(0)]], texture2d<float> tex [[texture(0)]], sampler texSmplr [[sampler(0)]])
// {
//     main0_out out = {};
// #line 16 "texture.glsl"
//     out.frag_color = tex.sample(texSmplr, in.uv) * float4(_25.color, 1.0);
//     return out;
// }
// 
//
const fs_source_metal_macos = [554]u8 {
    0x23,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,0x20,0x3c,0x6d,0x65,0x74,0x61,0x6c,0x5f,
    0x73,0x74,0x64,0x6c,0x69,0x62,0x3e,0x0a,0x23,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,
    0x20,0x3c,0x73,0x69,0x6d,0x64,0x2f,0x73,0x69,0x6d,0x64,0x2e,0x68,0x3e,0x0a,0x0a,
    0x75,0x73,0x69,0x6e,0x67,0x20,0x6e,0x61,0x6d,0x65,0x73,0x70,0x61,0x63,0x65,0x20,
    0x6d,0x65,0x74,0x61,0x6c,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x66,
    0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x33,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x7d,0x3b,0x0a,
    0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x6f,0x75,
    0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x66,
    0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x5b,0x5b,0x63,0x6f,0x6c,0x6f,
    0x72,0x28,0x30,0x29,0x5d,0x5d,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,
    0x63,0x74,0x20,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x69,0x6e,0x0a,0x7b,0x0a,0x20,0x20,
    0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,0x20,0x5b,0x5b,0x75,0x73,
    0x65,0x72,0x28,0x6c,0x6f,0x63,0x6e,0x30,0x29,0x5d,0x5d,0x3b,0x0a,0x7d,0x3b,0x0a,
    0x0a,0x23,0x6c,0x69,0x6e,0x65,0x20,0x31,0x36,0x20,0x22,0x74,0x65,0x78,0x74,0x75,
    0x72,0x65,0x2e,0x67,0x6c,0x73,0x6c,0x22,0x0a,0x66,0x72,0x61,0x67,0x6d,0x65,0x6e,
    0x74,0x20,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x6f,0x75,0x74,0x20,0x6d,0x61,0x69,0x6e,
    0x30,0x28,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x69,0x6e,0x20,0x69,0x6e,0x20,0x5b,0x5b,
    0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x5d,0x5d,0x2c,0x20,0x63,0x6f,0x6e,0x73,
    0x74,0x61,0x6e,0x74,0x20,0x66,0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x26,0x20,
    0x5f,0x32,0x35,0x20,0x5b,0x5b,0x62,0x75,0x66,0x66,0x65,0x72,0x28,0x30,0x29,0x5d,
    0x5d,0x2c,0x20,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x32,0x64,0x3c,0x66,0x6c,0x6f,
    0x61,0x74,0x3e,0x20,0x74,0x65,0x78,0x20,0x5b,0x5b,0x74,0x65,0x78,0x74,0x75,0x72,
    0x65,0x28,0x30,0x29,0x5d,0x5d,0x2c,0x20,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x20,
    0x74,0x65,0x78,0x53,0x6d,0x70,0x6c,0x72,0x20,0x5b,0x5b,0x73,0x61,0x6d,0x70,0x6c,
    0x65,0x72,0x28,0x30,0x29,0x5d,0x5d,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x6d,
    0x61,0x69,0x6e,0x30,0x5f,0x6f,0x75,0x74,0x20,0x6f,0x75,0x74,0x20,0x3d,0x20,0x7b,
    0x7d,0x3b,0x0a,0x23,0x6c,0x69,0x6e,0x65,0x20,0x31,0x36,0x20,0x22,0x74,0x65,0x78,
    0x74,0x75,0x72,0x65,0x2e,0x67,0x6c,0x73,0x6c,0x22,0x0a,0x20,0x20,0x20,0x20,0x6f,
    0x75,0x74,0x2e,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,
    0x74,0x65,0x78,0x2e,0x73,0x61,0x6d,0x70,0x6c,0x65,0x28,0x74,0x65,0x78,0x53,0x6d,
    0x70,0x6c,0x72,0x2c,0x20,0x69,0x6e,0x2e,0x75,0x76,0x29,0x20,0x2a,0x20,0x66,0x6c,
    0x6f,0x61,0x74,0x34,0x28,0x5f,0x32,0x35,0x2e,0x63,0x6f,0x6c,0x6f,0x72,0x2c,0x20,
    0x31,0x2e,0x30,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x72,0x65,0x74,0x75,0x72,0x6e,
    0x20,0x6f,0x75,0x74,0x3b,0x0a,0x7d,0x0a,0x0a,0x00,
};
pub fn colorShaderDesc(backend: sg.Backend) sg.ShaderDesc {
    var desc: sg.ShaderDesc = .{};
    switch (backend) {
        .GLCORE33 => {
            desc.attrs[0].name = "position";
            desc.attrs[1].name = "uv0";
            desc.vs.source = &vs_source_glsl330;
            desc.vs.entry = "main";
            desc.vs.uniform_blocks[0].size = 80;
            desc.vs.uniform_blocks[0].layout = .STD140;
            desc.vs.uniform_blocks[0].uniforms[0].name = "_22.mvp";
            desc.vs.uniform_blocks[0].uniforms[0].type = .MAT4;
            desc.vs.uniform_blocks[0].uniforms[0].array_count = 1;
            desc.vs.uniform_blocks[0].uniforms[1].name = "_22.tile";
            desc.vs.uniform_blocks[0].uniforms[1].type = .INT3;
            desc.vs.uniform_blocks[0].uniforms[1].array_count = 1;
            desc.fs.source = &fs_source_glsl330;
            desc.fs.entry = "main";
            desc.fs.uniform_blocks[0].size = 16;
            desc.fs.uniform_blocks[0].layout = .STD140;
            desc.fs.uniform_blocks[0].uniforms[0].name = "fs_params";
            desc.fs.uniform_blocks[0].uniforms[0].type = .FLOAT4;
            desc.fs.uniform_blocks[0].uniforms[0].array_count = 1;
            desc.fs.images[0].name = "tex";
            desc.fs.images[0].image_type = ._2D;
            desc.fs.images[0].sampler_type = .FLOAT;
            desc.label = "color_shader";
        },
        .D3D11 => {
            desc.attrs[0].sem_name = "TEXCOORD";
            desc.attrs[0].sem_index = 0;
            desc.attrs[1].sem_name = "TEXCOORD";
            desc.attrs[1].sem_index = 1;
            desc.vs.source = &vs_source_hlsl4;
            desc.vs.d3d11_target = "vs_4_0";
            desc.vs.entry = "main";
            desc.vs.uniform_blocks[0].size = 80;
            desc.vs.uniform_blocks[0].layout = .STD140;
            desc.fs.source = &fs_source_hlsl4;
            desc.fs.d3d11_target = "ps_4_0";
            desc.fs.entry = "main";
            desc.fs.uniform_blocks[0].size = 16;
            desc.fs.uniform_blocks[0].layout = .STD140;
            desc.fs.images[0].name = "tex";
            desc.fs.images[0].image_type = ._2D;
            desc.fs.images[0].sampler_type = .FLOAT;
            desc.label = "color_shader";
        },
        .METAL_MACOS => {
            desc.vs.source = &vs_source_metal_macos;
            desc.vs.entry = "main0";
            desc.vs.uniform_blocks[0].size = 80;
            desc.vs.uniform_blocks[0].layout = .STD140;
            desc.fs.source = &fs_source_metal_macos;
            desc.fs.entry = "main0";
            desc.fs.uniform_blocks[0].size = 16;
            desc.fs.uniform_blocks[0].layout = .STD140;
            desc.fs.images[0].name = "tex";
            desc.fs.images[0].image_type = ._2D;
            desc.fs.images[0].sampler_type = .FLOAT;
            desc.label = "color_shader";
        },
        else => {},
    }
    return desc;
}
