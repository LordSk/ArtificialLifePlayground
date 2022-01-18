const std   = @import("std");
const sg    = @import("sokol").gfx;
const sapp  = @import("sokol").app;
const sgapp = @import("sokol").app_gfx_glue;
const shd   = @import("shaders/shaders.zig");
const math  = @import("math.zig");
const content = @import("content.zig");

const vec2 = math.Vec2;
const vec3 = math.Vec3;
const mat4 = math.Mat4;

const Array = std.ArrayList;

fn logf(comptime format: []const u8, args: anytype) void
{
    const stdout = std.io.getStdOut().writer();
    stdout.print(format ++ "\n", args) catch unreachable;
}

fn log(comptime format: []const u8) void
{
    const stdout = std.io.getStdOut().writer();
    stdout.print(format ++ "\n", .{}) catch unreachable;
}

const Camera = struct {
    pos: vec2 = vec2.zero(),
    zoom: f32 = 1.0,
};

const RenderCommandSprite = struct {
    pos: vec2,
    size: vec2 = .{ .x = 1.0, .y = 1.0 },
    rot: f32 = 0,
    color: u32 = 0xFFFFFFFF,
    imgID: content.ImageID,
};

const Renderer = struct
{
    const Self = @This();

    cam: Camera = .{},
    queueSprite: Array(RenderCommandSprite),

    fn Push(self: *Self, cmd: RenderCommandSprite) void
    {
        self.queueSprite.append(cmd) catch unreachable;
    }
};

const Game = struct
{
    input: struct
    {
        zoom: f32 = 1.0,
        grabMove: bool = false,
        mouseMove: vec2 = vec2.new(0, 0)
    } = .{},
};

var rdr: Renderer = undefined;
var game: Game = .{};

const state = struct
{
    var bind: sg.Bindings = .{};
    var pip: sg.Pipeline = .{};
    var pipeTex: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};
};

var arena: std.heap.ArenaAllocator = undefined; // initialized in main

var xorshift32_state: u32 = 0x1234;

fn xorshift32() u32
{
    var x = xorshift32_state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    xorshift32_state = x;
    return x;
}

inline fn randi(min: i32, max: i32) i32
{
    const mod = @intCast(u32, max - min + 1);
    return min + @intCast(i32, xorshift32() % mod);
}

export fn init() void
{
    const allocator = arena.allocator();

    rdr = .{
        .queueSprite = Array(RenderCommandSprite).initCapacity(allocator, 10000) catch unreachable
    };

    sapp.lockMouse(false); // show cursor

    sg.setup(.{
        .context = sgapp.context()
    });
    
     // a vertex buffer
    const vertices = [_]f32 {
        // positions         uv
        0.0, 1.0, 0.0,     0, 1,
        1.0, 1.0, 0.0,     1, 1,
        1.0, 0.0, 0.0,     1, 0,
        0.0, 0.0, 0.0,     0, 0
    };
    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(vertices)
    });

    // an index buffer
    const indices = [_] u16 { 0, 1, 2,  0, 2, 3 };
    state.bind.index_buffer = sg.makeBuffer(.{
        .type = .INDEXBUFFER,
        .data = sg.asRange(indices)
    });

    // a shader and pipeline state object
    var pip_desc: sg.PipelineDesc = .{
        .index_type = .UINT16,
        .shader = sg.makeShader(shd.color.colorShaderDesc(sg.queryBackend())),
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },
        .cull_mode = .NONE,
    };
    pip_desc.layout.attrs[shd.color.ATTR_vs_position].format = .FLOAT3;
    pip_desc.layout.attrs[shd.color.ATTR_vs_color0].format = .FLOAT4;
    state.pip = sg.makePipeline(pip_desc);

    // a shader and pipeline state object
    pip_desc = .{
        .index_type = .UINT16,
        .shader = sg.makeShader(shd.texture.colorShaderDesc(sg.queryBackend())),
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },
        .cull_mode = .NONE
    };
    pip_desc.layout.attrs[shd.texture.ATTR_vs_position].format = .FLOAT3;
    pip_desc.layout.attrs[shd.texture.ATTR_vs_uv0].format = .FLOAT2;
    pip_desc.colors[0].blend = .{
        .enabled = true,
        .src_factor_rgb = .SRC_ALPHA,
        .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA
    };
    state.pipeTex = sg.makePipeline(pip_desc);

    // clear to grey
    state.pass_action.colors[0] = .{ .action=.CLEAR, .value=.{ .r=0.2, .g=0.2, .b=0.2, .a=1 } };

    //
    const loaded = content.LoadImages();
    if(!loaded) {
        log("ERROR: Could not load all images\n");
        sapp.quit();
        return;
    }

    rdr.Push(.{
        .pos = .{ .x = 0.0, .y =  0.0 },
        .imgID = comptime content.IMG("plant2"),
    });
    
    var y: f32 = 0.0;
    while(y < 1000): (y += 1) {
        var x: f32 = 0.0;
        while(x < 1000): (x += 1) {
            const r = randi(0, 100);

            const img = switch(r) {
                0 => "rock",
                1 => "plant1",
                2 => "plant2",
                3 => "plant3",
                4 => "cow",
                5 => "zap",
                else => continue
            };

            rdr.Push(.{
                .pos = .{ .x = x, .y = y },
                .imgID = content.IMG(img),
            });
        }
    }

    logf("render commands = {any}", .{ rdr.queueSprite.items.len });
}

export fn frame() void
{
    // zoom over many frames (smooth zoom)
    // TODO: make this better
    if(rdr.cam.zoom != game.input.zoom) {
        const delta = game.input.zoom - rdr.cam.zoom;
        if(std.math.fabs(delta) < 0.000001) {
            rdr.cam.zoom = game.input.zoom;
        }
        else {
            rdr.cam.zoom += delta / 10.0;
        }
    }

    if(game.input.grabMove) {
        rdr.cam.pos.x += -game.input.mouseMove.x/rdr.cam.zoom;
        rdr.cam.pos.y += -game.input.mouseMove.y/rdr.cam.zoom;
    }
    game.input.mouseMove = vec2.new(0, 0);

    const hw = sapp.widthf() / 2.0;
    const hh = sapp.heightf() / 2.0;

    const left = (-hw) * 1.0/rdr.cam.zoom + rdr.cam.pos.x;
    const right = (hw) * 1.0/rdr.cam.zoom + rdr.cam.pos.x;
    const bottom = (hh) * 1.0/rdr.cam.zoom + rdr.cam.pos.y;
    const top = (-hh) * 1.0/rdr.cam.zoom + rdr.cam.pos.y;

    sg.beginDefaultPass(state.pass_action, sapp.width(), sapp.height());
    sg.applyPipeline(state.pipeTex);

    const view = mat4.ortho(left, right, bottom, top, -10.0, 10.0);

    for(rdr.queueSprite.items) |value| {
        const vs_params: shd.texture.VsParams = .{
            .mvp = mat4.mul(view,
                mat4.mul(mat4.translate(vec3.new(value.pos.x, value.pos.y, 0)), mat4.scale(vec3.new(value.size.x, value.size.y, 1)))
            ),
            .tile = content.GetGpuImageTileInfo(value.imgID)
        };

        const fs_params: shd.texture.FsParams = .{
            .color = .{1, 1, 1}
        };

        state.bind.fs_images[0] = content.GetGpuImage(value.imgID);

        sg.applyBindings(state.bind);
        sg.applyUniforms(.VS, shd.texture.SLOT_vs_params, sg.asRange(vs_params));
        sg.applyUniforms(.FS, shd.texture.SLOT_fs_params, sg.asRange(fs_params));
        sg.draw(0, 6, 1);
    }
   
    sg.endPass();
    sg.commit();
}

export fn cleanup() void
{
    sg.shutdown();
}

export fn input(ev: ?*const sapp.Event) void
{
    const event = ev.?;
    if(event.type == .KEY_DOWN) {
        if(event.key_code == .ESCAPE) {
            sapp.quit();
        }
        if(event.key_code == .F1) {
            //reset Camera
            game.input.zoom = 1.0;
            rdr.cam.pos = vec2.new(0, 0);
        }
    }
    else if(event.type == .MOUSE_SCROLL) {
        if(event.scroll_y > 0.0) {
            game.input.zoom *= 1.0 + event.scroll_y * 0.1;
        }
        else {
            game.input.zoom /= 1.0 + -event.scroll_y * 0.1;
        }
    }
    else if(event.type == .MOUSE_UP) {
        if(event.mouse_button == .MIDDLE) {
            game.input.grabMove = false;
        }
    }
    else if(event.type == .MOUSE_DOWN) {
        if(event.mouse_button == .MIDDLE) {
            game.input.grabMove = true;
        }
    }
    else if(event.type == .MOUSE_MOVE) {
        game.input.mouseMove.x += event.mouse_dx;
        game.input.mouseMove.y += event.mouse_dy;
    }
}

pub fn main() void
{
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = input,
        .width = 1920,
        .height = 1080,
        .window_title = "Life",
    });
}