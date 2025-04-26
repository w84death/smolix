# SMOLiX
SMOLiX: Real Mode, Raw Power.

Homebrew research 16-bit OS.

## Files
- [DEVLOG](DEVLOG)
- [CHANGELOG](CHANGELOG)

## Technical Details

### Functions:
- bootloader
- kernel
    - int 0x60      System calls.
        - 0x0000    Reset; System initialization.
        - 0x0003    Version.
        - 0x0006    Get key from input (keyboard).
        - 0x0009    Print char.
        - 0x000C    Print string.
        - 0x000F    Set color.
        - 0x0012    Draw window.
        - 0x0015    Draw user prompt.
        - 0x0018    TBD
        - 0x001B    TBD
        - 0x001E    TBD
        - 0x0021    Interpret user input.
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
Copyright (C) 2025 [https://krzysztofjankowski.com](Krzysztof Krystian Jankowski). This program is free software. See [LICENSE](LICENSE) for details.