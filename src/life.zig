const std   = @import("std");
const sapp  = @import("sokol").app;
const imgui = @import("sokol").imgui;
const math  = @import("math.zig");
const content = @import("content.zig");
const gfx = @import("renderer.zig");
const assert = std.debug.assert;

const vec2 = math.Vec2;
const vec3 = math.Vec3;
const mat4 = math.Mat4;

const Array = std.ArrayList;

const futex_wait = std.Thread.Futex.wait;
const futex_wake = std.Thread.Futex.wake;

const WORLD_WIDTH = 1024;
const WORLD_HEIGHT = 1024;
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

    configShowGrid: bool = false,

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
        if(self.configShowGrid) {
            if(rdr.cam.zoom > 0.3) {
                var i: i32 = 0;
                while(i < WORLD_WIDTH+1): (i += 1) {
                    const f = @intToFloat(f32, i);
                    rdr.drawLine(0.0, f * TILE_SIZE, WORLD_WIDTH * TILE_SIZE, f * TILE_SIZE, .GAME, 1.0/rdr.cam.zoom, comptime CU4(1, 1, 1, 0.1));
                    rdr.drawLine(f * TILE_SIZE, 0.0, f * TILE_SIZE, WORLD_WIDTH * TILE_SIZE, .GAME, 1.0/rdr.cam.zoom, comptime CU4(1, 1, 1, 0.1));
                }
            }
        }
        
        rdr.drawDbgQuad(0, 0, .BACK, WORLD_WIDTH * TILE_SIZE, WORLD_WIDTH * TILE_SIZE, 0.0, 0xFF0d131e);

        // mouse hover
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

var rdr: gfx.Renderer = .{};
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

    if(!rdr.init(arena.allocator())) {
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
    rdr.deinit();
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