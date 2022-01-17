// stb
const c = @cImport({
    @cInclude("stb/stb_image.h");
});

const StbError = error {
    PngFileNotLoaded,
};

pub fn load(filename: [*:0]const u8, x: *i32, y: *i32, channels_in_file: *i32, desired_channels: i32) ![]u8
{
    const data = c.stbi_load(filename, x, y, channels_in_file, desired_channels);
    const len: usize = @intCast(usize, x.* * y.* * desired_channels);
    if(data == 0) return StbError.PngFileNotLoaded;
    return data[0..len];
}