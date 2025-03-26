# CHIPZ-8

***ELECTROCHEMISTRY [Medium]**: The phosphor glow of forgotten technology burns in your mind. These primitive pixels, this rudimentary sound—they call to something primal in you. The machines may be simple, but the experience was pure.*

A minimal Chip-8 emulator implemented in Zig using raylib.

## Features

- Complete Chip-8 instruction set implementation
- 64×32 pixel display at 16× scaling (1024×512 window)
- Customizable execution speed

## Prerequisites

- Zig 0.14.0
- raylib-zig

## Usage

```bash
zig build run -- path/to/rom.ch8
```

## Controls

The original Chip-8 had a 16-key hexadecimal keypad. This emulator maps them to modern keyboards as follows:

```
Chip-8 Keypad    Keyboard Mapping
+-+-+-+-+        +-+-+-+-+
|1|2|3|C|        |1|2|3|4|
+-+-+-+-+        +-+-+-+-+
|4|5|6|D|        |Q|W|E|R|
+-+-+-+-+   =>   +-+-+-+-+
|7|8|9|E|        |A|S|D|F|
+-+-+-+-+        +-+-+-+-+
|A|0|B|F|        |Z|X|C|V|
+-+-+-+-+        +-+-+-+-+
```

## Included ROMs

The `test-roms` directory contains several ROMs to test your emulator:

- `tetris.ch8` - Classic Tetris game
- `space_invaders.ch8` - Space Invaders clone
- `IBM_logo.ch8` - Displays the IBM logo
- `BMP_viewer.ch8` - Simple image viewer
- `keypad_test.ch8` - Tests keyboard input
- `test_opcode.ch8` - Tests Chip-8 opcodes

## Building from Source

```bash
git clone https://github.com/yourusername/CHIPZ-8.git
cd CHIPZ-8
zig build
```

## Additional Resources

- [Chip-8 Emulator Tutorial](https://austinmorlan.com/posts/chip8_emulator/) - Disco blog post by Austin Morlan
- [Chip-8 ROM Collection](https://github.com/dmatlack/chip8/tree/master/roms) - Additional ROMs to play with
