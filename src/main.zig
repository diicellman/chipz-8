const std = @import("std");
const rl = @import("raylib");
const CPU = @import("cpu.zig");

const keymap = [16]rl.KeyboardKey{
    .x,
    .one,
    .two,
    .three,
    .q,
    .w,
    .e,
    .a,
    .s,
    .d,
    .z,
    .c,
    .four,
    .r,
    .f,
    .v,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var arg_it = try std.process.argsWithAllocator(allocator);
    _ = arg_it.skip();
    const filename = arg_it.next() orelse {
        std.debug.print("no ROM file given!", .{});
        return;
    };

    // init CPU
    var cpu: CPU.Chip8 = undefined;
    try cpu.init();

    // load ROM into memory at 0x200
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const size = try file.getEndPos();
    var reader = file.reader();
    var i: usize = 0;
    while (i < size) : (i += 1) {
        cpu.memory[0x200 + i] = try reader.readByte();
    }

    // raylib init
    const screen_width = 1024;
    const screen_height = 512;
    rl.initWindow(screen_width, screen_height, "CHIPZ-8");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    // emulation settings
    const cycles_per_frame = 10;

    // main loop
    while (!rl.windowShouldClose()) {
        for (keymap, 0..) |key, index| {
            cpu.keys[index] = if (rl.isKeyDown(key)) 1 else 0;
        }

        for (0..cycles_per_frame) |_| {
            try cpu.cycle();
        }

        cpu.update_timers();

        // draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        const pixel_size: i32 = 16;
        for (0..32) |y| {
            for (0..64) |x| {
                if (cpu.graphics[y * 64 + x] == 1) {
                    const px = @as(i32, @intCast(x)) * pixel_size;
                    const py = @as(i32, @intCast(y)) * pixel_size;
                    rl.drawRectangle(px, py, pixel_size, pixel_size, .white);
                }
            }
        }
    }
}
