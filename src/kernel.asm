; SMOLiX: Real Mode, Raw Power.
; This is the kernel.
; It is a simple kernel that runs in real mode as god intended.
; Copyright (C) 2025 Krzysztof Krystian Jankowski
; This program is free software. See LICENSE for details.

org 0x0000
use16

GLYPH_FIRST           equ 0x80
PROMPT_MSG            equ GLYPH_FIRST+0xC
PROMPT_SYS_MSG        equ GLYPH_FIRST+0xE
PROMPT_STATUS         equ GLYPH_FIRST+0xA
PROMPT_ERR            equ GLYPH_FIRST+0xB
PROMPT_USR            equ GLYPH_FIRST+0xD
CHR_SPACE             equ GLYPH_FIRST
CHR_CR                equ 0x0D
CHR_LF                equ 0x0A
PROMPT_END            equ GLYPH_FIRST+0x9
COLOR_PRIMARY         equ 0x1F  ; White on blue
LENGTH_CMDS_TBL_CHAR  equ 1     ; Command character
LENGTH_CMDS_TBL_ADDR  equ 2     ; Address to function
LENGTH_CMDS_TBL_DESC  equ 24+1  ; Description length + terminator character

; Entry point / System reset ===================================================
; This function resets the system.
; Expects: None
; Returns: None
os_reset:
  mov ah, 0x00		    ; Set video mode
	mov al, 0x03		    ; 720x400 VGA text mode
	int 0x10            ; 80x25 text mode
  
  call os_load_all_glyphs
  call os_clear_screen
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
  
jmp os_main_loop

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

    mov bl, PROMPT_MSG
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
  call os_print_chr
  mov al, CHR_LF
  call os_print_chr
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

  mov al, PROMPT_END
  int 0x10
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

; Cursor position reset ========================================================
; This function resets the cursor position to the top left of the screen.
; Expects: None
; Returns: None
os_cursor_pos_reset:
  xor dx, dx
  mov ah, 0x2
  mov bh, 0x0
  int 0x10
ret

; Set cursor position ==========================================================
; This function sets the cursor position on the screen.
; Expects: DX = position (row * 80 + col)
; Returns: None
os_cursor_set_pos:
  mov ah, 0x02
  mov bh, 0x00
  ; DH <-
  ; DL <-
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

; Print debug info =============================================================
; This function prints debug information.
; Expects: None
; Returns: None
os_print_debug:
  mov bl, PROMPT_MSG
  call os_print_prompt
  mov al, GLYPH_FIRST
  call os_print_chr
  mov cx, 0xF
  .loop_chars:
    inc al
    call os_print_chr
  loop .loop_chars

  mov bl, PROMPT_MSG
  call os_print_prompt
  mov si, hex_ruler_msg
  call os_print_str
ret

; Print statistics =============================================================
; This function prints system statistics.
; Expects: None
; Returns: None
os_print_stats:
  ; Print available memory
  mov bx, PROMPT_STATUS
  call os_print_prompt

  mov ah, 0x88
  int 0x15      ; AX now contains KB of extended memory (above 1MB) 
  add ax, 640   ; Add conventional memory (640KB) to display total
  call os_print_chr
  mov al, ah
  call os_print_chr

  mov si, memory_available_msg
  call os_print_str
ret

; Data section =================================================================
version_msg         db 'Version alpha3', 0
welcome_msg         db 'Welcome to ', 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, ' Operating System', 0
copyright_msg       db '(C) 2025 Krzysztof Krystian Jankowski', 0
more_info_msg       db 'Type "h" for help. Read more at smol.p1x.in/smolix/', 0
help_icons_msg         db 'Legend: ',PROMPT_SYS_MSG,' system message, ',PROMPT_MSG,' message, ',PROMPT_STATUS,' return status, ',PROMPT_USR,' user prompt', 0
help_cmds_msg       db 'List of system character commands', 0
unknown_cmd_msg     db 'Unknown command', 0
hex_ruler_msg       db '0123456789ABCDEF', 0
memory_available_msg  db 'KB available memory', 0

; Commands table ===============================================================
os_commands_table:
  db 'h'
  dw os_print_help
  db 'Help & list of commands ', 0x0
  db 'v'
  dw os_print_ver
  db 'System version number   ', 0x0
  db 'r'
  dw os_reset
  db 'Soft system reset       ', 0x0
  db 'R'
  dw os_restart
  db 'Hard system restart     ', 0x0
  db 'D'
  dw os_down
  db 'Shutdown the computer   ', 0x0
  db 's'
  dw os_print_stats
  db 'System statistics       ', 0x0
  db 'd'
  dw os_print_debug
  db 'Debugging stuff         ', 0x0
  db 0x0  ; End of table

; Glyphs =======================================================================
; This section includes the glyph definitions
include 'glyphs.asm'
dw 0x0 ; Terminator

; Signature
db "P1X"            ; Use HEX viewer to see `P1X` at the end of binary
