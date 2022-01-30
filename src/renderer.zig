const std = @import("std");
const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const sgapp = @import("sokol").app_gfx_glue;
const imgui = @import("sokol").imgui;
const shd = @import("shaders/shaders.zig");
const math = @import("math.zig");
const content = @import("content.zig");

const vec2 = math.Vec2;
const vec3 = math.Vec3;
const mat4 = math.Mat4;

const Array = std.ArrayList;

const MAX_TILE_BATCH: usize = 1024*1024 + 64;
const MAX_DBGDRAW_BATCH: usize = 8192;

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

inline fn enumCount(comptime e: type) usize
{
    return @typeInfo(e).Enum.fields.len;
}

inline fn enumFields(comptime e: type) []const std.builtin.TypeInfo.EnumField
{
    return @typeInfo(e).Enum.fields;
}

pub const Renderer = struct {
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
    bindTex: sg.Bindings = .{},

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

    tileImageData: [1024*1024]u32 = [_]u32{0} ** (1024*1024),
    tileImage: sg.Image = .{},

    drawTileImage: bool = false,

    pub fn init(self: *Self, allocator: std.mem.Allocator) bool
    {
        sg.setup(.{
            .context = sgapp.context()
        });
        
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
        // quad uv 
        const vertQuadUV = [_]f32 {
            // positions
            0.0, 0.0, 0.0,    0.0, 0.0,
            1.0, 0.0, 0.0,    1.0, 0.0,
            1.0, 1.0, 0.0,    1.0, 1.0,
            0.0, 1.0, 0.0,    0.0, 1.0
        };
        self.bindTiles.vertex_buffers[0] = sg.makeBuffer(.{
            .data = sg.asRange(vertQuadCentered)
        });
        self.bindDbgDraw.vertex_buffers[0] = sg.makeBuffer(.{
            .data = sg.asRange(vertQuad)
        });
        self.bindTex.vertex_buffers[0] = sg.makeBuffer(.{
            .data = sg.asRange(vertQuadUV)
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
        self.bindTex.index_buffer = sg.makeBuffer(.{
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

        // tex pipeline
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
        self.pipeTex = sg.makePipeline(pip_desc);

        // clear to grey
        self.pass_action.colors[0] = .{ .action=.CLEAR, .value=.{ .r=0.2, .g=0.2, .b=0.2, .a=1 } };

        var img_desc = sg.ImageDesc{
            .width = 1024,
            .height = 1024,
            .pixel_format = .RGBA8,
            .min_filter = .NEAREST,
            .mag_filter = .NEAREST,
            .wrap_u = .CLAMP_TO_EDGE,
            .wrap_v = .CLAMP_TO_EDGE,
            .usage = .STREAM,
        };
        self.tileImage = sg.makeImage(img_desc);

        return true;
    }

    pub fn drawTile(self: *Self, imgID: content.ImageID, gridx: u16, gridy: u16, scale: u8, rot: u8, color: u24) void
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

    pub fn drawDbgQuad(self: *Self, x: f32, y: f32, z: Layer, w: f32, h: f32, rot: f32, color: u32) void
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

    pub fn drawLine(self: *Self, x1: f32, y1: f32, x2: f32, y2: f32, z: Layer, thickness: f32, color: u32) void
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

    pub fn renderLayer(self: *Self, comptime layer: Layer, view: mat4) void
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

    pub fn render(self: *Self) void
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

        if(self.drawTileImage) {
            self.drawTileImage = false;

            var imgData : sg.ImageData = .{};
            imgData.subimage[0][0] = sg.asRange(self.tileImageData);
            sg.updateImage(self.tileImage, imgData);

            sg.applyPipeline(self.pipeTex);
            self.bindTex.fs_images[0] = self.tileImage;
            sg.applyBindings(self.bindTex);

            const vs_params: shd.texture.VsParams = .{
                .mvp = mat4.mul(vp, mat4.scale(vec3.new(1024 * 32, 1024 * 32, 1))),
            };

            const fs_params: shd.texture.FsParams = .{
                .color = .{ 1, 1, 1 },
            };

            sg.applyUniforms(.VS, shd.texture.SLOT_vs_params, sg.asRange(vs_params));
            sg.applyUniforms(.FS, shd.texture.SLOT_fs_params, sg.asRange(fs_params));

            sg.draw(0, 6, 1);
        }

        self.renderLayer(.GAME, vp);
        self.renderLayer(.FRONT, vp);

        imgui.render();

        sg.endPass();
        sg.commit();

        self.tileBatch.clearRetainingCapacity();
        self.dbgDrawBatch.clearRetainingCapacity();
    }

    pub fn deinit(self: *Self) void
    {
        _ = self;
        sg.shutdown();
    }
};
