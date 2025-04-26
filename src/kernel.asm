; SMOLiX: Real Mode, Raw Power.
; This is the kernel.
; It is a simple kernel that runs in real mode as god intended.
; Copyright (C) 2025 Krzysztof Krystian Jankowski
; This program is free software. See LICENSE for details.

org 0x0000
use16

; Kernel consts
KERNEL_VERSION      db "SMOLiX Kernel v0.1", 0
PROMPT_MSG          db "+"
PROMPT_SYS_MSG      db ">"
PROMPT_STATUS       db "."
PROMPT_ERR          db "!"
PROMPT_USR          db "@"
PROMPT_SPACE        db " "

; Memory map

_BASE_              equ 0x2000           ; Start of memory
_OS_TICK_           equ _BASE_ + 0x00    ; 2 bytes
_OS_STATE_          equ _BASE_ + 0x02    ; 1 byte
_RNG_               equ _BASE_ + 0x03    ; 2 bytes

; System call table
SYS                 equ 0x0060  ; Position of the router in the kernel
SYS_RESET           equ 0x0000
SYS_DOWN            equ 0x0003
SYS_VER             equ 0x0006
SYS_PRINT_CHR       equ 0x0009
SYS_PRINT_STR       equ 0x000C
SYS_SET_COLOR       equ 0x000F
SYS_LOAD_GLYPH      equ 0x0012
SYS_LOAD_ALL_GLYPHS equ 0x0015
SYS_DRAW_GLYPH      equ 0x0018
SYS_DRAW_GLYPH_LONG equ 0x001B
SYS_DRAW_WINDOW     equ 0x001E
SYS_GET_KEY         equ 0x0021

; System call router
; This is the system call router. It is a jump table that
; redirects system calls to the appropriate function.
; Expects: None
; Returns: None
os_call_router:
    jmp near os_reset
    jmp near os_down
    jmp near os_ver
    jmp near os_print_chr
    jmp near os_print_str
    jmp near os_set_color
    jmp near os_load_glyph
    jmp near os_load_all_glyphs
    jmp near os_draw_glyph
    jmp near os_draw_glyph_long
    jmp near os_draw_window
    jmp near os_get_key

; System reset
; This function resets the system and clears the screen.
; Expects: None
; Returns: None
os_reset:
  push cs
	pop ds			; Align the data segment with the code segment

	push 0x0050		; Put the stack in a segment near the bottom
	pop ss			; of the memory
	
	mov bp, 0xFFFF		; Give us 65k of stack space
	mov sp, bp
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
os_ver:
    mov si, version ; Load the address of the version string
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
  mov ah, 0x0e        ; BIOS teletype output function
  .next_char:
    lodsb             ; Load next character from SI into AL
    cmp al, 0         ; Check for null terminator
    je .terminated
    int 0x10          ; BIOS video interrupt
  jmp near .next_char
  .terminated:
ret

os_set_color:
ret

os_load_glyph:
ret

os_load_all_glyphs:
ret

os_draw_glyph:
ret

os_draw_glyph_long:
ret

os_draw_window:
ret

os_get_key:
ret

version             db "alpha1:2025/04/25", 0
welcome_msg         db "Welcome to SMOLiX Operating System", 0
copyright_msg       db "(C) 2025 Krzysztof Krystian Jankowski", 0
more_info_msg       db "Read more at smol.p1x.in/smolix/", 0