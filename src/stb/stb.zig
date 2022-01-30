// stb
const c = @cImport({
    @cInclude("stb/stb_image.h");
    @cInclude("stb/stb_image_write.h");
});

const StbError = error {
    PngFileNotLoaded,
    PngFileNotWritten,
};

pub fn load(filename: [*:0]const u8, x: *i32, y: *i32, channels_in_file: *i32, desired_channels: i32) ![]u8
{
    const data = c.stbi_load(filename, x, y, channels_in_file, desired_channels);
    const len: usize = @intCast(usize, x.* * y.* * desired_channels);
    if(data == 0) return StbError.PngFileNotLoaded;
    return data[0..len];
}

pub fn save(filename: [*:0]const u8, width: usize, height: usize, data: []const u32) !void
{
    const success = c.stbi_write_png(filename, @intCast(c_int, width), @intCast(c_int, height), 4, data.ptr, 0);
    if(success == 0) return StbError.PngFileNotWritten;
}