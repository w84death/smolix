; SMOLiX: Real Mode, Raw Power.
; This is the kernel.
; It is a simple kernel that runs in real mode as god intended.
; Copyright (C) 2025 Krzysztof Krystian Jankowski
; This program is free software. See LICENSE for details.

org 0x0000
use16

GLYPHS_START     equ 0x80
PROMPT_MSG          equ GLYPHS_START+0xA
PROMPT_SYS_MSG      equ GLYPHS_START+0x8
PROMPT_STATUS       equ GLYPHS_START+0xD
PROMPT_ERR          equ GLYPHS_START+0xB
PROMPT_USR          equ GLYPHS_START+0xC
PROMPT_SPACE        equ ' '
PROMPT_CR           equ 0x0D
PROMPT_LF           equ 0x0A
PROMPT_END          equ GLYPHS_START+0xF
COLOR_PRIMARY       equ 0x1F ; White on blue 
COLOR_SECONDARY     equ 0x0E ; Yellow on black

; System reset
; This function resets the system.
; Expects: None
; Returns: None
os_reset:
  ; Set up the video mode
  mov ah, 0x00		    ; Set video mode
	mov al, 0x03		    ; 720x400 VGA text mode
	int 0x10            ; 80x25 text mode
  
  call os_load_all_glyphs
  call os_clear_screen
  call os_print_welcome
 
; Main system loop
; This is the main loop of the operating system.
; It waits for user input and interprets it.
; Expects: None
; Returns: None
os_main_loop:

  call os_print_prompt
  call os_get_key
  call os_print_chr
  call os_interpret_char
  
jmp os_main_loop

; Print help message
; This function prints the help message to the screen.
; Expects: None
; Returns: None
os_print_help:
  mov bl, PROMPT_MSG
  call os_print_prefix
  mov si, help_os_msg
  call os_print_str
  mov bl, PROMPT_MSG
  call os_print_prefix
  mov si, help_cmds_msg
  call os_print_str
ret

; Print prefix
; This function prints the prefix for the prompt.
; Expects: BL = character to print
; Returns: None
os_print_prefix:
  mov al, PROMPT_CR
  call os_print_chr
  mov al, PROMPT_LF
  call os_print_chr
  mov al, PROMPT_SPACE
  call os_print_chr
  mov al, bl
  call os_print_chr
  mov al, PROMPT_SPACE
  call os_print_chr
ret

; System shutdown
; This function shuts down the system.
; Expects: None
; Returns: None
os_down:
ret

; System version
; This function returns the version of the kernel.
; Expects: None
; Returns: DS:SI = pointer to version string
os_print_ver:
  mov bl, PROMPT_SYS_MSG
  call os_print_prefix
  mov si, version_msg
  call os_print_str
ret

; Print welcome message
; This function prints the welcome message to the screen.
; Expects: None
; Returns: None
os_print_welcome:
  mov bl, PROMPT_SYS_MSG
  call os_print_prefix
  mov si, welcome_msg
  call os_print_str

  call os_print_ver

  ; Print the copyright message
  mov bl, PROMPT_MSG
  call os_print_prefix
  mov si, copyright_msg
  call os_print_str

  ; Print the more info message
  mov bl, PROMPT_MSG
  call os_print_prefix
  mov si, more_info_msg
  call os_print_str
ret

; Print prompt
; This function prints the prompt to the screen.
; Expects: None
; Returns: None
os_print_prompt:
  mov bl, PROMPT_USR
  call os_print_prefix
ret

; Print character
; This function prints a character to the screen.
; Expects: AL = character to print
; Returns: None
os_print_chr:
  mov ah, 0x0e    ; BIOS teletype output function
  int 0x10        ; BIOS teletype output function
ret

; Print character with color
; This function prints a character to the screen with a specific color.
; Expects: AL = character to print
;          BL = color attribute
; Returns: None
os_print_chr_color:
  mov bh, 0x00       ; Page number
  mov ah, 0x09       ; BIOS function to write character and attribute
  mov cx, 1          ; Number of times to write character
  int 0x10           ; BIOS video interrupt
ret

; Print character with color and multiplication
; This function prints a character to the screen with a specific color and multiplies it.
; Expects: AL = character to print
;          BL = color attribute
;          CX = number of times to print
; Returns: None
os_print_chr_color_mul:
  mov bh, 0x00       ; Page number
  mov ah, 0x09       ; BIOS function to write character and attribute
  int 0x10           ; BIOS video interrupt
ret

; Print string
; This function prints a string to the screen.
; Expects: DS:SI = pointer to string
; Returns: None
os_print_str:
  xor bx, bx          ; Clear page number
  mov ah, 0x0e        ; BIOS teletype output function
  .next_char:
    lodsb             ; Load next character from SI into AL
    or al, al         ; Check for null terminator
    jz .terminated
    int 0x10          ; BIOS video interrupt
  jmp near .next_char
  .terminated:

  mov al, PROMPT_END
  int 0x10
ret

; Clear screen
; This function clears the screen with primary colors.
; Expects: None
; Returns: None
os_clear_screen:
  call os_cursor_pos_reset
  mov ax, 0x0600     ; Function 06h (scroll window up)
  mov bh, COLOR_PRIMARY  ; Set color attribute
  mov cx, 0x0000     ; Top left corner (row 0, col 0)
  mov dx, 0x184F     ; Bottom right corner (row 24, col 79)
  int 0x10
  call os_cursor_pos_reset
ret

os_cursor_pos_reset:
  xor dx, dx
  mov ah, 0x2
  mov bh, 0x0
  int 0x10
ret

; Set cursor position
; This function sets the cursor position on the screen.
; Expects: DX = position (row * 80 + col)
; Returns: None
os_cursor_set_pos:
  mov ah, 0x02
  mov bh, 0x00
  int 0x10
ret

; Set color
; This function sets the color of the text on the screen.
; Expects: BL = color attribute
; Returns: None
os_set_color:
  mov ah, 0x0B
  mov bh, 0x00
  int 0x10
ret

; Load glyph
; This function loads a custom glyph into the VGA font memory using BIOS.
; Expects: AX = character code to replace, BP = pointer to custom glyph data
; Returns: None
os_load_glyph:
  pusha
  push ax
  shl ax, 1             ; Multiply by 2 (each entry is 2 bytes)
  mov si, glyph_table   ; Get base address of glyph table
  add si, ax            ; Add offset to get pointer to the right entry
  mov bp, [si]          ; Get address of glyph data
  push ds
  pop es                ; Ensure ES = DS (BIOS expects ES:BP for font data)
  mov ax, 1100h         ; BIOS function to load 9×16 user-defined font
  mov bh, 10h           ; Number of bytes per character (16 for 8/9×16 glyph)
  mov bl, 00h           ; RAM block (0 for default)
  mov cx, 0x01          ; Number of characters to replace (1 for now)
  pop dx
  add dx, GLYPHS_START ; Adjust character code for extended ASCII
  int 10h             ; Call BIOS video interrupt to load the font
  popa
ret

; Load all glyphs
; This function loads all custom glyphs into the VGA font memory using BIOS.
; Expects: None
; Returns: None
os_load_all_glyphs:
  mov si, glyph_table
  xor cx, cx
  .loop_glyphs:
    lodsw
    cmp ax, 0x0
    je .done
    mov ax, cx
    call os_load_glyph
    inc cx
    jmp .loop_glyphs
  .done:
ret

; Wait for key press
; This function waits for a key press and returns the key code in AL.
; Expects: None
; Returns: AL = key code
os_get_key:
  xor ax, ax      ; Clear AX (any key)
  int 0x16        ; Wait for key press
ret


; Interpret character
; This function interprets the character in AL and performs the appropriate action.
; Expects: AL = character to interpret
; Returns: None
os_interpret_char:
  ; Check if the command exists in the command table
  mov si, os_commands_table
  xor cx, cx  ; Initialize command index

  .loop_commands:
    lodsb           ; Load next command character
    cmp al, 0       ; Check for end of table
    je .unknown     ; If end, jump to unknown command
    cmp al, [si]    ; Compare with input character
    je .found       ; If found, jump to found command
    add si, 3       ; Move to the next command entry (character, address, comment)
    inc cx          ; Increment command index
    jmp .loop_commands

  .found:
    ; Execute the corresponding command
    jmp [si + 1]  ; Jump to the command function

  .unknown:
    mov bl, PROMPT_ERR
    call os_print_prefix
    mov si, unknown_cmd_msg
    call os_print_str
ret

; Print debug info
; This function prints debug information.
; Expects: None
; Returns: None
os_print_debug:
  mov bl, PROMPT_MSG
  call os_print_prefix
  mov al, GLYPHS_START
  call os_print_chr
  mov cx, 0xF
  .loop_chars:
    inc al
    call os_print_chr
  loop .loop_chars

  mov bl, PROMPT_MSG
  call os_print_prefix
  mov si, hex_ruler_msg
  call os_print_str
ret

; Print statistics
; This function prints system statistics.
; Expects: None
; Returns: None
os_print_stats:
ret

; Data section
version_msg         db 'Version alpha2', 0
welcome_msg         db 'Welcome to ', 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, ' Operating System', 0
copyright_msg       db '(C) 2025 Krzysztof Krystian Jankowski', 0
more_info_msg       db 'Type "h" for help. Read more at smol.p1x.in/smolix/', 0
help_os_msg         db 'Legend: ',PROMPT_SYS_MSG,' system message, ',PROMPT_MSG,' message, ',PROMPT_STATUS,' return status, ',PROMPT_USR,' user prompt', 0
help_cmds_msg       db 'Commands: "v" version, "r" reset, "d" debug', 0
unknown_cmd_msg     db 'Unknown command', 0
hex_ruler_msg       db '0123456789ABCDEF', 0

; Commands table
os_commands_table:
  db 'h', os_print_help, 'system help'
  db 'v', os_print_ver, 'system version'
  db 'r', os_reset, 'reset the system'
  db 's', os_print_stats, 'system statistics'
  db 'd', os_print_debug, 'debug information'
  db 0  ; End of table

; Custom glyphs
glyph_00:
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

glyph_01:
    db 0x00, 0x00, 0x00, 0x3f, 0x7f, 0xf7, 0x70, 0x3e
    db 0xcf, 0xe7, 0xff, 0xfe, 0x7c, 0x00, 0x00, 0x00

glyph_02:
    db 0x00, 0x00, 0x00, 0xe3, 0xe3, 0xe3, 0xf7, 0xf7
    db 0xff, 0xdd, 0xc9, 0xc1, 0xc1, 0x00, 0x00, 0x00

glyph_03:
    db 0x00, 0x00, 0x00, 0xc3, 0xc7, 0xcd, 0xdc, 0xdc
    db 0xdc, 0xce, 0xcf, 0xc7, 0xc3, 0x00, 0x00, 0x00

glyph_04:
    db 0x00, 0x00, 0x00, 0x0c, 0x8c, 0xcc, 0xec, 0xec
    db 0xec, 0xcc, 0xcf, 0x8f, 0x0f, 0x00, 0x00, 0x00

glyph_05:
    db 0x00, 0x00, 0x00, 0x77, 0x77, 0x07, 0x77, 0x77
    db 0x71, 0x77, 0x77, 0x77, 0x77, 0x00, 0x00, 0x00

glyph_06:
    db 0x00, 0x00, 0x00, 0x70, 0x70, 0x70, 0xf0, 0xf0
    db 0xe0, 0xf0, 0x70, 0x70, 0x70, 0x00, 0x00, 0x00

glyph_07:
    db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
    db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff

glyph_08:
    db 0x00, 0x00, 0x00, 0x00, 0x54, 0x81, 0x3c, 0xad
    db 0x3c, 0xbd, 0x00, 0x55, 0x00, 0x00, 0x00, 0x00

glyph_09:
    db 0x00, 0x00, 0x00, 0xff, 0xbd, 0xbd, 0xbd, 0x81
    db 0x99, 0x99, 0xc3, 0xff, 0x00, 0x00, 0x00, 0x00

glyph_0a:
    db 0x00, 0x00, 0x00, 0xfc, 0xfe, 0x8b, 0xff, 0xa1
    db 0xff, 0x85, 0xff, 0xa1, 0xff, 0xff, 0x00, 0x00

glyph_0b:
    db 0x00, 0x0c, 0x14, 0x16, 0x1e, 0x1e, 0x0c, 0x0c
    db 0x0c, 0x08, 0x00, 0x18, 0x38, 0x10, 0x00, 0x00

glyph_0c:
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x40, 0x44
    db 0x46, 0x3f, 0x06, 0x04, 0x00, 0x00, 0x00, 0x00

glyph_0d:
    db 0x00, 0x00, 0x00, 0x00, 0x7e, 0x81, 0xad, 0x81
    db 0x7f, 0x06, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00

glyph_0e:
    db 0x00, 0x00, 0x3c, 0x42, 0x81, 0x81, 0xc3, 0xbd
    db 0xc3, 0xbd, 0xc3, 0xbd, 0x42, 0x3c, 0x00, 0x00

glyph_0f:
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x50, 0x20, 0x50, 0x00, 0x00, 0x00

glyph_table:
    dw glyph_00
    dw glyph_01
    dw glyph_02
    dw glyph_03
    dw glyph_04
    dw glyph_05
    dw glyph_06
    dw glyph_07
    dw glyph_08
    dw glyph_09
    dw glyph_0a
    dw glyph_0b
    dw glyph_0c
    dw glyph_0d
    dw glyph_0e
    dw glyph_0f
    dw 0x0

db "P1X"            ; Use HEX viewer to see P1X at the end of binary
