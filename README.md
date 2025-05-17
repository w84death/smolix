![SMOLiX](media/splash.png)

Real Mode, Raw Power.

Homebrew, research operating system for x86 processors. Targeting retro 32-bit computers (386+).

![Screenshot of SMOLiX](media/welcome.png)

## ALPHA STAGE (Version alpha9)
This code is in alpha stage. This means that all the documentation/manual is constantly outdated. I try to commit only working code but sometimes that means that features are removed before refactor.

## Technical Details

SMOLiX is a minimalist operating system designed to run in x86 Real Mode (16-bit). It embraces the simplicity and raw performance of direct hardware access, while providing a unique graphical user interface.

![High Resolution Mode](media/hires.png)

### Architecture
- **Processor Target**: x86 (386+ compatible)
- **Mode**: Real mode
- **Memory Model**: Segmented memory model
- **Boot Method**: Standard floppy disk boot
- **Minimal Hardware**:
  - CPU: 386+
  - Graphics: EGA/VGA
  - RAM: 256KB
- **Operating System**: Linux (development environment)

### Development Tools
- **Assembly Language**: FASM (Flat Assembler)
- **Build System**: Make
- **Emulation**: QEMU/Bochs
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
  - 16-color EGA/VGA support
  - Multiple video modes (40x25, 80x25)
  - Permanent header with logo and version

![ASCII Support](media/ascii.png)

- **User Interface**
  - Command-line interface
  - Sound feedback for commands
  - System statistics display

![System Statistics](media/stats.png)

![Help Screen](media/help.png)

## Building and Running

```
make        # Build the system
make run    # Run in QEMU
make debug  # Run in Bochs
make burn   # Burn to floppy disk
make clean  # Clean build artifacts
```

## Tileset 2 Glyphs

```/smolix/tool$ python3 tileset2glyphs.py tileset.png ../src/glyphs.asm```


# FOSS
Copyright (C) 2023 [Krzysztof Krystian Jankowski](https://krzysztofjankowski.com). This program is free software. See [LICENSE](LICENSE) for details.
