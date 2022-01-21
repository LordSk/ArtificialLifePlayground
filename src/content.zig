// content 
const stb = @import("stb/stb.zig");
const sg = @import("sokol").gfx;
const std = @import("std");

const Tile = struct {
    name: []const u8,
    index: u8
};

const ImageEntry = struct {
    path: [*:0]const u8,
    tiles: []const Tile,
    gridDiv: struct {
        x: u8,
        y: u8
    } = .{ .x = 1, .y = 1 }
};

// image "hash"
pub const ImageID = struct {
    const Self = @This();

    img: u16,
    tile: u16,

    fn fromName(name: []const u8) ImageID
    {
        for(g_ImageList) |image, ii| {
            for(image.tiles) |tile, ti| {
                if(StringEquals(tile.name, name)) {
                    return .{ .img = @intCast(u16, ii), .tile = @intCast(u16, ti) };
                }
            }
        }

        unreachable; // image not found
    }

    pub fn none() ImageID
    {
        return .{ .img = 0xFFFF, .tile = 0xFFFF };
    }

    pub fn equals(self: Self, other: ImageID) bool
    {
        return self.img == other.img and self.tile == other.tile;
    }
};

pub fn LoadImages() bool
{
    {
        var img_desc: sg.ImageDesc = .{
            .width = 2,
            .height = 2,
            .pixel_format = .RGBA8,
            .min_filter = .NEAREST,
            .mag_filter = .NEAREST,
            .wrap_u = .CLAMP_TO_EDGE,
            .wrap_v = .CLAMP_TO_EDGE,
        };
        const img_data = [4]u32 { 0xFFFF00FF, 0x00, 0x00, 0xFFFF00FF };
        img_desc.data.subimage[0][0] = sg.asRange(img_data);

        g_GpuDefaultImage = sg.makeImage(img_desc);
    }

    for(g_ImageList) |image, i| {
        var width: i32 = 0;
        var height: i32 = 0;
        var channels: i32 = 0;
        const data = stb.load(image.path, &width, &height, &channels, 4) catch return false;

        const stdout = std.io.getStdOut().writer();
        stdout.print("{s} width={d} heigh={d} channels={d}\n", .{image.path, width, height, channels}) catch return false;

        var img_desc = sg.ImageDesc{
            .width = width,
            .height = height,
            .pixel_format = .RGBA8,
            .min_filter = .LINEAR,
            .mag_filter = .LINEAR,
            .wrap_u = .CLAMP_TO_EDGE,
            .wrap_v = .CLAMP_TO_EDGE,
        };

        img_desc.data.subimage[0][0] = sg.asRange(data);
        g_GpuImages[i] = sg.makeImage(img_desc);
    }

    return true;
}

fn StringEquals(str1: []const u8, str2: []const u8) bool 
{
    if(str1.len != str2.len) return false;

    var i: usize = 0;
    while(i < str1.len) {
        if(str1[i] != str2[i]) return false;
        i += 1;
    }
    return true;
}

pub const IMG = ImageID.fromName;

var g_GpuImages: [g_ImageList.len]sg.Image = undefined;
var g_GpuDefaultImage: sg.Image = undefined;

pub fn GetGpuImage(id: ImageID) sg.Image
{
    return g_GpuImages[id.img];
}

pub fn GetGpuImageTileInfo(id: ImageID) struct { index: u8, divw: u8, divh: u8 }
{
    const img = g_ImageList[id.img];
    return .{
        .index = img.tiles[id.tile].index,
        .divw = img.gridDiv.x,
        .divh = img.gridDiv.y
    };
}

const g_ImageList = [_]ImageEntry
{
    .{
        .path = "data/tiles.png",
        .gridDiv = .{ .x = 8, .y = 8 },
        .tiles = &.{
            .{ .name = "rock", .index = 0 },
            .{ .name = "plant", .index = 1 },
            .{ .name = "cow", .index = 2 },
            .{ .name = "zap", .index = 3 },
        }
    },
};