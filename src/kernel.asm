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

OS_VIDEO_MODE_40      equ 0x00  ; default 40x25
OS_VIDEO_MODE_80      equ 0x03  ; 80x25 // 720x400 VGA text mode
_OS_MEMORY_BASE_      equ 0x2000  ; Define memory base address
_OS_TICK_             equ _OS_MEMORY_BASE_+0x0
_OS_VIDEO_MODE_       equ _OS_MEMORY_BASE_+0x4
_OS_NAV_POSITION_     equ _OS_MEMORY_BASE_+0x5

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
GLYPH_RAMP_UP         equ GLYPH_FIRST+0x15
GLYPH_RAMP_DOWN       equ GLYPH_FIRST+0x16
GLYPH_ICONS_SELECTOR  equ 0x9897
GLYPH_ICON_RESET      equ 0x9A99 
GLYPH_ICON_REBOOT     equ 0x9C9B 
GLYPH_ICON_DOWN       equ 0x9E9D 
GLYPH_ICON_SHELL      equ 0xA09F 
GLYPH_ICON_EDIT       equ 0xA2A1
GLYPH_ICON_CONF       equ 0xA4A3 
GLYPH_ICON_CLEAR      equ 0xA6A5
GLYPH_ICON_X          equ 0xA8A7 
GLYPH_ICON_DOTS       equ 0xAAA9 
GLYPH_KBD_LEFT        equ GLYPH_FIRST+0x2B
GLYPH_KBD_UP          equ GLYPH_FIRST+0x2C
GLYPH_KBD_RIGHT       equ GLYPH_FIRST+0x2D
GLYPH_KBD_DOWN        equ GLYPH_FIRST+0x2E

COLOR_PRIMARY         equ 0x1F  
COLOR_SECONDARY       equ 0x2F  
LENGTH_CMDS_TBL_CHAR  equ 1     
LENGTH_FUNCTION_ADDR  equ 2     
LENGTH_DESC_ADDR      equ 2     
LOGO_LENGTH           equ 7

OS_NAV_START_POS      equ 0x0
OS_NAV_LAST_POS       equ 0x8

SOUND_OS_START        equ 1500
SOUND_SUCCESS         equ 1700
SOUND_ERROR           equ 2500

KBD_KEY_LEFT          equ 0x4B
KBD_KEY_RIGHT         equ 0x4D
KBD_KEY_UP            equ 0x48
KBD_KEY_DOWN          equ 0x50
KBD_KEY_ESCAPE        equ 0x01
KBD_KEY_ENTER         equ 0x1C
KBD_KEY_BACKSPACE     equ 0x0E

os_init:
  mov dword [_OS_TICK_], 0  ; Initialize tick count
  mov byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_80
  mov byte [_OS_NAV_POSITION_], OS_NAV_START_POS

; Entry point / System reset ===================================================
; This function resets the system.
; Expects: None
; Returns: None
os_reset:
  mov ah, 0x00		    ; Set video mode
	mov al, [_OS_VIDEO_MODE_]
	int 0x10            ; 80x25 text mode
  
  call os_sound_init
  call os_load_all_glyphs
  call os_clear_screen
  call os_print_header  
  call os_print_welcome
  mov ax, SOUND_OS_START
  call os_sound_play
  mov bl, PROMPT_USR
  call os_print_prompt
  
  call os_print_tick
  
; Main system loop =============================================================
; This is the main loop of the operating system.
; It waits for user input and interprets it.
; Expects: None
; Returns: None
os_main_loop:

  check_keyboard:
    mov ah, 01h         ; BIOS keyboard status function
    int 16h             ; Call BIOS interrupt
    jz .no_key_press

    mov ah, 00h         ; BIOS keyboard read function
    int 16h   

    call os_print_chr  
    call os_interpret_char

    mov bl, PROMPT_USR
    call os_print_prompt
    call os_cursor_pos_get
    push dx
    call os_print_header
    pop dx
    call os_cursor_pos_set
  
  .no_key_press:

  xor ax, ax            ; Function 00h: Read system timer counter
  int 0x1a              ; Returns tick count in CX:DX
  mov bx, dx            ; Store the current tick count
  .wait_loop:
    int 0x1a            ; Read the tick count again
    test dx, bx
    jz .wait_loop

  inc dword [_OS_TICK_]
  call os_print_tick
  call os_sound_stop
  jmp os_main_loop  ; Return to the main loop

; Print System Tick
; This function prints the current system tick count to the screen.
; Expects: None
; Returns: None
os_print_tick:
  call os_cursor_pos_get
  push dx
  
  mov dl, 0x44
  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_80
  jz .skip_40
    mov dl, 0x1C
  .skip_40:
  call os_cursor_pos_set 
  mov ax, [_OS_TICK_+2]
  call os_print_num

  mov al, CHR_SPACE
  call os_print_chr

  mov ax, [_OS_TICK_]
  call os_print_num

  pop dx
  call os_cursor_pos_set
ret

; Gets Cursor Position
; This function gets the current cursor position on the screen.
; Expects: None
; Returns: AX = column, DX = row 
os_cursor_pos_get: 
  mov ax, 0x0300      ; Get cursor position and size
  xor bh, bh        ; Page 0
  int 0x10          ; Call BIOS
ret

; Sets Cursor Pos
; This function sets the cursor position on the screen.
; Expects: AX = column (0-79), DX = row (0-24)
; Returns: None
os_cursor_pos_set:
  mov ax, 0x0200      ; Set cursor position
  xor bh, bh        ; Page 0
  int 0x10          ; Call BIOS
ret

; Print Header =================================================================
; This function prints the header information to the screen.
; Expects: None
; Returns: None
os_print_header:
  mov dx, 0x014F    ; 2 rows, 80 columns
  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_80
  je .set_color
    mov dl, 0x27      ; 40 columns
  .set_color:
  mov ax, 0x0600    ; Function 06h (scroll window up)
  mov bh, COLOR_SECONDARY
  mov cx, 0x0000    ; Top left corner (row 0, col 0)
  int 0x10

  call os_cursor_pos_reset

  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_40
  je .set_width_40
  mov dl, 27
  mov dh, 80-25
  jmp .continue
  .set_width_40:
    mov dl, 2
    mov dh, 40-25
  .continue:
  sub dh, 13

  ; new line
  mov al, CHR_SPACE
  mov ah, CHR_SPACE
  call os_print_chr2
  
  mov si, system_logo_msg
  call os_print_str
  
  mov al, CHR_SPACE
  mov ah, CHR_SPACE
  call os_print_chr2

  call os_print_icons_toolbar

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

  mov al, GLYPH_RAMP_DOWN
  call os_print_chr

  mov al, GLYPH_FLOOR
  mov ah, LOGO_LENGTH
  call os_print_chr_mul

  mov al, GLYPH_RAMP_UP
  call os_print_chr

  mov al, GLYPH_CEILING
  call os_print_chr

  call os_print_icons_selector

  mov al, GLYPH_CEILING
  mov ah, dh
  call os_print_chr_mul

ret

; Print Icons Toolbar
; This function prints the icons in the toolbar.
; Expects: None
; Returns: None
os_print_icons_toolbar:
  push si
  mov si, os_icons_table
  .icons_loop:
    lodsw                     ; Load the next icon character into AL
    test ax, ax               ; Test if 0, terminator
    jz .done_icons            ; If zero, end of icons
    call os_print_chr2         ; Print the icon character
    mov al, CHR_SPACE          ; Move space character to AL
    call os_print_chr
    add si, 0x4             ; Skip function pointer, description pointer
    jmp .icons_loop          ; Repeat for the next icon
  .done_icons:
  pop si
ret

; Print Icons Selector
; This function prints the selected icon in the toolbar.
; Expects: None
; Returns: None 
os_print_icons_selector:
  xor cx, cx
  mov bl, [_OS_NAV_POSITION_]     ; Save current navigation position (selection)
  .icons_loop:
    cmp cl, OS_NAV_LAST_POS
    jg .done_icons                ; If zero, end of icons
    
    cmp cl, bl                    ; Check if current ID is selected
    je .icon_selected
    mov al, GLYPH_CEILING         ; Set two characters
    mov ah, GLYPH_CEILING         ; as empty space
    jmp .print_glyph
    .icon_selected:
    mov ax, GLYPH_ICONS_SELECTOR  ; Set selector icon
    .print_glyph:
    call os_print_chr2            ; Print to the screen
    mov al, GLYPH_CEILING         ; Add another empty space
    call os_print_chr    
    inc cl
    jmp .icons_loop               ; Repeat for the next icon
  .done_icons:
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

    add si, LENGTH_FUNCTION_ADDR  ; Skip address, point to description pointer
    push si                       ; Saves os_commands_table
    mov si, [si]                  ; Gets the description message address
    call os_print_str             ; Print description string  
    pop si                        ; Restore os_commands_table

    add si, LENGTH_DESC_ADDR      ; Move to next command
    jmp .cmd_loop
.done:
ret

; Print prompt ================================================================= 
; This function prints the prompt for the user.
; Expects: BL = type of glyph
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
  ; BL = type of glyph
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

; Reboot System
; This function reboots the system.
; Expects: None
; Returns: None
os_reboot:
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
  ; AL = character to print
  int 0x10        ; BIOS teletype output function
  pop ax
ret

; Print Two Characters =========================================================
; This function prints two characters to the screen.
; Expects: AL = first character, AH = second character
; Returns: None
os_print_chr2:
  ; AL = first character
  call os_print_chr
  ; AH = second character
  mov al, ah
  call os_print_chr
ret

; Print Character Multiple Times ===============================================
; This function prints a character multiple times to the screen.
; Expects: AL = character
;          AH = number of times to print
; Returns: None
os_print_chr_mul:
  push cx  
  ; AH = number of times to print
  movzx cx, ah
  .char_loop:
    ; AL = character
    call os_print_chr
  loop .char_loop
  pop cx
ret

; Print string =================================================================
; This function prints a string to the screen.
; Expects: SI = pointer to string
; Returns: None
os_print_str:
  pusha
  xor bx, bx          ; Clear page number
  mov ah, 0x0e        ; BIOS teletype output function
  .next_char:
    ; SI = pointer to string
    lodsb             ; Load next character from SI into AL
    or al, al         ; Check for null terminator
    jz .terminated
    int 0x10          ; BIOS video interrupt
  jmp near .next_char
  .terminated: 
  popa
ret

; Clear screen =================================================================
; This function clears the screen with primary colors.
; Expects: None
; Returns: None
os_clear_screen:
  pusha
  call os_cursor_pos_reset
  mov ax, 0x0600     ; Function 06h (scroll window up)
  mov bh, COLOR_PRIMARY  ; Set color attribute
  mov cx, 0x0000     ; Top left corner (row 0, col 0)
  mov dx, 0x184F     ; Bottom right corner (row 24, col 79)
  int 0x10
  call os_cursor_pos_reset
  popa
ret

; Clear Shell ==================================================================
; This function clears the shell and resets the display.
; Expects: None
; Returns: None
os_clear_shell:
  call os_clear_screen
  call os_print_header
ret

; Cursor position reset ========================================================
; This function resets the cursor position to the top left of the screen.
; Expects: None
; Returns: None
os_cursor_pos_reset:
  xor dx, dx        ; Page 0
  mov ah, 0x2       ; Set cursor
  xor bh, bh        ; Position 0, 0
  int 0x10
ret

; Set color ====================================================================
; This function sets the color of the text on the screen.
; Expects: BL = color attribute
; Returns: None
os_set_color:
  mov ah, 0x0B
  mov bh, 0x00
  ; BL = color attribute
  int 0x10
ret

; Load glyph ===================================================================
; This function loads a custom glyph into the VGA font memory using BIOS.
; Expects: AX = character code to replace
; Returns: None
os_load_glyph:
  pusha
  ; AX = character code to replace
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
  mov cx, 0x01          ; Number of characters to replace (single)
  pop dx
  add dx, GLYPH_FIRST   ; Adjust character code for extended ASCII
  int 10h               ; Call BIOS video interrupt to load the font
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
    ; AX = character code to replace
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
  ; AL = key code
ret

; Interpret character ==========================================================
; This function interprets the command and performs the appropriate action.
; Expects: AL = character to interpret (letters)
;          AH = character to interpret (control)
; Returns: None
os_interpret_char:
  mov si, os_commands_table
  ; AL = character to interpret
  ; AH = character to interpret (control)
  mov bx, ax
  .loop_commands:
    lodsb           ; Load next command character
    test al, al     ; Check for end of table
    jz .unknown_command
    ; BL = character to interpret
    cmp bl, al
    je .found
    add si, LENGTH_FUNCTION_ADDR+LENGTH_DESC_ADDR
    jmp .loop_commands

  .unknown_command:

  .check_keyboard:
  mov si, os_keyboard_table
  .loop_kbd:
    lodsb
    test al, al
    jz .unknown
    ; BH = character to interpret (control)
    cmp bh, al
    je .found
    add si, LENGTH_FUNCTION_ADDR
  jmp .loop_kbd

  .found:
    mov ax, SOUND_SUCCESS
    call os_sound_play
    lodsw           ; Load next command address
    call ax         ; call the command address   
  ret

  .unknown:
    mov ax, SOUND_ERROR
    call os_sound_play
    movzx dx, bl
    mov bl, PROMPT_ERR
    call os_print_prompt
    mov si, unknown_cmd_msg
    call os_print_str
    mov al, CHR_SPACE
    call os_print_chr
    mov ax, dx
    call os_print_num
  ret

; Selects next icon
; This function selects the next icon in the navigation
; Expects: None
; Returns: None
os_icon_next:
  movzx ax, [_OS_NAV_POSITION_]
  cmp al, OS_NAV_LAST_POS
  jge .bounded
  inc al
  ; AX - icon index
  mov byte [_OS_NAV_POSITION_], al
  call os_icon_print_desc
  .bounded:
ret

; Selects previous icon
; This function selects the previous icon in the navigation
; Expects: None
; Returns: AX - icon index
os_icon_prev:
  movzx ax, [_OS_NAV_POSITION_]  
  cmp al, 0
  jle .bounded
  dec al
  ; AX - icon index
  mov byte [_OS_NAV_POSITION_], al
  call os_icon_print_desc
  .bounded:
ret

; Print icon description
; This function prints the description of the currently selected icon
; Expects: AX - icon index
; Returns: None
os_icon_print_desc:
  ; AX - icon index
  imul ax, 0x6
  mov si, os_icons_table
  add si, ax
  mov si, [si+4]
  call os_print_str
ret

; Executes icon command
; This function executes the command associated with the currently selected icon
; Expects: None
; Returns: None
os_icon_execute:
  movzx ax, [_OS_NAV_POSITION_]
  imul ax, 0x6          ; Calculate the icon index
  mov si, os_icons_table
  add si, ax
  mov ax, [si+2]        ; Load the command pointer
  call ax               ; Execute the command
ret

; Initialize Mouse Driver ======================================================
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
  ; First row
  mov bl, PROMPT_MSG
  call os_print_prompt
  mov al, GLYPH_FIRST    
  call os_print_chr
  mov cx, 0x1F            ; 32 glyphs
  .loop_chars:
    inc al
    call os_print_chr
  loop .loop_chars

  mov bl, PROMPT_MSG
  call os_print_prompt
  mov si, hex_ruler_msg
  call os_print_str
  call os_print_str
  
  ; Second row
  mov bl, PROMPT_MSG
  call os_print_prompt
  mov cx, 0x1F          ; 32 glyphs
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

; Print Number =================================================================
; This function prints a number in decimal format
; Expects: AX - number to print
; Returns: None
os_print_num:
  mov cx, 10000  ; Divisor starting with 10000 (for 5 digits)

  .next_digit:
    xor dx, dx     ; Clear DX for division
    ; AX - number to print
    div cx         ; Divide AX by CX, quotient in AX, remainder in DX
    
    ; Convert digit to ASCII
    add al, '0'    ; Convert to ASCII
    call os_print_chr
    
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
    
    cmp cx, 0      ; If divisor is 0, we're done
  jne .next_digit
  
ret

; Toggle Video Mode ============================================================
; This function toggles between 40 and 80 column video modes
; Expects: None
; Returns: None
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
  int 0x12                  ; Returns KB in AX
  call os_print_num

  mov si, kb_msg
  call os_print_str

  ; Kernel size
  mov bx, GLYPH_MEM
  call os_print_prompt

  mov si, kernel_size_msg
  call os_print_str
  mov ax, os_kernel_end     ; Last place in memory in B
  call os_print_num
  mov si, byte_msg
  call os_print_str

 ; Check for PS/2 mouse
  mov bx, GLYPH_MOUSE
  call os_print_prompt

  mov si, ps2_mouse_msg
  call os_print_str

  mov ax, 0x0
  int 0x11     
  test ax, 0x03             ; Mouse
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
  call os_print_num

  ; Battery status
  mov bx, GLYPH_BAT
  call os_print_prompt  
  mov si, apm_batt_msg
  call os_print_str

  mov ax, 530Ah         ; Get Power Status
  mov bx, 0001h         ; All devices
  int 15h               ; Returns battery status in BL, BH
  movzx ax, bl
  call os_print_num
  mov ax, CHR_SPACE
  call os_print_chr
  movzx ax, bh
  call os_print_num

ret

; Sound Initialization =========================================================
; This function initializes the sound system.
; Expects: None
; Returns: None
os_sound_init:
   mov al, 182         ; Binary mode, square wave, 16-bit divisor
   out 43h, al         ; Write to PIT command register[2]
ret

; Sound Play ===================================================================
; This function sets the sound to play a tone
; Expects: AX = note
; Returns: None
os_sound_play:
  ; AX = note
  out 42h, al         ; Low byte first
  mov al, ah          
  out 42h, al

  in al, 61h          ; Read current port state
  or al, 00000011b    ; Set bits 0 and 1
  out 61h, al         ; Enable speaker output
ret

; Stop sound playback ==========================================================
; This function stops the sound playback
; Expects: None
; Returns: None
os_sound_stop:
  in al, 61h
  and al, 11111100b   ; Clear bits 0-1
  out 61h, al
ret

; Void =========================================================================
; This is a placeholder function
; Expects: None
; Returns: None
os_void:
  nop
ret

; Data section =================================================================
version_msg           db 'Version alpha5', 0
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
hex_ruler_msg         db '0123456789ABCDEF', 0
memory_installed_msg  db 'Memory installed: ', 0
kernel_size_msg       db 'Kernel size: ', 0
kb_msg                db 'KB', 0
byte_msg              db 'B', 0
ps2_mouse_msg         db 'PS/2 mouse ', 0
bios_date_msg         db 'BIOS date: ', 0
apm_batt_msg          db 'Battery status: ', 0
benchmark_msg         db 'Benchmark score: ', 0

msg_cmd_h             db 'Help & list of commands', 0x0
msg_cmd_v             db 'Prints system version', 0x0
msg_cmd_r             db 'Soft system reset', 0x0
msg_cmd_R             db 'Hard system reboot', 0x0
msg_cmd_D             db 'Shutdown the computer', 0x0
msg_cmd_c             db 'Clear the shell log', 0x0  
msg_cmd_x             db 'Toggle between 40 and 80 screen modes', 0x0    ; Added description for msg_cmd_x 
msg_cmd_m             db 'Initialize mouse driver', 0x0  ; Added description for msg_cmd_m 
msg_cmd_s             db 'Print system statistics', 0x0  ; Added description for msg_cmd_s
msg_cmd_tilde         db 'Debugging stuff, charset', 0x0
msg_cmd_void          db 'Void. Not implemented yet.', 0x0

; Icons table ==================================================================
; pointer to icon (2b) | pointer to function (2b)
os_icons_table:
  dw GLYPH_ICON_CLEAR, os_clear_shell, msg_cmd_c
  dw GLYPH_ICON_SHELL, os_void, msg_cmd_void
  dw GLYPH_ICON_EDIT, os_void, msg_cmd_void
  dw GLYPH_ICON_CONF, os_print_stats, msg_cmd_s
  dw GLYPH_ICON_X, os_toggle_video_mode, msg_cmd_x  ; Added description for msg_cmd_x
  dw GLYPH_ICON_DOTS, os_print_debug, msg_cmd_tilde
  dw GLYPH_ICON_RESET, os_reset, msg_cmd_r
  dw GLYPH_ICON_REBOOT, os_reboot, msg_cmd_R
  dw GLYPH_ICON_DOWN, os_down, msg_cmd_D
  dw 0x0

; Commands table ===============================================================
; character (1b) | pointer to function (2b) | description (24b/chars)
os_commands_table:
  db 'h'
  dw os_print_help, msg_cmd_h

  db 'v'
  dw os_print_ver, msg_cmd_v
  
  db 'r'
  dw os_reset, msg_cmd_r
  
  db 'R'
  dw os_reboot, msg_cmd_R
    
  db 'D'
  dw os_down, msg_cmd_D
  
  db 'c'
  dw os_clear_shell, msg_cmd_c
  
  db 'x'
  dw os_toggle_video_mode, msg_cmd_x

  db 'm'
  dw os_mouse_init, msg_cmd_m
  
  db 's'
  dw os_print_stats, msg_cmd_s
  
  db '`'
  dw os_print_debug, msg_cmd_tilde
  
  db 0x0

os_keyboard_table:
  db KBD_KEY_RIGHT
  dw os_icon_next
  db KBD_KEY_LEFT
  dw os_icon_prev
  db KBD_KEY_ENTER
  dw os_icon_execute
  db 0x0

; Glyphs =======================================================================
; This section includes the glyph definitions
include 'glyphs.asm'
dw 0x0 ; Terminator

db "P1X"            ; Use HEX viewer to see `P1X` at the end of binary
os_kernel_end: