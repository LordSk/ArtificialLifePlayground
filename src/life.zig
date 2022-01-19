const std   = @import("std");
const sg    = @import("sokol").gfx;
const sapp  = @import("sokol").app;
const sgapp = @import("sokol").app_gfx_glue;
const shd   = @import("shaders/shaders.zig");
const math  = @import("math.zig");
const content = @import("content.zig");
const assert = std.debug.assert;

const vec2 = math.Vec2;
const vec3 = math.Vec3;
const mat4 = math.Mat4;

const Array = std.ArrayList;

const MAX_TILE_BATCH: usize = 1024*1024;

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

const Renderer = struct
{
    const Self = @This();
    const GpuTileEntry = struct {
        gridx: u16,
        gridy: u16,
        tsi: u16, // tileset index
        tsw: u8, // tileset div width
        tsh: u8, // tileset div height
        color: u24
    };

    cam: Camera = .{},

    state: struct
    {
        bind: sg.Bindings = .{},
        pip: sg.Pipeline = .{},
        pipeTex: sg.Pipeline = .{},
        pipeTile: sg.Pipeline = .{},
        pass_action: sg.PassAction = .{},
    } = .{},

    tileBuffer: sg.Buffer,
    tileBatch: Array(GpuTileEntry),

    fn init(self: *Self) bool
    {
        comptime assert(@sizeOf(GpuTileEntry) == 12);

        const allocator = arena.allocator();

        self.tileBatch = Array(GpuTileEntry).initCapacity(allocator, MAX_TILE_BATCH) catch unreachable;

        // a vertex buffer
        const vertices = [_]f32 {
            // positions         uv
            0.0, 0.0, 0.0,     0, 0,
            1.0, 0.0, 0.0,     1, 0,
            1.0, 1.0, 0.0,     1, 1,
            0.0, 1.0, 0.0,     0, 1,
        };
        self.state.bind.vertex_buffers[0] = sg.makeBuffer(.{
            .data = sg.asRange(vertices)
        });

        // an index buffer
        const indices = [_] u16 { 0, 1, 2,  0, 2, 3 };
        self.state.bind.index_buffer = sg.makeBuffer(.{
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
            .cull_mode = .BACK,
        };
        pip_desc.layout.attrs[shd.color.ATTR_vs_position].format = .FLOAT3;
        pip_desc.layout.attrs[shd.color.ATTR_vs_color0].format = .FLOAT4;
        self.state.pip = sg.makePipeline(pip_desc);

        // a shader and pipeline state object
        pip_desc = .{
            .index_type = .UINT16,
            .shader = sg.makeShader(shd.texture.colorShaderDesc(sg.queryBackend())),
            .depth = .{
                .compare = .LESS_EQUAL,
                .write_enabled = true,
            },
            .cull_mode = .BACK
        };
        pip_desc.layout.attrs[shd.texture.ATTR_vs_position].format = .FLOAT3;
        pip_desc.layout.attrs[shd.texture.ATTR_vs_uv0].format = .FLOAT2;
        pip_desc.colors[0].blend = .{
            .enabled = true,
            .src_factor_rgb = .SRC_ALPHA,
            .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA
        };
        self.state.pipeTex = sg.makePipeline(pip_desc);

        // tile pipeline
        self.tileBuffer = sg.makeBuffer(.{
            .usage = .STREAM,
            .size = MAX_TILE_BATCH * @sizeOf(GpuTileEntry)
        });
        if(self.tileBuffer.id == 0) return false;
        self.state.bind.vertex_buffers[1] = self.tileBuffer;

        pip_desc = .{
            .index_type = .UINT16,
            .shader = sg.makeShader(shd.tile.colorShaderDesc(sg.queryBackend())),
            .depth = .{
                .compare = .LESS_EQUAL,
                .write_enabled = true,
            },
            .cull_mode = .BACK
        };
        pip_desc.layout.attrs[shd.tile.ATTR_vs_vert_pos].format = .FLOAT3;
        pip_desc.layout.attrs[shd.tile.ATTR_vs_vert_uv].format = .FLOAT2;
        // NOTE how the vertex layout is setup for instancing, with the instancing
        // data provided by buffer-slot 1:
        pip_desc.layout.buffers[1].step_func = .PER_INSTANCE;
        pip_desc.layout.attrs[shd.tile.ATTR_vs_tile] = .{ .format = .FLOAT3, .buffer_index = 1 }; // instance positions

        pip_desc.colors[0].blend = .{
            .enabled = true,
            .src_factor_rgb = .SRC_ALPHA,
            .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA
        };

        self.state.pipeTile = sg.makePipeline(pip_desc);

        // clear to grey
        self.state.pass_action.colors[0] = .{ .action=.CLEAR, .value=.{ .r=0.2, .g=0.2, .b=0.2, .a=1 } };
        return true;
    }

    fn push(self: *Self, imgID: content.ImageID, gridx: u16, gridy: u16, color: u24) void
    {
        const info = content.GetGpuImageTileInfo(imgID);
        self.tileBatch.append(.{
            .gridx = gridx,
            .gridy = gridy,
            .tsi = info.index,
            .tsw = info.divw,
            .tsh = info.divh,
            .color = color
        }) catch unreachable;
    }

    fn render(self: *Self) void
    {
        const hw = sapp.widthf() / 2.0;
        const hh = sapp.heightf() / 2.0;

        const left = (-hw) * 1.0/self.cam.zoom + self.cam.pos.x;
        const right = (hw) * 1.0/self.cam.zoom + self.cam.pos.x;
        const bottom = (hh) * 1.0/self.cam.zoom + self.cam.pos.y;
        const top = (-hh) * 1.0/self.cam.zoom + self.cam.pos.y;

        const view = mat4.ortho(left, right, bottom, top, -10.0, 10.0);

        sg.updateBuffer(self.state.bind.vertex_buffers[1], sg.asRange(self.tileBatch.items));

        sg.beginDefaultPass(self.state.pass_action, sapp.width(), sapp.height());
        sg.applyPipeline(self.state.pipeTile);
        
        self.state.bind.fs_images[0] = content.GetGpuImage(.{ .img = 0, .tile = 0 });
        sg.applyBindings(self.state.bind);

        const vs_params: shd.tile.VsParams = .{
            .vp = view,
        };

        sg.applyUniforms(.VS, shd.tile.SLOT_vs_params, sg.asRange(vs_params));
        sg.draw(0, 6, @intCast(u32, self.tileBatch.items.len));

        sg.endPass();
        sg.commit();
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
    sapp.lockMouse(false); // show cursor

    sg.setup(.{
        .context = sgapp.context()
    });

    if(!rdr.init()) {
        log("ERROR: Could not init renderer");
        sapp.quit();
        return;
    }

    if(!content.LoadImages()) {
        log("ERROR: Could not load all images");
        sapp.quit();
        return;
    }

    var y: u16 = 0;
    while(y < 1024): (y += 1) {
        var x: u16 = 0;
        while(x < 1024): (x += 1) {
            const r = randi(0, 6);

            const img = switch(r) {
                0 => "rock",
                1 => "plant1",
                2 => "plant2",
                3 => "plant3",
                4 => "cow",
                5 => "zap",
                else => continue
            };

            rdr.push(content.IMG(img), x, y, @intCast(u24, randi(0, 0xFFFFFF)));
        }
    }

    logf("render commands = {any}", .{ rdr.tileBatch.items.len });
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

    rdr.render();
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
        .swap_interval = 0
    });
}