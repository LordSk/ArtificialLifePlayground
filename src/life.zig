const std   = @import("std");
const sg    = @import("sokol").gfx;
const sapp  = @import("sokol").app;
const sgapp = @import("sokol").app_gfx_glue;
const imgui = @import("sokol").imgui;
const shd   = @import("shaders/shaders.zig");
const math  = @import("math.zig");
const content = @import("content.zig");
const assert = std.debug.assert;

const vec2 = math.Vec2;
const vec3 = math.Vec3;
const mat4 = math.Mat4;

const Array = std.ArrayList;

const futex_wait = std.Thread.Futex.wait;
const futex_wake = std.Thread.Futex.wake;

const WORLD_WIDTH = 1024;
const WORLD_HEIGHT = 1024;
const MAX_TILE_BATCH: usize = 1024*1024;
const MAX_DBGDRAW_BATCH: usize = 8192;
const MAX_STEP_SPEED = 100;
const TILE_SIZE = 32;

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

fn assertSize(comptime t: type, size: usize) void
{
    if(@sizeOf(t) != size) {
        @compileLog(@sizeOf(t));
        @compileError("size does not match");
    }
}

fn hash32(data: []const u8) u32
{
    var h: u32 = 0x811c9dc5;
    for(data) |d| {
        h ^= d;
        h *%= 0x01000193;
    }
    return h;
}

inline fn CU4(r: f32, g: f32, b: f32, a: f32) u32
{
    const ret: u32 = (@floatToInt(u32, r * 255.0)) |
        (@floatToInt(u32, g * 255.0) << 8) |
        (@floatToInt(u32, b * 255.0) << 16) |
        (@floatToInt(u32, a * 255.0) << 24);
    return ret;
}

inline fn enumCount(comptime e: type) usize
{
    return @typeInfo(e).Enum.fields.len;
}
inline fn enumFields(comptime e: type) []const std.builtin.TypeInfo.EnumField
{
    return @typeInfo(e).Enum.fields;
}

comptime {
    assertSize(Renderer.GpuTileEntry, 12);
    assertSize(Renderer.GpuDbgDrawEntry, 28);
}

const Renderer = struct
{
    const Self = @This();

    const GpuTileEntry = packed struct {
        gridx: u16,
        gridy: u16,
        tsi: u8, // tileset index
        tsw: u8, // tileset div width
        tsh: u8, // tileset div height
        scale: u8,
        // rot: u8, -> packed struct size is bugged
        // color: u24 -> packed struct size is bugged
        rot_color: u32
    };

    const GpuDbgDrawEntry = packed struct {
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        rot: f32,
        color: u32,
        z: f32
    };

    const Layer = enum(i32) {
        BACK = -1,
        GAME = 0,
        FRONT = 1
    };

    cam: Camera = .{},

    bindTiles: sg.Bindings = .{},
    bindDbgDraw: sg.Bindings = .{},
    pipeDbgDraw: sg.Pipeline = .{},
    pipeTex: sg.Pipeline = .{},
    pipeTile: sg.Pipeline = .{},
    pass_action: sg.PassAction = .{},

    tileBatch: Array(GpuTileEntry) = undefined,
    dbgDrawBatch: Array(GpuDbgDrawEntry) = undefined,
    orderedDbgDrawBatch: Array(GpuDbgDrawEntry) = undefined,

    gpuTileBuffer: sg.Buffer = .{},
    gpuDbgDrawBuffer: sg.Buffer = .{},
    countDbgDraw: [enumCount(Layer)]u32 = [_]u32{0} ** enumCount(Layer),

    fn init(self: *Self) bool
    {
        sg.setup(.{
            .context = sgapp.context()
        });

        const allocator = arena.allocator();

        self.tileBatch = Array(GpuTileEntry).initCapacity(allocator, MAX_TILE_BATCH) catch unreachable;
        self.dbgDrawBatch = Array(GpuDbgDrawEntry).initCapacity(allocator, MAX_DBGDRAW_BATCH) catch unreachable;
        self.orderedDbgDrawBatch = Array(GpuDbgDrawEntry).initCapacity(allocator, MAX_DBGDRAW_BATCH) catch unreachable;

        // centered quad
        const vertQuadCentered = [_]f32 {
            // positions         uv
            -0.5, -0.5, 0.0,     0, 0,
             0.5, -0.5, 0.0,     1, 0,
             0.5,  0.5, 0.0,     1, 1,
            -0.5,  0.5, 0.0,     0, 1,
        };
        // quad
        const vertQuad = [_]f32 {
            // positions
            0.0, 0.0, 0.0,
            1.0, 0.0, 0.0,
            1.0, 1.0, 0.0,
            0.0, 1.0, 0.0,
        };
        self.bindTiles.vertex_buffers[0] = sg.makeBuffer(.{
            .data = sg.asRange(vertQuadCentered)
        });
        self.bindDbgDraw.vertex_buffers[0] = sg.makeBuffer(.{
            .data = sg.asRange(vertQuad)
        });

        // an index buffer
        const indices = [_] u16 { 0, 1, 2,  0, 2, 3 };
        self.bindTiles.index_buffer = sg.makeBuffer(.{
            .type = .INDEXBUFFER,
            .data = sg.asRange(indices)
        });
        self.bindDbgDraw.index_buffer = sg.makeBuffer(.{
            .type = .INDEXBUFFER,
            .data = sg.asRange(indices)
        });

        // debug draw pipeline
        self.gpuDbgDrawBuffer = sg.makeBuffer(.{
            .usage = .STREAM,
            .size = MAX_DBGDRAW_BATCH * @sizeOf(GpuDbgDrawEntry)
        });
        if(self.gpuDbgDrawBuffer.id == 0) return false;
        self.bindDbgDraw.vertex_buffers[1] = self.gpuDbgDrawBuffer;

        var pip_desc: sg.PipelineDesc = .{
            .index_type = .UINT16,
            .shader = sg.makeShader(shd.dbgDraw.colorShaderDesc(sg.queryBackend())),
            .depth = .{
                .compare = .LESS_EQUAL,
                .write_enabled = true,
            },
            .cull_mode = .BACK,
        };
        pip_desc.layout.attrs[shd.dbgDraw.ATTR_vs_vert_pos].format = .FLOAT3;
        // instanced
        pip_desc.layout.buffers[1].stride = @sizeOf(GpuDbgDrawEntry);
        pip_desc.layout.buffers[1].step_func = .PER_INSTANCE;
        pip_desc.layout.attrs[shd.dbgDraw.ATTR_vs_inst_pos_size] = .{ .format = .FLOAT4, .buffer_index = 1 };
        pip_desc.layout.attrs[shd.dbgDraw.ATTR_vs_inst_rcz] = .{ .format = .FLOAT3, .buffer_index = 1, .offset = 16 };

        pip_desc.colors[0].blend = .{
            .enabled = true,
            .src_factor_rgb = .SRC_ALPHA,
            .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA
        };

        self.pipeDbgDraw = sg.makePipeline(pip_desc);

        // tile pipeline
        self.gpuTileBuffer = sg.makeBuffer(.{
            .usage = .STREAM,
            .size = MAX_TILE_BATCH * @sizeOf(GpuTileEntry)
        });
        if(self.gpuTileBuffer.id == 0) return false;
        self.bindTiles.vertex_buffers[1] = self.gpuTileBuffer;

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
        // instanced
        pip_desc.layout.buffers[1].step_func = .PER_INSTANCE;
        pip_desc.layout.attrs[shd.tile.ATTR_vs_tile] = .{ .format = .FLOAT3, .buffer_index = 1 }; // instance positions

        pip_desc.colors[0].blend = .{
            .enabled = true,
            .src_factor_rgb = .SRC_ALPHA,
            .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA
        };

        self.pipeTile = sg.makePipeline(pip_desc);

        // clear to grey
        self.pass_action.colors[0] = .{ .action=.CLEAR, .value=.{ .r=0.2, .g=0.2, .b=0.2, .a=1 } };
        return true;
    }

    fn drawTile(self: *Self, imgID: content.ImageID, gridx: u16, gridy: u16, scale: u8, rot: u8, color: u24) void
    {
        const info = content.GetGpuImageTileInfo(imgID);
        self.tileBatch.append(.{
            .gridx = gridx,
            .gridy = gridy,
            .tsi = info.index,
            .tsw = info.divw,
            .tsh = info.divh,
            .scale = scale,
            .rot_color = @intCast(u32, rot) | (@intCast(u32, color) << 8),
        }) catch unreachable;
    }

    fn drawDbgQuad(self: *Self, x: f32, y: f32, z: Layer, w: f32, h: f32, rot: f32, color: u32) void
    {
        self.dbgDrawBatch.append(.{
            .x = x,
            .y = y,
            .w = w,
            .h = h,
            .rot = rot,
            .color = color,
            .z = @intToFloat(f32, @enumToInt(z)),
        }) catch unreachable;
    }

    fn drawLine(self: *Self, x1: f32, y1: f32, x2: f32, y2: f32, z: Layer, thickness: f32, color: u32) void
    {
        const rot = std.math.atan2(f32, y2 - y1, x2 - x1);
        const len = vec2.len(.{ .x = x2 - x1, .y = y2 - y1 });

        self.dbgDrawBatch.append(.{
            .x = x1,
            .y = y1,
            .w = len,
            .h = thickness,
            .rot = rot,
            .color = color,
            .z = @intToFloat(f32, @enumToInt(z)),
        }) catch unreachable;
    }

    fn renderLayer(self: *Self, comptime layer: Layer, view: mat4) void
    {
        const lyID = comptime for(enumFields(Layer)) |L, i| {
            if(@intToEnum(Layer, L.value) == layer) break i;
        } else unreachable;

        if(self.orderedDbgDrawBatch.items.len > 0) {
            var offset: u32 = 0;
            var i: usize = 0;
            while(i < lyID): (i += 1) {
                offset += self.countDbgDraw[i];
            }
            self.bindDbgDraw.vertex_buffer_offsets[1] = @intCast(i32, offset * @sizeOf(GpuDbgDrawEntry));
            
            sg.applyPipeline(self.pipeDbgDraw);
            sg.applyBindings(self.bindDbgDraw);

            const vs_params: shd.dbgDraw.VsParams = .{
                .vp = view,
            };

            sg.applyUniforms(.VS, shd.dbgDraw.SLOT_vs_params, sg.asRange(vs_params));
            sg.draw(0, 6, @intCast(u32, self.countDbgDraw[lyID]));
        }
    }

    fn render(self: *Self) void
    {
        const hw = sapp.widthf() / 2.0;
        const hh = sapp.heightf() / 2.0;

        const left = (-hw) * 1.0/self.cam.zoom;
        const right = (hw) * 1.0/self.cam.zoom;
        const bottom = (hh) * 1.0/self.cam.zoom;
        const top = (-hh) * 1.0/self.cam.zoom;

        const proj = mat4.ortho(left, right, bottom, top, -100.0, 100.0);
        const view = mat4.lookat(
            vec3.new(self.cam.pos.x, self.cam.pos.y, 10),
            vec3.new(self.cam.pos.x, self.cam.pos.y, 0),
            vec3.new(0, 1, 0)
        );

        const vp = mat4.mul(proj, view);

        sg.beginDefaultPass(self.pass_action, sapp.width(), sapp.height());

        self.orderedDbgDrawBatch.clearRetainingCapacity();
        self.countDbgDraw = [_]u32{0} ** enumCount(Layer);
        inline for(enumFields(Layer)) |L, i| {
            for(self.dbgDrawBatch.items) |it| {
                const l = @floatToInt(i32, it.z);
                if(l == L.value) {
                    self.orderedDbgDrawBatch.append(it) catch unreachable;
                    self.countDbgDraw[i] += 1;
                }
            }
        }

        sg.updateBuffer(self.bindDbgDraw.vertex_buffers[1], sg.asRange(self.orderedDbgDrawBatch.items));

        self.renderLayer(.BACK, vp);

        if(self.tileBatch.items.len > 0) {
            sg.applyPipeline(self.pipeTile);
            sg.updateBuffer(self.bindTiles.vertex_buffers[1], sg.asRange(self.tileBatch.items));

            self.bindTiles.fs_images[0] = content.GetGpuImage(.{ .img = 0, .tile = 0 });
            sg.applyBindings(self.bindTiles);

            const vs_params: shd.tile.VsParams = .{
                .vp = vp,
            };

            sg.applyUniforms(.VS, shd.tile.SLOT_vs_params, sg.asRange(vs_params));
            sg.draw(0, 6, @intCast(u32, self.tileBatch.items.len));
        }

        self.renderLayer(.GAME, vp);
        self.renderLayer(.FRONT, vp);

        imgui.render();

        sg.endPass();
        sg.commit();

        self.tileBatch.clearRetainingCapacity();
        self.dbgDrawBatch.clearRetainingCapacity();
    }
};

const EntityType = enum(u8) {
    EMPTY,
    WALL,
    ZAP,
    ROCK,
    PLANT,
    COW
};

const Game = struct
{
    const Self = @This();

    const Tile = struct {
        type: EntityType,
        energy: u8
    };

    running: bool = true,

    input: struct
    {
        zoom: f32 = 1.0,
        grabMove: bool = false,
        mouseMove: vec2 = vec2.new(0, 0),
        mousePos: vec2 = vec2.new(0, 0)
    } = .{},

    world: [WORLD_WIDTH][WORLD_HEIGHT]Tile = undefined,

    pulse: std.atomic.Atomic(u32) = .{ .value = 0 },
    speed: i32 = 80,
    dontWaitToStep: bool = false,

    fn init(self: *Self) void
    {
        self.reset();
        _ = std.Thread.spawn(.{}, thread, .{ self }) catch unreachable;
    }

    fn reset(self: *Self) void
    {
        for(self.world) |*col| {
            for(col) |*it| {
                it.* = .{
                    .type = .EMPTY,
                    .energy = 0
                };
            }
        }
    }

    fn step(self: *Self) void
    {
        for(self.world) |*col, y| {
            for(col) |*it, x| {
                switch(it.type) {
                    .PLANT => {
                        it.energy += 5;
                        if(it.energy > 100) it.energy = 100;

                        if(it.energy > 50 and randi(0, 10) == 0) {
                            const dx = @intCast(i32, x) + randi(-1, 1);
                            const dy = @intCast(i32, y) + randi(-1, 1);

                            if(dx < 0 or dx >= WORLD_WIDTH) continue;
                            if(dy < 0 or dy >= WORLD_HEIGHT) continue;

                            const udx = @intCast(usize, dx);
                            const udy = @intCast(usize, dy);

                            if(self.world[udy][udx].type != .EMPTY) continue;

                            it.energy -= @intCast(u8, randi(35, 50));

                            self.world[udy][udx] = .{
                                .type = .PLANT,
                                .energy = 20
                            };
                        }
                    },

                    .ZAP => {
                        self.world[y][x] = .{
                            .type = .EMPTY,
                            .energy = 0
                        };
                    },

                    else => continue
                }
            }
        }

        const zapCount = randi(0, 512);
        var z: i32 = 0;
        while(z < zapCount): (z += 1) {
            const ux = @intCast(usize, randi(0, WORLD_WIDTH-1));
            const uy = @intCast(usize, randi(0, WORLD_HEIGHT-1));

            self.world[uy][ux] = .{
                .type = .ZAP,
                .energy = 0
            };
        }
    }

    fn thread(self: *Self) void
    {
        while(self.running) {
            if(!self.dontWaitToStep) {
                futex_wait(&self.pulse, 0, null) catch unreachable;
            }
            self.step();
        }
    }

    fn draw(self: Self) void
    {
        for(self.world) |col, y| {
            for(col) |it, x| {
                const img = switch(it.type) {
                    .EMPTY => continue,
                    .WALL => continue,
                    .ZAP => "zap",
                    .ROCK => "rock",
                    .PLANT => "plant",
                    .COW => "cow",
                };

                const scale: u8 = switch(it.type) {
                    .PLANT => @floatToInt(u8, @intToFloat(f32, std.math.min(it.energy, 100)) / 100.0 * 255.0),
                    else => 255,
                };

                const rot: u8 = switch(it.type) {
                    .PLANT => @truncate(u8, hash32(std.mem.asBytes(&.{x,y}))),
                    else => 0,
                };

                rdr.drawTile(content.IMG(img), @intCast(u16, x), @intCast(u16, y), scale, rot, 0xFFFFFF);
            }
        }

        // draw grid
        if(rdr.cam.zoom > 0.3) {
            var i: i32 = 0;
            while(i < WORLD_WIDTH+1): (i += 1) {
                const f = @intToFloat(f32, i);
                rdr.drawLine(0.0, f * TILE_SIZE, WORLD_WIDTH * TILE_SIZE, f * TILE_SIZE, .GAME, 1.0/rdr.cam.zoom, comptime CU4(1, 1, 1, 0.1));
                rdr.drawLine(f * TILE_SIZE, 0.0, f * TILE_SIZE, WORLD_WIDTH * TILE_SIZE, .GAME, 1.0/rdr.cam.zoom, comptime CU4(1, 1, 1, 0.1));
            }
        }
        
        rdr.drawDbgQuad(0, 0, .BACK, WORLD_WIDTH * TILE_SIZE, WORLD_WIDTH * TILE_SIZE, 0.0, 0xFF0d131e);

        const tm = self.getGridMousePos();

        rdr.drawDbgQuad(tm.x * TILE_SIZE, tm.y * TILE_SIZE, .FRONT, TILE_SIZE, TILE_SIZE, 0.0, comptime CU4(1, 0, 1, 0.2));
    }

    fn signalStep(self: *Self) void
    {
        futex_wake(&self.pulse, 1);
    }

    fn getGridMousePos(self: Self) vec2
    {
        const tmx = @floor(((self.input.mousePos.x - sapp.widthf() /2.0)/rdr.cam.zoom + rdr.cam.pos.x) / TILE_SIZE);
        const tmy = @floor(((self.input.mousePos.y - sapp.heightf()/2.0)/rdr.cam.zoom + rdr.cam.pos.y) / TILE_SIZE);
        return vec2.new(tmx, tmy);
    }
};

var rdr: Renderer = .{};
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

    if(!rdr.init()) {
        log("ERROR: Could not init renderer");
        sapp.quit();
        return;
    }

    imgui.setup(.{});

    if(!content.LoadImages()) {
        log("ERROR: Could not load all images");
        sapp.quit();
        return;
    }

    game.init();
}

fn doUi() void
{
    imgui.showDemoWindow();

    if(imgui.begin("Simulation")) {
        if(imgui.button("Reset")) {
            game.reset();
        }
        _ = imgui.sliderInt("Speed", &game.speed, 0, MAX_STEP_SPEED);
        if(imgui.checkbox("Max speed", &game.dontWaitToStep)) {
            game.signalStep();
        }
    }
    imgui.end();
}

var skippedSteps: i32 = 0;

export fn frame() void
{
    imgui.newFrame(.{
        .width = sapp.width(),
        .height = sapp.height(),
        .delta_time = sapp.frameDuration(),
        .dpi_scale = sapp.dpiScale()
    });

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

    doUi();

    if(skippedSteps == 0) {
        skippedSteps = MAX_STEP_SPEED - game.speed;
    }

    game.draw();
    if(skippedSteps > 0) {
        skippedSteps -= 1;
    }
    if(game.speed != 0 and skippedSteps == 0) {
        game.signalStep();
    }

    rdr.render();
}

export fn cleanup() void
{
    game.running = false;
    sg.shutdown();
}

export fn input(ev: ?*const sapp.Event) void
{
    if(imgui.handleEvent(ev)) return;

    const event = ev.?;
    if(event.type == .KEY_DOWN) {
        if(event.key_code == .ESCAPE) {
            sapp.quit();
        }
        else if(event.key_code == .F1) {
            //reset Camera
            game.input.zoom = 1.0;
            rdr.cam.pos = vec2.new(0, 0);
        }
        else if(event.key_code == .SPACE) {
            log("spawn plant");

            game.world[10][10] = .{
                .type = .PLANT,
                .energy = 100
            };
        }
        else if(event.key_code == .R) {
            log("reset");

            game.reset();
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
        game.input.mousePos = .{ .x = event.mouse_x, .y = event.mouse_y };
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
        .swap_interval = 0,
    });
}