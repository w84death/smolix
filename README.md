# SMOLiX
![SMOLiX Logo](smolix.png)

SMOLiX: Real Mode, Raw Power.

Homebrew, research, 16-bit operating system for x86 processors.

## Files
- [DEVLOG](DEVLOG)
- [CHANGELOG](CHANGELOG)

## Technical Details

### Functions:
- bootloader
- kernel
    - int 0x60      System calls.
        - 0x0000    Reset, system initialization.
        - 0x0003    Version.
        - 0x0006    TBD
        - 0x0009    Print char.
        - 0x000C    Print string.
        - 0x000F    Set color.
        - 0x0012    Load glyph.
        - 0x0015    Load all glyphs for the UI.
        - 0x0018    Draw glyph.
        - 0x001B    Draw multi-char glyph.
        - 0x001E    Draw window.
        - 0x0021    Get key from input
        - 0x0024    TBD
        - 0x0027    TBD
- applications
    - sh    Shell Prompt Logic.
    - edit  Text Editor.

### Interface
+ comment message.
> system message.
. system status reply.
@ user prompt

All messages ends with a dot.

# FOSS
Copyright (C) 2025 [Krzysztof Krystian Jankowski](https://krzysztofjankowski.com). This program is free software. See [LICENSE](LICENSE) for details.