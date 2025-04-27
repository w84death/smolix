; SMOLiX: Real Mode, Raw Power.
; This is the bootloader.
; It is a simple bootloader that loads the kernel from disk and jumps to it.
; Copyright (C) 2025 Krzysztof Krystian Jankowski
; This program is free software. See LICENSE for details.

org 0x7C00
use16 

KERNEL_SIZE_KB equ 8 ; Size of the kernel in KB
SECTORS_TO_LOAD equ KERNEL_SIZE_KB*2 ; Number of sectors to load (512KB chunks)
KERNEL_STACK_POINTER equ 0xFFFE ; Stack pointer for the kernel
KERNEL_SEGMENT equ 0x7E0 ; Segment where kernel code is loaded
KERNEL_OFFSET equ 0x0000 ; Offset where kernel code starts

; Start of the bootloader
; This is the entry point of the bootloader.
; Expects: None
; Returns: None
boot_start:
  cli                 ; Disable interrupts
  xor ax, ax
  mov ds, ax
  mov es, ax

	mov ah, 0x00		; Set video mode
	mov al, 0x03		; 720x400 VGA text mode
	int 0x10

  mov si, welcome_msg
  call boot_print_str

  jmp boot_load_kernel


; Load kernel
; This function loads the kernel from disk into memory.
; Expects: None
; Returns: None
boot_load_kernel:
  mov si, loading_msg
  call boot_print_str

  ; Reset disk system first
  xor ax, ax
  mov dl, 0x00           ; Drive 0 (first floppy drive)
  int 0x13               ; Reset disk system
  jc boot_disk_reset_error

  ; Set up memory location for loading kernel
  mov ax, 0x7E0          ; Segment where code will be loaded
  mov es, ax
  xor bx, bx             ; Offset where code will be loaded (starting at 0)
  
  ; Set up disk read parameters
  mov ah, 0x02           ; BIOS read sectors function
  mov al, SECTORS_TO_LOAD
  mov ch, 0              ; Cylinder 0
  mov cl, 2              ; Start from sector 2
  mov dh, 0              ; Head 0
  mov dl, 0x00           ; Drive 0 (first floppy drive)
  
  int 0x13               ; BIOS disk interrupt
  jc boot_kernel_error   ; Error if carry flag set
  
  ; Check if we read the correct number of sectors
  cmp al, SECTORS_TO_LOAD     ; AL returns the number of sectors actually read
  jb boot_sector_count_error  ; Error if fewer sectors read than expected
  
  jmp boot_kernel_success ; Jump to kernel loaded success handler

; Disk reset error
; This function handles disk reset errors.
; Expects: None
; Returns: None
boot_disk_reset_error:
  mov si, reset_err_msg
  call boot_print_str
  jmp boot_error_recovery

; Sector count error
; This function handles sector count errors.
; Expects: None
; Returns: None  
boot_sector_count_error:
  mov si, count_err_msg
  call boot_print_str
  jmp boot_error_recovery

; Disk error
; This function handles disk read errors.
; Expects: None
; Returns: None
boot_kernel_error:
  mov si, error_msg
  call boot_print_str
  jmp boot_error_recovery

; Error recovery
; Common handler for disk errors
; Expects: None
; Returns: None
boot_error_recovery:
  mov si, again_msg
  call boot_print_str
  xor ax, ax
  int 0x16               ; BIOS keyboard interrupt (wait for keypress)
  jmp boot_load_kernel   ; Try again
ret

; Kernel loaded successfully
; This function is called after the kernel is loaded successfully.
; Expects: None
; Returns: None
boot_kernel_success:
  mov si, done_msg
  call boot_print_str

  ; Give visual indicator we're about to jump to kernel
  mov si, kernel_jump_msg
  call boot_print_str
  
  ; Set up stack before jumping to kernel
  mov ax, KERNEL_SEGMENT          ; Segment where code is loaded
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, KERNEL_STACK_POINTER         ; Initialize stack pointer to top of segment
  
  ; Jump to the loaded kernel at 0x7E0:0x0100
  ; The kernel will enable interrupts
  jmp KERNEL_SEGMENT:KERNEL_OFFSET


; Print string
; This function prints a string to the screen.
; Expects: DS:SI = pointer to string
; Returns: None
boot_print_str:
  mov ah, 0x0e        ; BIOS teletype output function
  .next_char:
    lodsb             ; Load next character from SI into AL
    or al, al         ; Check for null terminator
    jz .terminated
    int 0x10          ; BIOS video interrupt
  jmp near .next_char
  .terminated:
ret

; Print statements
welcome_msg db    '+  SMOLiX Bootloader V0.1d',0x0A,0x0D,0x0
loading_msg db  '>  Loading kernel...',0x0A,0x0D,0x0
error_msg db    '!  Error.',0x0A,0x0D,0x0
reset_err_msg db '! Disk reset error.',0x0A,0x0D,0x0
count_err_msg db '! Disk sector count error.',0x0A,0x0D,0x0
done_msg db     '.  Success.',0x0A,0x0D,0x0
again_msg db    '+  Press any key to try again.',0x0A,0x0D,0x0
kernel_jump_msg db '> Jumping into kernel...',0x0A,0x0D,0x0

; Bootloader signature
times 507 - ($ - $$) db 0   ; Pad to 510 bytes
db "P1X"                    ; Use HEX viewer to see P1X at the end of binary
dw 0xAA55                   ; Boot signature