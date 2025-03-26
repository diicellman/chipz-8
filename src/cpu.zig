const std = @import("std");

// fontset for Chip-8
const chip8_fontset = [_]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};

pub const Chip8 = struct {
    memory: [4096]u8,
    graphics: [64 * 32]u8,
    stack: [32]u16,
    rand: std.Random.DefaultPrng,
    registers: [16]u8,
    keys: [16]u8,
    current_opcode: u16,
    index: u16,
    program_counter: u16,
    stack_pointer: u16,
    delay_timer: u8,
    sound_timer: u8,

    pub fn init(self: *Chip8) !void {
        const seed: u64 = @intCast(std.time.milliTimestamp());
        self.rand = std.Random.DefaultPrng.init(seed);

        self.program_counter = 0x200; // program starts at 0x200
        self.current_opcode = 0x00;
        self.index = 0x00;
        self.stack_pointer = 0x00;

        // clear display
        @memset(&self.graphics, 0);
        // clear stack
        @memset(&self.stack, 0);
        // clear registers
        @memset(&self.registers, 0);
        // clear memory
        @memset(&self.memory, 0);
        //clear keys
        @memset(&self.keys, 0);
        // load fontset into memory at 0x000
        @memcpy(self.memory[0..chip8_fontset.len], &chip8_fontset);

        self.delay_timer = 0;
        self.sound_timer = 0;
    }

    // increment the program counter by 2 (instructions is 2 bytes)
    fn increment_program_counter(self: *Chip8) void {
        self.program_counter += 2;
    }

    pub fn random_byte(self: *Chip8) u8 {
        return self.rand.random().int(u8);
    }

    pub fn cycle(self: *Chip8) !void {
        if (self.program_counter > 0xFFF) {
            @panic("opcode out of range!");
        }

        // fetch opcode
        self.current_opcode = @as(u16, self.memory[self.program_counter]) << 8 | self.memory[self.program_counter + 1];

        // decode and execute
        // CLS
        if (self.current_opcode == 0x00E0) {
            @memset(&self.graphics, 0);
            self.increment_program_counter();
        } else if (self.current_opcode == 0x00EE) { //RET
            self.stack_pointer -= 1;
            self.program_counter = self.stack[self.stack_pointer];
            self.increment_program_counter();
        } else {
            const first = self.current_opcode >> 12;

            switch (first) {
                0x0 => {
                    std.debug.print("SYS INSTR!!", .{});
                    self.increment_program_counter();
                },
                0x1 => {
                    self.program_counter = self.current_opcode & 0x0FFF;
                },
                0x2 => {
                    self.stack[self.stack_pointer] = self.program_counter;
                    self.stack_pointer += 1;
                    self.program_counter = self.current_opcode & 0x0FFF;
                },
                0x3 => {
                    const x = (self.current_opcode & 0x0F00) >> 8;
                    if (self.registers[x] == (self.current_opcode & 0x00FF)) {
                        self.increment_program_counter();
                    }
                    self.increment_program_counter();
                },
                0x4 => {
                    const x = (self.current_opcode & 0x0F00) >> 8;
                    if (self.registers[x] != (self.current_opcode & 0x00FF)) {
                        self.increment_program_counter();
                    }
                    self.increment_program_counter();
                },
                0x5 => {
                    const x = (self.current_opcode & 0x0F00) >> 8;
                    const y = (self.current_opcode & 0x00F0) >> 4;
                    if (self.registers[x] == self.registers[y]) {
                        self.increment_program_counter();
                    }
                    self.increment_program_counter();
                },
                0x6 => {
                    const x = (self.current_opcode & 0x0F00) >> 8;
                    self.registers[x] = @truncate(self.current_opcode & 0x00FF);
                    self.increment_program_counter();
                },
                0x7 => {
                    @setRuntimeSafety(false);
                    const x = (self.current_opcode & 0x0F00) >> 8;
                    self.registers[x] += @truncate(self.current_opcode & 0x00FF);
                    self.increment_program_counter();
                },
                0x8 => {
                    const x = (self.current_opcode & 0x0F00) >> 8;
                    const y = (self.current_opcode & 0x00F0) >> 4;
                    const m = self.current_opcode & 0x000F;

                    switch (m) {
                        0 => self.registers[x] = self.registers[y],
                        1 => self.registers[x] |= self.registers[y],
                        2 => self.registers[x] &= self.registers[y],
                        3 => self.registers[x] ^= self.registers[y],
                        4 => {
                            var sum: u16 = self.registers[x];
                            sum += self.registers[y];
                            self.registers[0xF] = if (sum > 255) 1 else 0;
                            self.registers[x] = @truncate(sum & 0x00FF);
                        },
                        5 => {
                            @setRuntimeSafety(false);
                            self.registers[0xF] = if (self.registers[x] > self.registers[y]) 1 else 0;
                            self.registers[x] -= self.registers[y];
                        },
                        6 => {
                            self.registers[0xF] = self.registers[x] & 0b00000001;
                            self.registers[x] >>= 1;
                        },
                        7 => {
                            @setRuntimeSafety(false);
                            self.registers[0xF] = if (self.registers[y] > self.registers[x]) 1 else 0;
                            self.registers[x] = self.registers[y] - self.registers[x];
                        },
                        0xE => {
                            self.registers[0xF] = if (self.registers[x] & 0b10000000 != 0) 1 else 0;
                            self.registers[x] <<= 1;
                        },
                        else => std.debug.print("CURRENT ALU OP: {x}\n", .{self.current_opcode}),
                    }
                    self.increment_program_counter();
                },
                0x9 => {
                    const x = (self.current_opcode & 0x0F00) >> 8;
                    const y = (self.current_opcode & 0x00F0) >> 4;
                    if (self.registers[x] != self.registers[y]) {
                        self.increment_program_counter();
                    }
                    self.increment_program_counter();
                },
                0xA => {
                    self.index = self.current_opcode & 0x0FFF;
                    self.increment_program_counter();
                },
                0xB => {
                    self.program_counter = (self.current_opcode & 0x0FFF) + @as(u16, self.registers[0]);
                },
                0xC => {
                    const x = (self.current_opcode & 0x0F00) >> 8;
                    const kk = self.current_opcode & 0x00FF;
                    self.registers[x] = self.random_byte() & @as(u8, @truncate(kk));
                    self.increment_program_counter();
                },
                0xD => {
                    self.registers[0xF] = 0;
                    const register_x = self.registers[(self.current_opcode & 0x0F00) >> 8];
                    const register_y = self.registers[(self.current_opcode & 0x00F0) >> 4];
                    const height = self.current_opcode & 0x000F;

                    var y: usize = 0;
                    while (y < height) : (y += 1) {
                        const stack_pointer = self.memory[self.index + y];
                        var x: usize = 0;
                        while (x < 8) : (x += 1) {
                            const v: u8 = 0x80;
                            if ((stack_pointer & (v >> @intCast(x))) != 0) {
                                const t_x = (register_x + x) % 64;
                                const t_y = (register_y + y) % 32;
                                const idx = t_x + t_y * 64;
                                self.graphics[idx] ^= 1;
                                if (self.graphics[idx] == 0) {
                                    self.registers[0xF] = 1;
                                }
                            }
                        }
                    }
                    self.increment_program_counter();
                },
                0xE => {
                    const x = (self.current_opcode & 0x0F00) >> 8;
                    const m = self.current_opcode & 0x00FF;

                    if (m == 0x9E) {
                        if (self.keys[self.registers[x]] == 1) {
                            self.increment_program_counter();
                        }
                    } else if (m == 0xA1) {
                        if (self.keys[self.registers[x]] != 1) {
                            self.increment_program_counter();
                        }
                    }
                    self.increment_program_counter();
                },
                0xF => {
                    const x = (self.current_opcode & 0x0F00) >> 8;
                    const m = self.current_opcode & 0x00FF;

                    if (m == 0x07) {
                        self.registers[x] = self.delay_timer;
                    } else if (m == 0x0A) {
                        var key_pressed = false;
                        var i: usize = 0;

                        while (i < 16) : (i += 1) {
                            if (self.keys[i] != 0) {
                                self.registers[x] = @truncate(i);
                                key_pressed = true;
                                break;
                            }
                        }
                        if (!key_pressed) return;
                    } else if (m == 0x15) {
                        self.delay_timer = self.registers[x];
                    } else if (m == 0x18) {
                        self.sound_timer = self.registers[x];
                    } else if (m == 0x1E) {
                        self.registers[0xF] = if (self.index + self.registers[x] > 0xFFF) 1 else 0;
                        self.index += self.registers[x];
                    } else if (m == 0x29) {
                        self.index = self.registers[x] * 0x5;
                    } else if (m == 0x33) {
                        self.memory[self.index] = self.registers[x] / 100;
                        self.memory[self.index + 1] = (self.registers[x] / 10) % 10;
                        self.memory[self.index + 2] = self.registers[x] % 10;
                    } else if (m == 0x55) {
                        var i: usize = 0;
                        while (i <= x) : (i += 1) {
                            self.memory[self.index + i] = self.registers[i];
                        }
                    } else if (m == 0x65) {
                        var i: usize = 0;
                        while (i <= x) : (i += 1) {
                            self.registers[i] = self.memory[self.index + i];
                        }
                    }
                    self.increment_program_counter();
                },
                else => std.debug.print("CURRENT OP: {x}\n", .{self.current_opcode}),
            }
        }
    }

    pub fn update_timers(self: *Chip8) void {
        if (self.delay_timer > 0) self.delay_timer -= 1;
        if (self.sound_timer > 0) {
            // TODO: need to implement sound
            self.sound_timer -= 1;
        }
    }
};
