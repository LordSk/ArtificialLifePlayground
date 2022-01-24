const sapp = @import("app.zig");

// sokol_imgui.h
const PixelFormat = enum(u32) {
    _SG_PIXELFORMAT_DEFAULT,    // value 0 reserved for default-init
    SG_PIXELFORMAT_NONE,

    SG_PIXELFORMAT_R8,
    SG_PIXELFORMAT_R8SN,
    SG_PIXELFORMAT_R8UI,
    SG_PIXELFORMAT_R8SI,

    SG_PIXELFORMAT_R16,
    SG_PIXELFORMAT_R16SN,
    SG_PIXELFORMAT_R16UI,
    SG_PIXELFORMAT_R16SI,
    SG_PIXELFORMAT_R16F,
    SG_PIXELFORMAT_RG8,
    SG_PIXELFORMAT_RG8SN,
    SG_PIXELFORMAT_RG8UI,
    SG_PIXELFORMAT_RG8SI,

    SG_PIXELFORMAT_R32UI,
    SG_PIXELFORMAT_R32SI,
    SG_PIXELFORMAT_R32F,
    SG_PIXELFORMAT_RG16,
    SG_PIXELFORMAT_RG16SN,
    SG_PIXELFORMAT_RG16UI,
    SG_PIXELFORMAT_RG16SI,
    SG_PIXELFORMAT_RG16F,
    SG_PIXELFORMAT_RGBA8,
    SG_PIXELFORMAT_RGBA8SN,
    SG_PIXELFORMAT_RGBA8UI,
    SG_PIXELFORMAT_RGBA8SI,
    SG_PIXELFORMAT_BGRA8,
    SG_PIXELFORMAT_RGB10A2,
    SG_PIXELFORMAT_RG11B10F,

    SG_PIXELFORMAT_RG32UI,
    SG_PIXELFORMAT_RG32SI,
    SG_PIXELFORMAT_RG32F,
    SG_PIXELFORMAT_RGBA16,
    SG_PIXELFORMAT_RGBA16SN,
    SG_PIXELFORMAT_RGBA16UI,
    SG_PIXELFORMAT_RGBA16SI,
    SG_PIXELFORMAT_RGBA16F,

    SG_PIXELFORMAT_RGBA32UI,
    SG_PIXELFORMAT_RGBA32SI,
    SG_PIXELFORMAT_RGBA32F,

    SG_PIXELFORMAT_DEPTH,
    SG_PIXELFORMAT_DEPTH_STENCIL,

    SG_PIXELFORMAT_BC1_RGBA,
    SG_PIXELFORMAT_BC2_RGBA,
    SG_PIXELFORMAT_BC3_RGBA,
    SG_PIXELFORMAT_BC4_R,
    SG_PIXELFORMAT_BC4_RSN,
    SG_PIXELFORMAT_BC5_RG,
    SG_PIXELFORMAT_BC5_RGSN,
    SG_PIXELFORMAT_BC6H_RGBF,
    SG_PIXELFORMAT_BC6H_RGBUF,
    SG_PIXELFORMAT_BC7_RGBA,
    SG_PIXELFORMAT_PVRTC_RGB_2BPP,
    SG_PIXELFORMAT_PVRTC_RGB_4BPP,
    SG_PIXELFORMAT_PVRTC_RGBA_2BPP,
    SG_PIXELFORMAT_PVRTC_RGBA_4BPP,
    SG_PIXELFORMAT_ETC2_RGB8,
    SG_PIXELFORMAT_ETC2_RGB8A1,
    SG_PIXELFORMAT_ETC2_RGBA8,
    SG_PIXELFORMAT_ETC2_RG11,
    SG_PIXELFORMAT_ETC2_RG11SN,

    _SG_PIXELFORMAT_NUM,
    _SG_PIXELFORMAT_FORCE_U32 = 0x7FFFFFFF
};

const Desc = extern struct {
    max_vertices: i32 = 0,
    color_format: PixelFormat = ._SG_PIXELFORMAT_DEFAULT,
    depth_format: PixelFormat = ._SG_PIXELFORMAT_DEFAULT,
    sample_count: i32 = 1,
    ini_filename: [*:0]const u8 = "imgui.ini",
    no_default_font: bool = false,
    disable_hotkeys: bool = false   // don't let ImGui handle Ctrl-A,C,V,X,Y,Z
};

const FrameDesc = extern struct {
    width: i32,
    height: i32,
    delta_time: f64,
    dpi_scale: f32,
};

pub extern fn simgui_setup([*c]const Desc) void;
pub extern fn simgui_new_frame([*c]const FrameDesc) void;
pub extern fn simgui_render() void;
pub extern fn simgui_handle_event([*c]const sapp.Event) bool;

pub fn setup(desc: Desc) void {
    simgui_setup(&desc);
}
pub fn newFrame(desc: FrameDesc) void {
    simgui_new_frame(&desc);
}
pub fn render() void {
    simgui_render();
}
pub fn handleEvent(ev: ?*const sapp.Event) bool {
    return simgui_handle_event(ev);
}

// cimgui.h
const ImGuiWindowFlags = i32;
const ImGuiSliderFlags = i32;
const ImVec2 = extern struct {
    x: f32,
    y: f32
};

pub extern fn igShowDemoWindow(p_open: [*c]bool) void;
pub extern fn igBegin(name: [*:0]const u8, p_open: [*c]bool, flags: ImGuiWindowFlags) bool;
pub extern fn igEnd() void;
pub extern fn igButton(label: [*:0]const u8, size: ImVec2) bool;
pub extern fn igSliderInt(label: [*:0]const u8, v: [*c]i32, v_min: i32, v_max: i32, format: ?[*:0]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igCheckbox(label: [*:0]const u8, v: *bool) bool;

pub fn showDemoWindow() void
{
    igShowDemoWindow(null);
}

pub fn begin(name: [*:0]const u8) bool
{
    return igBegin(name, null, 0x0);
}

pub fn end() void
{
    return igEnd();
}

pub fn button(label: [*:0]const u8) bool
{
    return igButton(label, .{ .x=0, .y=0 });
}

pub fn sliderInt(label: [*:0]const u8, val: *i32, v_min: i32, v_max: i32) bool
{
    return igSliderInt(label, val, v_min, v_max, null, 0x0);
}

pub fn checkbox(label: [*:0]const u8, v: *bool) bool
{
    return igCheckbox(label, v);
}