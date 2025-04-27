; SMOLiX: Real Mode, Raw Power.
; This is the kernel.
; It is a simple kernel that runs in real mode as god intended.
; Copyright (C) 2025 Krzysztof Krystian Jankowski
; This program is free software. See LICENSE for details.

org 0x0000
use16

; Kernel consts
PROMPT_MSG          equ '+'
PROMPT_SYS_MSG      equ '>'
PROMPT_STATUS       equ '.'
PROMPT_ERR          equ '!'
PROMPT_USR          equ '@'
PROMPT_SPACE        equ ' '
PROMPT_CR           equ 0x0D
PROMPT_LF           equ 0x0A
GLYPH_SHIFT_IDX     equ 0x80

; Entry point
start:
  ; Set up data segment correctly (important for booting from bootloader)
  push cs            ; Push code segment
  pop ds             ; Set data segment = code segment
  push cs            ; Make sure ES is also set correctly
  pop es
  sti                ; Enable interrupts - critical for BIOS calls to work

; System reset
; This function resets the system.
; Expects: None
; Returns: None
os_reset:
  ; Set up the video mode
  mov ah, 0x00		    ; Set video mode
	mov al, 0x03		    ; 720x400 VGA text mode
	int 0x10

  mov al, 0
  call os_load_glyph
  inc al
  call os_load_glyph
inc al
  call os_load_glyph
inc al
  call os_load_glyph
inc al
  call os_load_glyph
inc al
  call os_load_glyph
inc al
  call os_load_glyph
inc al
  call os_load_glyph
inc al
  call os_load_glyph

  ; Print the welcome message
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
 
; Main system loop
os_main_loop:

  mov bl, PROMPT_USR
  call os_print_prefix

  call os_get_key
  call os_print_chr
  call os_interpret_char
  
jmp os_main_loop

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

; Print character
; This function prints a character to the screen.
; Expects: AL = character to print
; Returns: None
os_print_chr:
  mov ah, 0x0e    ; BIOS teletype output function
  int 0x10        ; BIOS teletype output function
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
ret

os_set_color:
ret

; Load glyph
; This function loads a custom glyph into the VGA font memory using BIOS.
; Expects: AX = character code to replace, BP = pointer to custom glyph data
; Returns: None
os_load_glyph:
  pusha
  push ax
  shl ax, 1            ; Multiply by 2 (each entry is 2 bytes)
  mov si, glyph_table  ; Get base address of glyph table
  add si, ax           ; Add offset to get pointer to the right entry
  mov bp, [si]         ; Get address of glyph data
  push ds
  pop es              ; Ensure ES = DS (BIOS expects ES:BP for font data)
  mov ax, 1100h       ; BIOS function to load user-defined font
  mov bh, 10h         ; Number of bytes per character (16 for 8x16 glyph)
  mov bl, 00h         ; RAM block (0 for default)
  mov cx, 01h         ; Number of characters to replace (1 for now)
  pop dx
  add dx, GLYPH_SHIFT_IDX ; Adjust character code for extended ASCII
  int 10h             ; Call BIOS video interrupt to load the font
  popa
ret


os_load_all_glyphs:
ret

os_draw_glyph:
ret

os_draw_glyph_long:
ret

os_draw_window:
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
  cmp al, "h"
  je .print_help
  cmp al, "v"
  je .print_os_version
  cmp al, "r"
  je .reset_os
  cmp al, "d"
  je .print_debug

  jmp .done

  .print_os_version:
    call os_print_ver
    jmp .done

  .reset_os:
    jmp os_reset

  .print_help:
    call os_print_help
    jmp .done

  .print_debug:
    mov bl, PROMPT_MSG
    call os_print_prefix
    mov al, GLYPH_SHIFT_IDX
    call os_print_chr
    mov cx, 0xF
    .loop_chars:
      inc al
      call os_print_chr
    loop .loop_chars
    jmp .done


  .done:
ret

; Data section
version_msg         db 'SMOLiX Version alpha1d', 0
welcome_msg         db 'Welcome to SMOLiX Operating System', 0
copyright_msg       db '(C) 2025 Krzysztof Krystian Jankowski', 0
more_info_msg       db 'Type "h" for help. Read more at smol.p1x.in/smolix/', 0
help_os_msg         db 'Legend: ">" system message, "+" message, "." return status, "@" user prompt', 0
help_cmds_msg       db 'Commands: "v" version, "r" reset, "d" debug', 0

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
    dw 0x0

glyph_00:
    db 0x00, 0x00, 0x08, 0x18, 0x38, 0x78, 0xF8, 0x78
    db 0x38, 0x18, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00

glyph_01:
    db 0x00, 0x00, 0x00, 0x0f, 0x1f, 0x3d, 0x1c, 0x0f
    db 0x33, 0x39, 0x3f, 0x3f, 0x1f, 0x00, 0x00, 0x00

glyph_02:
    db 0x00, 0x00, 0x00, 0xdc, 0xdc, 0xdc, 0x1e, 0x9e
    db 0xdf, 0xdb, 0xd9, 0x98, 0x18, 0x00, 0x00, 0x00

glyph_03:
    db 0x00, 0x00, 0x00, 0x78, 0x79, 0x7b, 0xff, 0xff
    db 0xff, 0xbb, 0x3b, 0x39, 0x38, 0x00, 0x00, 0x00

glyph_04:
    db 0x00, 0x00, 0x00, 0xe3, 0xf3, 0x3b, 0x1f, 0x1f
    db 0x1f, 0x9b, 0xfb, 0xf3, 0xe3, 0x00, 0x00, 0x00

glyph_05:
    db 0x00, 0x00, 0x00, 0x0e, 0x0e, 0x00, 0x0e, 0x0e
    db 0x0e, 0x0e, 0xee, 0xee, 0xee, 0x00, 0x00, 0x00

glyph_06:
    db 0x00, 0x00, 0x00, 0xdc, 0xdc, 0xdc, 0xfc, 0xfc
    db 0x78, 0xfc, 0xdc, 0xdc, 0xdc, 0x00, 0x00, 0x00

glyph_07:
    db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
    db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff

glyph_08:
    db 0x7f, 0x80, 0xbf, 0xbf, 0xbf, 0xbf, 0xbf, 0xbf
    db 0xbf, 0xbf, 0xbf, 0xbf, 0xbf, 0xbf, 0xbf, 0xbf



db "P1X"            ; Use HEX viewer to see P1X at the end of binary
