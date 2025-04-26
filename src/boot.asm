; SMOLiX: Real Mode, Raw Power.
; This is the bootloader.
; It is a simple bootloader that loads the kernel from disk and jumps to it.
; Copyright (C) 2025 Krzysztof Krystian Jankowski
; This program is free software. See LICENSE for details.

org 0x7C00
use16 

; Start of the bootloader
; This is the entry point of the bootloader.
; Expects: None
; Returns: None
start:
  cli                 ; Disable interrupts
  xor ax, ax
  mov ds, ax
  mov es, ax

  call clear_screen
  xor dx, dx
  call set_cursor
  mov si, welcome_msg
  call print_string
  call load_kernel

  hlt

; Clear screen
; This function clears the screen and sets the cursor position to (0, 0).
; Expects: None
; Returns: None
.clear_screen:
  mov ah, 0x06                ; Clear entire screen
  mov bh, BACKGROUND_COLOR    ; Background color
  mov dx, 0x184F              ; Lower right corner
  int 0x10
ret

; Load kernel
; This function loads the kernel from disk into memory.
; Expects: None
; Returns: None
load_kernel:
  mov ax, 0x7E0          ; Segment where code will be loaded
  mov es, ax
  xor bx, bx             ; Clear offset
  ; mov bx, 0x0100         ; Offset where code will be loaded

  mov ax, 0x0220         ; 8KB = 32 sectors
  xor dx, dx             ; CH = 0 cylinder, DH = 0 head
  mov cl, 2              ; CL = start at second sector
  int 0x13               ; BIOS disk interrupt
  jc disk_error          ; Jump if carry flag set (error)
  
  jmp near kernel_loaded

; Disk error
; This function handles disk read errors.
; Expects: None
; Returns: None
disk_error:
  mov si, error_msg
  call print_string
  mov si, again_msg
  call print_string
  xor ax, ax
  int 0x16               ; BIOS keyboard interrupt (wait for keypress)
  jmp near load_kernel
ret

; Kernel loaded successfully
; This function is called after the kernel is loaded successfully.
; Expects: None
; Returns: None
kernel_loaded:
  mov si, done_msg
  call print_string

  mov si, wait_msg
  call print_string

  xor ax, ax
  int 0x16               ; BIOS keyboard interrupt (wait for keypress)

  mov ax, 0x7E0          ; Segment where code is loaded
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x7C00         ; Initialize stack pointer  

  jmp 0x7E0:0x0100        ; Jump to the loaded kernel

; Set cursor position
; This function sets the cursor position to the specified coordinates.
; Expects: DX = (row << 8) | column
; Returns: None
set_cursor:
  mov ah, 0x02            ; BIOS set cursor position function
  mov bh, 0               ; Page number
  int 0x10                ; BIOS video interrupt
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

; Print statements
title_msg db    '+  SMOLiX Bootloader V0.1',0x0A,0x0D,0x0
loading_msg db  '>  Initializing bootloader...',0x0A,0x0D,0x0
error_msg db    '!  Error.',0x0A,0x0D,,0x0
done_msg db     '.  Success.',0x0A,0x0D,,0x0
again_msg db    '+  Press any key to try again.',0x0A,0x0D,0x0
wait_msg db     '+  Press any key to boot into the SMOLiX.',0x0

; Bootloader signature
times 507 - ($ - $$) db 0   ; Pad to 510 bytes
db "P1X"                    ; Use HEX viewer to see P1X at the end of binary
dw 0xAA55                   ; Boot signature