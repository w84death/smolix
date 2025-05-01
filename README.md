# SMOLiX
![SMOLiX Logo](smolix.png)

SMOLiX: Real Mode, Raw Power.

Homebrew, research, 16-bit operating system for x86 processors.

![Screenshot of SMOLiX](media/smolix.png)

## Technical Details

SMOLiX is a minimalist operating system designed to run in x86 Real Mode (16-bit). It embraces the simplicity and raw performance of direct hardware access, while providing a unique graphical user interface.

### Architecture
- **Processor Target**: x86 (286+ compatible)
- **Mode**: Real mode (16-bit)
- **Memory Model**: Segmented memory model
- **Boot Method**: Standard floppy disk boot
- **Minimal Hardware**:
  - CPU: 286
  - Graphics: EGA
  - RAM: 256KB

### Development Tools
- **Assembly Language**: FASM (Flat Assembler)
- **Build System**: Make
- **Emulation**: QEMU with KVM support
- **Graphics Tool**: Custom Python tileset converter (tileset2glyphs.py)
- **Disk Image Creation**: dd (direct disk utility)

### Functions:
- **Bootloader**
  - Loads kernel from disk
  - Sets up initial environment
  - Transfers control to kernel entry point
  - Boot parameters configuration

- **Kernel**
  - int 0x60 System calls:
    - Reset, system initialization
    - Version information
    - Print char
    - Print string
    - Set color
    - Load glyph
    - Load all glyphs for the UI
    - Draw glyph
    - Draw multi-char glyph
    - Get key from input
    - Handle text input
    - Process keyboard events
    - Memory management routines
    - System statistics display
    - APM power management

- **Graphics System**
  - Custom glyph-based rendering
  - 16-color VGA support
  - Multiple video modes (40x25, 80x25)
  - Permanent header with logo and version

- **User Interface**
  - Icon-based toolbar
  - Command-line interface
  - Sound feedback for commands

## Building and Running

```
make        # Build the system
make run    # Run in QEMU
make clean  # Clean build artifacts
```

## Current Version
Version alpha5:
- Support for both 40x25 and 80x25 video modes
- Updated character set
- Permanent header with logo and version
- Hardware statistics display
- APM power management
- Sound feedback for commands
- Automatic command listing in help

# FOSS
Copyright (C) 2025 [Krzysztof Krystian Jankowski](https://krzysztofjankowski.com). This program is free software. See [LICENSE](LICENSE) for details.