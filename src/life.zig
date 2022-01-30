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

fn fmod(f: f32, mod: f32) f32
{
    const d = @floor(f / mod);
    return f - (mod * d);
}

fn hueToRGBA(hue: u8) u32
{
    const H = @intToFloat(f32, hue) / 255.0 * 360.0;
    const C = 1.0;
    const X = C * (1.0 - std.math.absFloat(fmod(H/60.0, 2) - 1));
    var r: f32 = 0.0;
    var g: f32 = 0.0;
    var b: f32 = 0.0;

    if(H >= 0 and H < 60){
        r = C;
        g = X;
        b = 0;
    }
    else if(H >= 60 and H < 120){
        r = X;
        g = C;
        b = 0;
    }
    else if(H >= 120 and H < 180){
        r = 0;
        g = C;
        b = X;
    }
    else if(H >= 180 and H < 240){
        r = 0;
        g = X;
        b = C;
    }
    else if(H >= 240 and H < 300){
        r = X;
        g = 0;
        b = C;
    }
    else{
        r = C;
        g = 0;
        b = X;
    }

    return CU4(r, g, b, 1.0);
}

const EntityType = enum(u8) {
    EMPTY,
    WALL,
    ZAP,
    ROCK,
    PLANT,
    COW,
    PLANT_MUTANT,
    COW_MUTANT
};

const Game = struct
{
    const Self = @This();

    const Tile = struct {
        type: EntityType,
        energy: i8,
        hue: u8 = 0,
    };

    const ClickAction = enum {
        ADD_ROCK,
        ADD_PLANT,
        ADD_COW,
        ADD_PLANT_MUTANT,
        ADD_COW_MUTANT,
        ZAP,
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

    clickAction: ClickAction = .ADD_ROCK,

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

    fn stepPlant(self: *Self, it: *Tile, x: usize, y: usize) void
    {
        it.energy += 5;
        if(it.energy > 100) it.energy = 100;

        if(it.energy > 50 and randi(0, 10) == 0) {
            const dx = @intCast(i32, x) + randi(-1, 1);
            const dy = @intCast(i32, y) + randi(-1, 1);

            if(dx < 0 or dx >= WORLD_WIDTH) return;
            if(dy < 0 or dy >= WORLD_HEIGHT) return;

            const udx = @intCast(usize, dx);
            const udy = @intCast(usize, dy);

            if(self.world[udy][udx].type != .EMPTY) return;

            const offspringEnergy = @intCast(i8, randi(20, 35));
            it.energy -= offspringEnergy;

            self.world[udy][udx] = .{
                .type = .PLANT,
                .energy = offspringEnergy
            };
        }
    }

    fn stepCow(self: *Self, it: *Tile, x: usize, y: usize) void
    {
        it.energy -= 2;
        if(it.energy <= 0) {
            it.* = .{
                .type = .EMPTY,
                .energy = 0
            };
            return;
        }

        var dx: i32 = -1;
        var dy: i32 = -1;
        while(dx < 0 or dx >= WORLD_WIDTH or dy < 0 or dy >= WORLD_HEIGHT) {
            dx = @intCast(i32, x) + randi(-1, 1);
            dy = @intCast(i32, y) + randi(-1, 1);
        }

        const udx = @intCast(usize, dx);
        const udy = @intCast(usize, dy);

        var spot = &self.world[udy][udx];

        const reproduce = it.energy > 80 and randi(0, 8) == 0;
        const offspringEnergy = @intCast(i8, randi(20, 35));

        switch(spot.type) {
            .EMPTY => {
                spot.* = .{
                    .type = .COW,
                    .energy = it.energy,
                };

                if(reproduce) {
                    it.* = .{
                        .type = .COW,
                        .energy = offspringEnergy
                    };
                    spot.energy -= offspringEnergy;
                }
                else {
                    it.* = .{
                        .type = .EMPTY,
                        .energy = 0
                    };
                }
            },
            
            .PLANT, .PLANT_MUTANT => {
                spot.* = .{
                    .type = .COW,
                    .energy = @intCast(i8, std.math.min(100, @intCast(u32, it.energy) + 50)),
                };

                if(reproduce) {
                    it.* = .{
                        .type = .COW,
                        .energy = offspringEnergy
                    };
                    spot.energy -= offspringEnergy;
                }
                else {
                    it.* = .{
                        .type = .EMPTY,
                        .energy = 0
                    };
                }
            },

            else => {},
        }
    }

    fn stepPlantMutant(self: *Self, it: *Tile, x: usize, y: usize) void
    {
        it.energy += 5;
        if(it.energy > 100) it.energy = 100;

        if(it.energy > 50 and randi(0, 10) == 0) {
            const dx = @intCast(i32, x) + randi(-1, 1);
            const dy = @intCast(i32, y) + randi(-1, 1);

            if(dx < 0 or dx >= WORLD_WIDTH) return;
            if(dy < 0 or dy >= WORLD_HEIGHT) return;

            const udx = @intCast(usize, dx);
            const udy = @intCast(usize, dy);

            if(self.world[udy][udx].type != .EMPTY) return;

            const offspringEnergy = @intCast(i8, randi(20, 35));
            it.energy -= offspringEnergy;

            const mutate = randi(0, 1) == 0;
            const hueAdd = if(mutate) @intCast(u8, (randi(0, 1) * 2 - 1) * randi(1, 2)) else 0;

            self.world[udy][udx] = .{
                .type = .PLANT_MUTANT,
                .energy = offspringEnergy,
                .hue = it.hue +% hueAdd,
            };
        }
    }

    fn step(self: *Self) void
    {
        for(self.world) |*col, y| {
            for(col) |*it, x| {
                switch(it.type) {
                    .PLANT => self.stepPlant(it, x, y),
                    .COW => self.stepCow(it, x, y),
                    .PLANT_MUTANT => self.stepPlantMutant(it, x, y),

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

        const zapCount = randi(0, WORLD_WIDTH* WORLD_HEIGHT / 2048);
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
                    .ZAP => "zap",
                    .ROCK => "rock",
                    .PLANT => "plant",
                    .COW => "cow",
                    .PLANT_MUTANT => "plant_grey",
                    .COW_MUTANT => "cow_grey",
                    else => continue,
                };

                const scale: u8 = switch(it.type) {
                    .PLANT, .PLANT_MUTANT => @floatToInt(u8, @intToFloat(f32, std.math.min(it.energy, 100)) / 100.0 * 255.0),
                    .COW, .COW_MUTANT => std.math.max(50, @floatToInt(u8, @intToFloat(f32, std.math.min(it.energy, 100)) / 100.0 * 255.0)),
                    else => 255,
                };

                const rot: u8 = switch(it.type) {
                    .PLANT, .PLANT_MUTANT => @truncate(u8, hash32(std.mem.asBytes(&.{x,y}))),
                    else => 0,
                };

                const color: u24 = switch(it.type) {
                    .PLANT_MUTANT => @truncate(u24, hueToRGBA(it.hue) & 0xFFFFFF),
                    else => 0xFFFFFF,
                };

                rdr.drawTile(content.IMG(img), @intCast(u16, x), @intCast(u16, y), scale, rot, color);
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

        if(tm.x >= 0 and tm.x < WORLD_WIDTH and tm.y >= 0 and tm.y < WORLD_HEIGHT) {
            const imgID = content.IMG(switch(self.clickAction) {
                .ADD_ROCK => "rock",
                .ADD_PLANT => "plant",
                .ADD_COW => "cow",
                .ADD_PLANT_MUTANT => "plant_grey",
                .ADD_COW_MUTANT => "cow_grey",
                .ZAP => "zap",
            });
            rdr.drawTile(imgID, @floatToInt(u16, tm.x), @floatToInt(u16, tm.y), 255, 0, 0xFFC8FF);
        }
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

    fn killAllCows(self: *Self) void
    {
        for(self.world) |*col| {
            for(col) |*it| {
                if(it.type == .COW) {
                    it.* = .{
                        .type = .EMPTY,
                        .energy = 0
                    };
                }
            }
        }
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

fn uiImageButton(imgID: content.ImageID, selected: bool) bool
{
    const img = content.GetGpuImage(imgID);
    const tile = content.GetGpuImageTileInfo(imgID);

    const ix = @intToFloat(f32, tile.index % tile.divw);
    const iy = @intToFloat(f32, tile.index / tile.divh);
    const tw = @intToFloat(f32, tile.divw);
    const th = @intToFloat(f32, tile.divh);

    const uv0: imgui.ImVec2 = .{
        .x = ix/tw,
        .y = iy/th,
    };

    const uv1: imgui.ImVec2 = .{
        .x = uv0.x + 1.0/tw,
        .y = uv0.y + 1.0/th
    };

    const bgColor: imgui.ImVec4 = if(selected) .{ .x=1, .y=0, .z=0, .w=1 } else .{ .x=0, .y=0, .z=0, .w=0 };
    const tintColor: imgui.ImVec4 = .{ .x=1, .y=1, .z=1, .w=1 };

    imgui.pushID(@intCast(i32, @intCast(u32, imgID.img) << 16 | imgID.tile));
    const r = imgui.imageButton(img, .{ .x=32, .y=32 }, uv0, uv1, bgColor, tintColor);
    imgui.popID();
    return r;
}

fn uiImage(imgID: content.ImageID) void
{
    const img = content.GetGpuImage(imgID);
    const tile = content.GetGpuImageTileInfo(imgID);

    const ix = @intToFloat(f32, tile.index % tile.divw);
    const iy = @intToFloat(f32, tile.index / tile.divh);
    const tw = @intToFloat(f32, tile.divw);
    const th = @intToFloat(f32, tile.divh);

    const uv0: imgui.ImVec2 = .{
        .x = ix/tw,
        .y = iy/th,
    };

    const uv1: imgui.ImVec2 = .{
        .x = uv0.x + 1.0/tw,
        .y = uv0.y + 1.0/th
    };

    imgui.image(img, .{ .x=32, .y=32 }, uv0, uv1);
}

fn doUi() void
{
    // imgui.showDemoWindow();

    if(imgui.begin("Simulation")) {
        if(imgui.button("Reset")) {
            game.reset();
        }
        imgui.sameLine();
        if(imgui.button("Murder all the cows")) {
            game.killAllCows();
        }

        _ = imgui.sliderInt("Speed", &game.speed, 0, MAX_STEP_SPEED);
        if(imgui.checkbox("Max speed", &game.dontWaitToStep)) {
            game.signalStep();
        }
    }
    imgui.end();

    if(imgui.begin("Options")) {
        _ = imgui.checkbox("Show grid", &game.configShowGrid);
    }
    imgui.end();

    if(imgui.begin("Actions")) {
        const actions = .{
            .{ "rock", .ADD_ROCK },
            .{ "plant", .ADD_PLANT },
            .{ "cow", .ADD_COW },
            .{ "plant_grey", .ADD_PLANT_MUTANT },
            .{ "cow_grey", .ADD_COW_MUTANT },
            .{ "zap", .ZAP },
        };

        inline for(actions) |a, i| {
            if(uiImageButton(comptime content.IMG(a[0]), game.clickAction == a[1])) {
                game.clickAction = a[1];
            }
            
            if(i+1 < actions.len) imgui.sameLine();
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
        else if(event.mouse_button == .LEFT) {
            const tm = game.getGridMousePos();

            if(tm.x >= 0 and tm.x < WORLD_WIDTH and tm.y >= 0 and tm.y < WORLD_HEIGHT) {
                const tmi = .{ @floatToInt(u32, tm.x), @floatToInt(u32, tm.y) };

                switch(game.clickAction) {
                    .ADD_ROCK => game.world[tmi[1]][tmi[0]] = .{
                        .type = .ROCK,
                        .energy = 100
                    },
                    .ADD_PLANT => game.world[tmi[1]][tmi[0]] = .{
                        .type = .PLANT,
                        .energy = 100
                    },
                    .ADD_COW => game.world[tmi[1]][tmi[0]] = .{
                        .type = .COW,
                        .energy = 100
                    },
                    .ADD_PLANT_MUTANT => game.world[tmi[1]][tmi[0]] = .{
                        .type = .PLANT_MUTANT,
                        .energy = 100,
                        .hue = @intCast(u8, randi(0, 255))
                    },
                    .ADD_COW_MUTANT => game.world[tmi[1]][tmi[0]] = .{
                        .type = .COW_MUTANT,
                        .energy = 100
                    },
                    .ZAP => game.world[tmi[1]][tmi[0]] = .{
                        .type = .ZAP,
                        .energy = 100
                    },
                }
            }
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