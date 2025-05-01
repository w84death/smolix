; SMOLiX: Real Mode, Raw Power.
; This is the kernel.
; It is a simple kernel that runs in real mode as god intended.
; Copyright (C) 2025 Krzysztof Krystian Jankowski
; This program is free software. See LICENSE for details.

; Minimal hardware:
; CPU: 286
; Graphics: EGA
; RAM: 256KB

org 0x0000
use16

OS_VIDEO_MODE_40         equ 0x00  ; default 40x25
OS_VIDEO_MODE_80         equ 0x03  ; 80x25 // 720x400 VGA text mode
_OS_VIDEO_MODE_        equ 0x2000

GLYPH_FIRST           equ 0x80
PROMPT_MSG            equ GLYPH_FIRST+0xB
PROMPT_SYS_MSG        equ GLYPH_FIRST+0x9
PROMPT_LIST           equ 0xFE
PROMPT_ERR            equ GLYPH_FIRST+0xA
PROMPT_USR            equ GLYPH_FIRST+0xC
CHR_SPACE             equ GLYPH_FIRST
CHR_CR                equ 0x0D
CHR_LF                equ 0x0A
PROMPT_END            equ GLYPH_FIRST+0x8
GLYPH_PC              equ GLYPH_FIRST+0xD
GLYPH_MOUSE           equ GLYPH_FIRST+0xE
GLYPH_CAL             equ GLYPH_FIRST+0xF
GLYPH_MEM             equ GLYPH_FIRST+0x10
GLYPH_BAT             equ GLYPH_FIRST+0x11
GLYPH_BLOCK           equ GLYPH_FIRST+0x12
GLYPH_CEILING         equ GLYPH_FIRST+0x13
GLYPH_FLOOR           equ GLYPH_FIRST+0x14
GLYPH_UP              equ GLYPH_FIRST+0x15
GLYPH_DOWN            equ GLYPH_FIRST+0x16
GLYPH_ICONS_SELECTOR  equ 0x9897
GLYPH_ICON_RESET      equ 0x9A99 
GLYPH_ICON_REBOOT     equ 0x9C9B 
GLYPH_ICON_DOWN       equ 0x9E9D 
GLYPH_ICON_SHELL      equ 0xA09F 
GLYPH_ICON_EDIT       equ 0xA2A1
GLYPH_ICON_CONF       equ 0xA4A3  ; New glyph for calculator icon
GLYPH_ICON_HOME       equ 0xA6A5  ; New glyph for chip icon
GLYPH_ICON_X          equ 0xA8A7  ; New glyph for clear icon
GLYPH_ICON_DOTS       equ 0xAAA9  ; New glyph for save icon

COLOR_PRIMARY         equ 0x1F  ; White on blue
COLOR_SECONDARY       equ 0x2F  ; Light gray on dark blue 
LENGTH_CMDS_TBL_CHAR  equ 1     ; Command character
LENGTH_CMDS_TBL_ADDR  equ 2     ; Address to function
LENGTH_CMDS_TBL_DESC  equ 24+1  ; Description length + terminator character


os_init:
  mov byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_80

  ; Continue with os_reset

; Entry point / System reset ===================================================
; This function resets the system.
; Expects: None
; Returns: None
os_reset:
  mov ah, 0x00		    ; Set video mode
	mov al, [_OS_VIDEO_MODE_]
	int 0x10            ; 80x25 text mode
  
  call os_load_all_glyphs
  call os_clear_screen
  call os_print_header
  call os_print_welcome
  ; No return, go to the main loop
 
; Main system loop =============================================================
; This is the main loop of the operating system.
; It waits for user input and interprets it.
; Expects: None
; Returns: None
os_main_loop:
  
  mov bl, PROMPT_USR
  call os_print_prompt
  call os_get_key
  call os_print_chr
  call os_interpret_char

  call os_cursor_pos_get
  push dx
  call os_print_header
  pop dx
  call os_cursor_pos_set

jmp os_main_loop

os_cursor_pos_get: 
  mov ax, 0x0300      ; Get cursor position and size
  xor bh, bh        ; Page 0
  int 0x10          ; Call BIOS
ret

os_cursor_pos_set:
  mov ax, 0x0200      ; Set cursor position
  xor bh, bh        ; Page 0
  int 0x10          ; Call BIOS
ret

os_print_header: 
  cmp dh, 24           ; Check if cursor is on the bottom row (row 24)
  jl .no_bottom_screen
    call os_cursor_pos_reset
    mov al, CHR_SPACE
    mov ah, 160
    call os_print_chr_mul
    mov dx, 0x034F
    jmp .no_reset
  .no_bottom_screen:
    call os_cursor_pos_reset
    mov al, CHR_SPACE
    mov ah, 80
    call os_print_chr_mul
    mov dx, 0x024F
  .no_reset:

  mov ax, 0x0600     ; Function 06h (scroll window up)
  mov bh, COLOR_SECONDARY
  mov cx, 0x0000     ; Top left corner (row 0, col 0)
  int 0x10

  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_40
  je .set_width_40
  mov dl, 28
  mov dh, 80-15
  jmp .continue
  .set_width_40:
    mov dl, 3
    mov dh, 40-15
  .continue:

  ; new line
  mov al, CHR_SPACE
  mov ah, 2
  call os_print_chr_mul
  
  mov si, system_logo_msg
  call os_print_str
  
  mov al, CHR_SPACE
  mov ah, 2
  call os_print_chr_mul

  mov si, os_icons_msg
  call os_print_str

  mov al, CHR_SPACE
  mov ah, dl
  call os_print_chr_mul
  
  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_40
  je .skip_version
    mov si, version_msg
    call os_print_str
    mov al, CHR_SPACE
    call os_print_chr
  .skip_version:

  ; new line

  mov al, GLYPH_CEILING
  call os_print_chr

  mov al, GLYPH_DOWN
  call os_print_chr

  mov al, GLYPH_FLOOR
  mov ah, 9
  call os_print_chr_mul

  mov al, GLYPH_UP
  call os_print_chr

  mov al, GLYPH_CEILING
  call os_print_chr

  mov ax, GLYPH_ICONS_SELECTOR
  call os_print_chr2

  mov al, GLYPH_CEILING
  mov ah, dh
  call os_print_chr_mul

ret

; Print help message ===========================================================
; This function prints the help message to the screen.
; Expects: None
; Returns: None
os_print_help:
  ; Line describing icons
  mov bl, PROMPT_MSG
  call os_print_prompt
  mov si, help_icons_msg
  call os_print_str

  ; Commands header
  mov bl, PROMPT_MSG
  call os_print_prompt
  mov si, help_cmds_msg
  call os_print_str

  ; Listing of all commands
  mov si, os_commands_table
  .cmd_loop:
    lodsb         ; Current character in AL
    test al, al   ; Test if 0, terminator
    jz .done

    mov bl, PROMPT_LIST
    call os_print_prompt          ; Prompt
    call os_print_chr             ; Character printed
    mov al, CHR_SPACE             ; Move space character to AL
    call os_print_chr

    add si, LENGTH_CMDS_TBL_ADDR  ; Skip address, point to description
    call os_print_str             ; Print description string  

    add si, LENGTH_CMDS_TBL_DESC  ; Move to next command
    jmp .cmd_loop
.done:
ret

; Print prompt ================================================================= 
; This function prints the prompt for the user.
; Expects: BL = type of prompt
; Returns: None
os_print_prompt:
  push ax
  ; New line
  mov al, CHR_CR
  mov ah, CHR_LF
  call os_print_chr2
  ; Space
  mov al, CHR_SPACE
  call os_print_chr
  ; Icon
  ; BL <-
  mov al, bl
  call os_print_chr
  ; Space
  mov al, CHR_SPACE
  call os_print_chr
  pop ax
ret

; System shutdown ==============================================================
; This function shuts down or restarts the system.
; Expects: None
; Returns: None
os_down:
  ; Connect to APM API
  mov ax, 5301h
  xor bx, bx        ; Device ID = 0 (APM BIOS)
  int 15h
  
  ; Try to set APM version (1.2)
  mov ax, 530Eh
  xor bx, bx
  mov cx, 0102h     ; APM version 1.2
  int 15h
  
  ; Turn off the system
  mov ax, 5307h
  mov bx, 0001h     ; All devices
  mov cx, 0003h     ; Power off
  int 15h

  mov bl, PROMPT_ERR
  call os_print_prompt
  mov si, unsupported_msg
  call os_print_str
ret

os_restart:
  jmp 0FFFFh:0000h

; System version ===============================================================
; This function returns the version of the kernel.
; Expects: None
; Returns: None
os_print_ver:
  mov bl, PROMPT_SYS_MSG
  call os_print_prompt
  mov si, version_msg
  call os_print_str
ret

; Print welcome message ========================================================
; This function prints the welcome message to the screen.
; Expects: None
; Returns: None
os_print_welcome:
  mov bl, PROMPT_SYS_MSG
  call os_print_prompt
  mov si, welcome_msg
  call os_print_str

  call os_print_ver

  ; Print the copyright message
  mov bl, PROMPT_MSG
  call os_print_prompt
  mov si, copyright_msg
  call os_print_str

  ; Print the more info message
  mov bl, PROMPT_MSG
  call os_print_prompt
  mov si, more_info_msg
  call os_print_str
ret

; Print character ==============================================================
; This function prints a character to the screen.
; Expects: AL = character to print
; Returns: None
os_print_chr:
  push ax
  mov ah, 0x0e    ; BIOS teletype output function
  ; AL <-
  int 0x10        ; BIOS teletype output function
  pop ax
ret

os_print_chr2:
  call os_print_chr
  mov al, ah
  call os_print_chr
ret

os_print_chr_mul:
  push cx  
  movzx cx, ah
  .char_loop:
  call os_print_chr
  loop .char_loop
  pop cx
ret

; Print string =================================================================
; This function prints a string to the screen.
; Expects: DS:SI = pointer to string
; Returns: None
os_print_str:
  pusha
  ; SI <-
  xor bx, bx          ; Clear page number
  mov ah, 0x0e        ; BIOS teletype output function
  .next_char:
    lodsb             ; Load next character from SI into AL
    or al, al         ; Check for null terminator
    jz .terminated
    int 0x10          ; BIOS video interrupt
  jmp near .next_char
  .terminated: 
  popa
ret

; Prints decimal number ========================================================
; This function prints a decimal number to the screen.
; Expects: AX = number to print
; Returns: None
os_print_dec:

ret

; Clear screen =================================================================
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

os_clear_shell:
  call os_clear_screen
  call os_print_header
ret


; Cursor position reset ========================================================
; This function resets the cursor position to the top left of the screen.
; Expects: None
; Returns: None
os_cursor_pos_reset:
  xor dx, dx
  mov ah, 0x2
  xor bh, bh
  int 0x10
ret


; Set color ====================================================================
; This function sets the color of the text on the screen.
; Expects: BL = color attribute
; Returns: None
os_set_color:
  mov ah, 0x0B
  mov bh, 0x00
  ; BL <-
  int 0x10
ret

; Load glyph ===================================================================
; This function loads a custom glyph into the VGA font memory using BIOS.
; Expects: AX = character code to replace, BP = pointer to custom glyph data
; Returns: None
os_load_glyph:
  pusha
  ; AX
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
  add dx, GLYPH_FIRST ; Adjust character code for extended ASCII
  int 10h             ; Call BIOS video interrupt to load the font
  popa
ret

; Load all glyphs ==============================================================
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

; Wait for key press ===========================================================
; This function waits for a key press and returns the key code in AL.
; Expects: None
; Returns: AL = key code
os_get_key:
  xor ax, ax      ; Clear AX (any key)
  int 0x16        ; Wait for key press
  ; AL ->
ret

; Interpret character ==========================================================
; This function interprets the command and performs the appropriate action.
; Expects: AL = character to interpret
; Returns: None
os_interpret_char:
  mov si, os_commands_table
  ; AL <-
  mov bl, al
  .loop_commands:
    lodsb           ; Load next command character
    test al, al     ; Check for end of table
    jz .unknown     ; If end, jump to unknown command
    cmp bl, al
    je .found       ; If found, jump to found command
    add si, LENGTH_CMDS_TBL_ADDR+LENGTH_CMDS_TBL_DESC       ; Move to the next command entry (character, address, desc)
    jmp .loop_commands

  .found:
    lodsw           ; Load next command address
    call ax         ; call the command address
ret

  .unknown:
    mov bl, PROMPT_ERR
    call os_print_prompt
    mov si, unknown_cmd_msg
    call os_print_str
ret

; Initialize mouse and show cursor =============================================
; This function initializes the mouse and shows the cursor
; Expects: None
; Returns: CF=0 if successful, CF=1 if failed
os_mouse_init:
  ; Initialize mouse
  mov ax, 0xC200     ; Initialize mouse
  int 0x15           ; CF=0 if successful
  jc .init_failed
  
  ; Set mouse cursor visibility
  mov ax, 0x0001     ; Function 0x01: Show mouse cursor
  int 0x33           ; Mouse driver function
  
  ; Set mouse cursor shape (optional)
  mov ax, 0x000A     ; Function 0x0A: Set text cursor
  mov bx, 0x0000     ; Software text cursor
  mov cx, 0x7700     ; Screen mask (AND mask)
  mov dx, 0x0077     ; Cursor mask (XOR mask)
  int 0x33
  
  mov bx, PROMPT_SYS_MSG
  call os_print_prompt
  mov si, ps2_mouse_msg
  call os_print_str
  mov si, success_init_msg
  call os_print_str

  clc                ; Clear carry flag (success)
  ret
  
.init_failed:
  mov bx, PROMPT_ERR
  call os_print_prompt
  mov si, ps2_mouse_msg
  call os_print_str
  mov si, failed_init_msg
  call os_print_str

  stc                ; Set carry flag (failure)
  ret

; Print debug info =============================================================
; This function prints debug information.
; Expects: None
; Returns: None
os_print_debug:

  mov bl, PROMPT_MSG
  call os_print_prompt
  
  mov al, GLYPH_FIRST    
  call os_print_chr
  mov cx, 0x1F
  .loop_chars:
    inc al
    call os_print_chr
  loop .loop_chars

  mov bl, PROMPT_MSG
  call os_print_prompt
  mov si, hex_ruler_msg
  call os_print_str
  call os_print_str
  
  mov bl, PROMPT_MSG
  call os_print_prompt

  mov cx, 0x1F
  .loop_chars2:
    inc al
    call os_print_chr
  loop .loop_chars2
  mov bl, PROMPT_MSG
  call os_print_prompt
  mov si, hex_ruler_msg
  call os_print_str
  call os_print_str
ret


os_print_number:
  mov cx, 10000  ; Divisor starting with 10000 (for 5 digits)

  .next_digit:
    xor dx, dx     ; Clear DX for division
    div cx         ; Divide AX by CX, quotient in AX, remainder in DX
    
    ; Convert digit to ASCII
    add al, '0'    ; Convert to ASCII
    
    ; Print the character
    mov ah, 0x0E   ; Teletype output
    push dx        ; Save remainder
    push cx        ; Save divisor
    mov bh, 0      ; Page 0
    int 0x10       ; BIOS video interrupt
    pop cx         ; Restore divisor
    pop dx         ; Restore remainder
    
    ; Move remainder to AX for next iteration
    mov ax, dx
    
    ; Update divisor
    push ax        ; Save current remainder
    mov ax, cx     ; Get current divisor in AX
    xor dx, dx     ; Clear DX for division
    push bx
    mov bx, 10     ; Divide by 10
    div bx         ; AX = AX/10
    pop bx
    mov cx, ax     ; Set new divisor
    pop ax         ; Restore current remainder
    
    ; Check if we're done
    cmp cx, 0      ; If divisor is 0, we're done
    jne .next_digit
  
  ret


os_toggle_video_mode:
  mov al, [_OS_VIDEO_MODE_]
  cmp al, OS_VIDEO_MODE_40
  je .set_video_mode80
  mov al, OS_VIDEO_MODE_40
  jmp .save_video_mode
  .set_video_mode80:
  mov al, OS_VIDEO_MODE_80
  .save_video_mode:
  mov byte [_OS_VIDEO_MODE_], al
  jmp os_reset
ret

; Print statistics =============================================================
; This function prints system statistics.
; Expects: None
; Returns: None
os_print_stats:
 
  ; Get conventional memory size (first 640KB)
  mov bx, GLYPH_MEM
  call os_print_prompt

  mov si, memory_installed_msg
  call os_print_str

  mov ah, 0x12
  int 0x12       ; Returns KB in AX
  call os_print_number

  mov si, kb_msg
  call os_print_str

 ; Check for PS/2 mouse

  mov bx, GLYPH_MOUSE
  call os_print_prompt

  mov si, ps2_mouse_msg
  call os_print_str

  mov ax, 0x0
  int 0x11     
  test ax, 0x03 ; Mouse
  jnz .mouse_not_detected
  mov si, detected_msg
  jmp .mouse_done
  .mouse_not_detected:
  mov si, not_detected_msg
  .mouse_done:
  call os_print_str

  ; Get BIOS date

  mov bx, GLYPH_CAL
  call os_print_prompt
  
  mov si, bios_date_msg
  call os_print_str

  mov ah, 0x0B
  int 0x1A
  call os_print_number

  ; APM functions

  mov bx, GLYPH_BAT
  call os_print_prompt
  
  mov si, apm_batt_msg
  call os_print_str

  mov ax, 530Ah  ; Get Power Status
  mov bx, 0001h  ; All devices
  int 15h        ; Returns battery status in BL, BH
  movzx ax, bl
  call os_print_number
  mov ax, CHR_SPACE
  call os_print_chr
  movzx ax, bh
  call os_print_number

ret

; Data section =================================================================
version_msg           db 'Version alpha4', 0
system_logo_msg       db 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0
welcome_msg           db 'Welcome to SMOLiX Operating System', 0
copyright_msg         db '(C)2025 Krzysztof Krystian Jankowski', 0
more_info_msg         db 'Type "h" for help.', 0
help_icons_msg        db 'Legend: ',PROMPT_SYS_MSG,' system message, ',PROMPT_MSG,' message, ',PROMPT_ERR,' error, ',PROMPT_USR,' user prompt', 0
help_cmds_msg         db 'System character commands:', 0
unknown_cmd_msg       db 'Unknown command', 0
unsupported_msg       db 'Unsupported hardware function', 0
detected_msg          db 'detected', 0
not_detected_msg      db 'not detected', 0
success_init_msg      db 'initialized successfully', 0
failed_init_msg       db 'failed to initialize', 0
os_icons_msg:
dw GLYPH_ICON_SHELL
db CHR_SPACE
dw GLYPH_ICON_RESET
db CHR_SPACE
dw GLYPH_ICON_REBOOT
db CHR_SPACE
dw GLYPH_ICON_DOWN
db CHR_SPACE
dw GLYPH_ICON_EDIT
db CHR_SPACE
dw GLYPH_ICON_CONF
db CHR_SPACE
dw GLYPH_ICON_HOME
db CHR_SPACE
dw GLYPH_ICON_X
db CHR_SPACE
dw GLYPH_ICON_DOTS
db 0  

hex_ruler_msg         db '0123456789ABCDEF', 0
memory_installed_msg  db 'Memory installed: ', 0
kb_msg                db 'KB', 0
ps2_mouse_msg         db 'PS/2 mouse ', 0
bios_date_msg         db 'BIOS date: ', 0
apm_batt_msg          db 'Battery status: ', 0
benchmark_msg         db 'Benchmark score: ', 0

; Commands table ===============================================================
; character (1b) | pointer to function (2b) | description (24b/chars) | terminator (1b)
os_commands_table:
  db 'h'
  dw os_print_help
  db 'Help & list of commands ', 0x0

  db 'v'
  dw os_print_ver
  db 'Prints system version   ', 0x0

  db 'r'
  dw os_reset
  db 'Soft system reset       ', 0x0

  db 'R'
  dw os_restart
  db 'Hard system restart     ', 0x0
  
  db 'D'
  dw os_down
  db 'Shutdown the computer   ', 0x0

  db 'c'
  dw os_clear_shell
  db 'Clear the shell log     ', 0x0  

  db 'x'
  dw os_toggle_video_mode
  db 'Switch mode 80x25, 40x25', 0x0

  db 'm'
  dw os_mouse_init
  db 'Initialize mouse driver ', 0x0
  
  db 's'
  dw os_print_stats
  db 'Prints system statistics', 0x0
  
  db '`'
  dw os_print_debug
  db 'Debugging stuff, charset', 0x0
  
  db 0x0  ; End of table

; Glyphs =======================================================================
; This section includes the glyph definitions
include 'glyphs.asm'
dw 0x0 ; Terminator

; Signature
db "P1X"            ; Use HEX viewer to see `P1X` at the end of binary
