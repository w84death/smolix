; SMOLiX: Real Mode, Raw Power.
; It is a simple kernel that runs in real mode as God intended.
; Copyright (C) 2025 Krzysztof Krystian Jankowski
; This is free and open software. See LICENSE for details.

; Tested hardware:
; CPU: 486 DX4, 100Mhz
; Graphics: VGA
; RAM: 24MB
;
; Teoretical minimum requirements:
; CPU: 386 SX, 20Mhz
; Graphics: EGA Enchanced (8x16)
; RAM: 512KB

org 0x0000

_OS_MEMORY_BASE_                equ 0x2000    ; Define memory base address
_OS_TICK_                       equ _OS_MEMORY_BASE_ + 0x00
_OS_VIDEO_MODE_                 equ _OS_MEMORY_BASE_ + 0x04
_OS_STATE_                      equ _OS_MEMORY_BASE_ + 0x05
_OS_TOOLBAR_STATE_              equ _OS_MEMORY_BASE_ + 0x06
_OS_TOOLBAR_SELECTED_           equ _OS_MEMORY_BASE_ + 0x07   ; 2b
_OS_MOUSE_                      equ _OS_MEMORY_BASE_ + 0x09   ; 6b
_OS_FS_BUFFER_                  equ _OS_MEMORY_BASE_ + 0x10

OS_STATE_INIT                   equ 0x01
OS_STATE_SPLASH_SCREEN          equ 0x02
OS_STATE_SHELL                  equ 0x03
OS_STATE_FS                     equ 0x04
OS_STATE_SETTINGS               equ 0x05
OS_VIDEO_MODE_40                equ 0x00      ; 40x25
OS_VIDEO_MODE_80                equ 0x03      ; 80x25

OS_TOOLBAR_STATE_MAIN           equ 0x01
OS_TOOLBAR_STATE_SHELL          equ 0x02
OS_TOOLBAR_STATE_FS             equ 0x03
OS_TOOLBAR_STATE_HELP           equ 0x04
OS_TOOLBAR_TABLE_ENTRY_SIZE     equ 0x08

OS_FS_BLOCK_FIRST               equ 0x11
OS_FS_BLOCK_SIZE                equ 0x10
OS_FS_FILE_SIZE                 equ 8192
OS_FS_FILE_LINES_ON_SCREEN      equ 0x15
OS_FS_FILE_CHARS_ON_LINE_80     equ 80-1
OS_FS_FILE_CHARS_ON_LINE_40     equ 40-1
OS_FS_FILE_SCROLL_CHARS         equ 160
OS_FS_FILE_ID_MANUAL            equ 0x00
OS_FS_FILE_ID_LEM               equ 0x01

OS_COLOR_PRIMARY                equ 0x1F
OS_COLOR_SECONDARY              equ 0x2F
OS_LENGTH_BYTE                  equ 0x01
OS_LENGTH_WORD                  equ 0x02
OS_LENGTH_WORD                  equ 0x02
OS_LOGO_LENGTH                  equ 0x07

OS_SOUND_STARTUP                equ 1500
OS_SOUND_SUCCESS                equ 1700
OS_SOUND_ERROR                  equ 2500

OS_MOUSE_SLOWDOWN               equ 0x02
OS_MOUSE_ENABLED                equ 0x00
OS_MOUSE_X                      equ 0x01
OS_MOUSE_Y                      equ 0x03
OS_MOUSE_BTN                    equ 0x05

OS_GLYPH_ADDRESS                equ 0x80
; LOGO                              0x80 - 0x86
GLYPH_MASCOT                    equ 0x87
GLYPH_SYSTEM                    equ 0x88
GLYPH_ERROR                     equ 0x89
GLYPH_MSG                       equ 0x8A
GLYPH_PROMPT                    equ 0x8B
GLYPH_MOUSE                     equ 0x8C
GLYPH_FLOPPY                    equ 0x8D
GLYPH_CAL                       equ 0x8E
GLYPH_MEM                       equ 0x8F
GLYPH_BAT                       equ 0x90
GLYPH_CURSOR                    equ 0x91
GLYPH_CEILING                   equ 0x92
GLYPH_FLOOR                     equ 0x93
GLYPH_RAMP_UP                   equ 0x94
GLYPH_RAMP_DOWN                 equ 0x95
GLYPH_ICONS_SELECTOR            equ 0x9796
GLYPH_ICON_RESET                equ 0x9998
GLYPH_ICON_REBOOT               equ 0x9B9A
GLYPH_ICON_DOWN                 equ 0x9D9C
GLYPH_ICON_BACK                 equ 0x9F9E
GLYPH_ICON_EDIT                 equ 0xA1A0
GLYPH_ICON_CONF                 equ 0xA3A2
GLYPH_ICON_SHELL                equ 0xA5A4
GLYPH_ICON_X                    equ 0xA7A6
GLYPH_ICON_HELP                 equ 0xA9A8
GLYPH_ICON_FLOPPY               equ 0xABAA
GLYPH_RULER_START               equ 0xAC
GLYPH_RULER_MIDDLE              equ 0xAD
GLYPH_RULER_END                 equ 0xAE
GLYPH_RULER_NO                  equ 0xAF
; Ruler numbers 10-70               0xB0 - 0xB5
GLYPH_ICON_FS_READ              equ 0xB7B6
GLYPH_ICON_FS_WRITE             equ 0xB9B8
GLYPH_ICON_FS_LIST              equ 0xBBBA
GLYPH_ICON_PAINT                equ 0xBDBC
GLYPH_16BIT_1                   equ 0xBE
GLYPH_16BIT_2                   equ 0xBF
GLYPH_16BIT_3                   equ 0xC0
; C1-C5 game sprites

CHR_SPACE                       equ ' '
CHR_CR                          equ 0x0D
CHR_LF                          equ 0x0A
CHR_NEW_LINE                    equ 0x0A0D
CHR_LIST                        equ 0x1A
CHR_SLASH                       equ '/'
KBD_KEY_LEFT                    equ 0x4B
KBD_KEY_RIGHT                   equ 0x4D
KBD_KEY_UP                      equ 0x48
KBD_KEY_DOWN                    equ 0x50
KBD_KEY_ESCAPE                  equ 0x01
KBD_KEY_ENTER                   equ 0x1C
KBD_KEY_BACKSPACE               equ 0x0E

; Initialize OS ================================================================
; This is the main entry
os_init:
  mov byte [_OS_STATE_], OS_STATE_INIT
  mov byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_40
  mov dword [_OS_TICK_], 0  ; Initialize tick count
  call os_sound_init

; Entry point / System reset ===================================================
; This function resets the system.
; Expects: None
; Returns: None
os_reset:
  mov ah, 0x00		    ; Set video mode
	mov al, [_OS_VIDEO_MODE_]
	int 0x10            ; 80x25 text mode
  call os_load_all_glyphs

  mov byte [_OS_TOOLBAR_STATE_], OS_TOOLBAR_STATE_MAIN
  mov word [_OS_TOOLBAR_SELECTED_], os_toolbar_table

  call os_mouse_init
  setc [_OS_MOUSE_+OS_MOUSE_ENABLED]

  mov ax, OS_SOUND_STARTUP
  call os_sound_play
  call os_clear_screen
  call os_print_splash_screen
  mov byte [_OS_STATE_], OS_STATE_SPLASH_SCREEN

; Main system loop =============================================================
; This is the main loop of the operating system.
; It waits for user input and interprets it.
; Expects: None
; Returns: None
os_main_loop:

  check_keyboard:
    mov ah, 01h         ; BIOS keyboard status function
    int 16h             ; Call BIOS interrupt
    jz .done

    mov ah, 00h         ; BIOS keyboard read function
    int 16h

    cmp byte [_OS_STATE_], OS_STATE_FS
    je .no_command_key
    cmp byte [_OS_STATE_], OS_STATE_SPLASH_SCREEN
    je .no_command_key

    test al, al
    jz .no_command_key
      call os_print_chr
      call os_interpret_char

      mov bl, GLYPH_PROMPT
      call os_print_prompt
      jmp .continue

    .no_command_key:
      call os_interpret_kb

    .continue:
      cmp byte [_OS_STATE_], OS_STATE_SPLASH_SCREEN
      je .print_splash

    .print_header:
      call os_cursor_pos_get
      push dx
      call os_print_header
      pop dx
      call os_cursor_pos_set
      jmp .done

    .print_splash:
      call os_print_splash_screen

    .done:

    .mouse:
      cmp byte [_OS_MOUSE_+OS_MOUSE_ENABLED], 0x0
      je .skip_mouse
        call os_mouse_poll
        call os_print_mouse_cursor
      .skip_mouse:


    .cpu_delay:
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
  mov eax, [_OS_TICK_]
  mov cx, 0x08
  call os_print_num

  pop dx
  call os_cursor_pos_set
ret


os_print_mouse_cursor:
  call os_cursor_pos_get
  push dx
  mov ax, [_OS_MOUSE_+OS_MOUSE_X]
  shr ax, OS_MOUSE_SLOWDOWN
  mov bx, [_OS_MOUSE_+OS_MOUSE_Y]
  shr bx, OS_MOUSE_SLOWDOWN
  mov dl, al
  mov dh, bl
  call os_cursor_pos_set
  mov al, GLYPH_CURSOR
  call os_print_chr
  pop dx
  call os_cursor_pos_set
ret


; Gets Cursor Position
; This function gets the current cursor position on the screen.
; Expects: None
; Returns: DX = column, DX = row
os_cursor_pos_get:
  mov ax, 0x0300    ; Get cursor position and size
  xor bh, bh        ; Page 0
  int 0x10          ; Call BIOS
ret

; Sets Cursor Pos
; This function sets the cursor position on the screen.
; Expects: DX = column (0-79), DX = row (0-24)
; Returns: None
os_cursor_pos_set:
  mov ax, 0x0200    ; Set cursor position
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
  mov bh, OS_COLOR_SECONDARY
  mov cx, 0x0000    ; Top left corner (row 0, col 0)
  int 0x10

  call os_cursor_pos_reset

  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_40
  je .set_width_40
  mov dl, 41+15
  mov dh, 82
  jmp .continue
  .set_width_40:
    mov dl, 16+15
    mov dh, 42
  .continue:
  sub dh, 13

  ; new line
  mov al, GLYPH_MASCOT
  mov ah, CHR_SPACE
  call os_print_chr_double

  mov si, system_logo_msg
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

  mov al, GLYPH_RAMP_DOWN
  call os_print_chr

  mov al, GLYPH_FLOOR
  mov ah, 2
  call os_print_chr_mul

  mov al, GLYPH_16BIT_1
  mov ah, GLYPH_16BIT_2
  call os_print_chr_double
  mov al, GLYPH_16BIT_3
  call os_print_chr

  mov al, GLYPH_FLOOR
  mov ah, 2
  call os_print_chr_mul

  mov al, GLYPH_RAMP_UP
  call os_print_chr

  mov al, GLYPH_CEILING
  call os_print_chr

  mov al, GLYPH_CEILING
  mov ah, dh
  call os_print_chr_mul


  call os_print_toolbar
ret

; Print Error Status ===========================================================
; This function prints the status of the last operation.
; Expects: CF = clear for success, set for error
; Returns: None
os_print_error_status:
  pusha
  jc .error
  mov si, success_msg
  jmp .success
  .error:
  mov si, failure_msg
  .success:
  call os_print_str
  popa
ret

; Print help message ===========================================================
; This function prints the help message to the screen.
; Expects: None
; Returns: None
os_print_help:
  mov bl, GLYPH_MSG
  call os_print_prompt
  mov si, help_line1_msg
  call os_print_str

  call os_print_prompt
  mov si, help_line3_msg
  call os_print_str

  ; Listing of all commands
  mov si, os_commands_table
  .cmd_loop:
    lodsb         ; Current character in AL
    test al, al   ; Test if 0, terminator
    jz .done

    mov bl, CHR_LIST
    call os_print_prompt          ; Prompt
    cmp al, '!'                   ; First character in ASCII table
    jl .done                      ; Skip if not a character (enter, arrows)
    call os_print_chr             ; Character printed
    mov al, CHR_SPACE             ; Move space character to AL

    call os_print_chr

    add si, OS_LENGTH_WORD  ; Skip address, point to description pointer
    push si                       ; Saves os_commands_table
    mov si, [si]                  ; Gets the description message address
    call os_print_str             ; Print description string
    pop si                        ; Restore os_commands_table

    add si, OS_LENGTH_WORD      ; Move to next command
    jmp .cmd_loop
.done:
ret

os_load_and_read_manual:
  call os_fs_file0_read
  call os_fs_file_display
ret

; Print prompt =================================================================
; This function prints the prompt for the user.
; Expects: BL = type of glyph
; Returns: None
os_print_prompt:
  push ax
  ; New line
  mov ax, CHR_NEW_LINE
  call os_print_chr_double
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

  mov bl, GLYPH_ERROR
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
  mov bl, GLYPH_SYSTEM
  call os_print_prompt
  mov si, version_msg
  call os_print_str
ret

; Print welcome message ========================================================
; This function prints the welcome message to the screen.
; Expects: None
; Returns: None
os_print_welcome_shell:
  mov bl, GLYPH_SYSTEM
  call os_print_prompt
  mov si, welcome_msg
  call os_print_str

  ; Print the copyright message
  mov bl, GLYPH_MSG
  call os_print_prompt
  mov si, copyright_msg
  call os_print_str

  ; Print the more info message
  mov bl, GLYPH_MSG
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
os_print_chr_double:
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
  mov bh, OS_COLOR_PRIMARY  ; Set color attribute
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
  pusha
  call os_clear_screen
  call os_print_header
  popa
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
; Expects: AL = character code to replace
; Returns: None
os_load_glyph:
  pusha
  ; AL = character code to replace
  movzx bx, al          ; Move character code to BX, clears AH
  push bx               ; Save character code
  shl bx, 1             ; Multiply by 2 (each entry is 2 bytes)
  mov bp, [glyph_table + bx]  ; Get pointer to the right entry
  push ds
  pop es                ; Ensure ES = DS (BIOS expects ES:BP for font data)
  mov ax, 1100h         ; BIOS function to load 9×16 user-defined font
  mov bh, 10h           ; Number of bytes per character (16 for 8/9×16 glyph)
  mov bl, 00h           ; RAM block (0 for default)
  mov cx, 0x01          ; Number of characters to replace (single)
  pop dx                ; Restore character code
  add dx, OS_GLYPH_ADDRESS   ; Adjust character code for extended ASCII
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
; Returns: None
os_interpret_char:
  mov si, os_commands_table
  ; AL = character to interpret
  mov bl, al
  .loop_commands:
    lodsb           ; Load next command character
    test al, al     ; Check for end of table
    jz .unknown
    ; BL = character to interpret
    cmp bl, al
    je .found
    lea si, [si + OS_LENGTH_WORD+OS_LENGTH_WORD]
    jmp .loop_commands

  .found:
    lodsw           ; Load next command address
    call ax         ; call the command address
    mov ax, OS_SOUND_SUCCESS
    call os_sound_play
  ret

  .unknown:
    mov ax, OS_SOUND_ERROR
    call os_sound_play
    movzx dx, bl
    mov bl, GLYPH_ERROR
    call os_print_prompt
    mov si, unknown_cmd_msg
    call os_print_str
    mov al, CHR_SPACE
    call os_print_chr
    mov ax, dx
    call os_print_num
  ret

os_interpret_kb:
  mov si, os_keyboard_table
  ; AH = character to interpret (control)
  mov bl, ah
  mov bh, [_OS_STATE_]
  .loop_kbd:
    lodsb
    test al, al
    jz .unknown
    cmp al, bh
    jne .skip_kb
    lodsb
    cmp bl, al
    je .found
    jmp .next_entry
    .skip_kb:
    add si, OS_LENGTH_BYTE
    .next_entry:
    add si, OS_LENGTH_WORD
  jmp .loop_kbd

  .found:
    lodsw           ; Load next command address
    call ax         ; call the command address
    mov ax, OS_SOUND_SUCCESS
    call os_sound_play
  ret

  .unknown:
    mov ax, OS_SOUND_ERROR
    call os_sound_play
  ret

; Print debug info =============================================================
; This function prints debug information.
; Expects: None
; Returns: None
os_print_debug:
mov dx, 0
mov cx, 0x03
  .looper:
    push cx
    mov bl, GLYPH_MSG
    call os_print_prompt
    mov al, OS_GLYPH_ADDRESS
    add al, dl
    call os_print_chr
    mov cx, 0x1F            ; 32 glyphs
    .loop_chars:
      inc al
      call os_print_chr
    loop .loop_chars

    mov bl, GLYPH_MSG
    call os_print_prompt
    mov si, hex_ruler_msg
    call os_print_str
    call os_print_str

    add dx, 0x20
    pop cx
  loop .looper
ret

; Print Number =================================================================
; This function prints a number in decimal format
; Expects: EAX - number to print
; Returns: None
os_print_num:
  pusha
  mov ecx, 1000000000
  ; Skip leading zeros
   mov ebx, 0          ; Flag to track if we've started printing

  .next_digit:
    xor edx, edx     ; Clear EDX for division
    ; EAX - number to print
    div ecx         ; Divide EAX by ECX, quotient in EAX, remainder in EDX

    ; Handle leading zeros (skip them until first non-zero digit)
    test ebx, ebx     ; Check if we've started printing digits
    jnz .print_digit  ; If yes, print this digit

    test eax, eax     ; Is the quotient zero?
    jz .skip_zero     ; If it's a leading zero, skip it
    mov ebx, 1        ; Set flag to start printing digits

  .print_digit:
    add al, '0'    ; Convert to ASCII
    push edx          ; Save remainder
    call os_print_chr
    pop edx           ; Restore remainder

  .skip_zero:
    mov eax, edx      ; Move remainder to EAX for next iteration

    ; Update divisor
    push eax        ; Save current remainder
    mov eax, ecx     ; Get current divisor in EAX
    xor edx, edx     ; Clear EDX for division
    push ebx
    mov ebx, 10     ; Divide by 10
    div ebx         ; EAX = EAX/10
    pop ebx
    mov ecx, eax     ; Set new divisor
    pop eax         ; Restore current remainder

    test ecx, ecx      ; If divisor is 0, we're done
    jne .next_digit

  .print_zero_value:
    test ebx, ebx
    jnz .done
    mov al, '0'
    call os_print_chr

  .done:
  popa
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

  mov bl, GLYPH_SYSTEM
  call os_print_prompt
  mov si, cpu_family_msg
  call os_print_str
  call os_print_cpuid

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

  ; Get BIOS date
  mov bx, GLYPH_CAL
  call os_print_prompt
  mov si, bios_date_msg
  call os_print_str

  mov ah, 0x0B
  int 0x1A
  jc .unsuported

  movzx ax, cl
  call os_print_bcd
  mov al, CHR_SLASH
  call os_print_chr
  movzx ax, dh
  call os_print_bcd
  mov al, CHR_SLASH
  call os_print_chr
  movzx ax, dl
  call os_print_bcd
  jmp .supported
  .unsuported:
  mov si, unsupported_msg
  call os_print_str
  .supported:

  ; Battery status
  mov bx, GLYPH_BAT
  call os_print_prompt
  mov si, apm_batt_msg
  call os_print_str

  mov ax, 530Ah         ; Get Power Status
  mov bx, 0001h         ; All devices
  int 15h               ; Returns battery status in BL, BH

  cmp bl, 0xFF
  je .apm_unsuported

  test bl, bl
  jz .ac_power

  movzx ax, cl
  call os_print_num
  mov si, apm_batt_life
  call os_print_str
  jmp .apm_done

  .ac_power:
    mov si, apm_batt_ac
    call os_print_str
    jmp .apm_done
  .apm_unsuported:
    mov si, unsupported_msg
    call os_print_str
  .apm_done:

  mov bx, GLYPH_MOUSE
  call os_print_prompt
  mov si, mouse_msg
  call os_print_str

  cmp byte [_OS_MOUSE_+OS_MOUSE_ENABLED], 0x0
  jz .mouse_unsupported
  mov ax, [_OS_MOUSE_+OS_MOUSE_X]
  call os_print_num
  mov al, CHR_SLASH
  call os_print_chr
  mov ax, [_OS_MOUSE_+OS_MOUSE_Y]
  call os_print_num
  jmp .mouse_done
  .mouse_unsupported:
    mov si, unsupported_msg
    call os_print_str
  .mouse_done:
ret


os_print_bcd:
  push ax                ; Save the original BCD value
  shr al, 4              ; Get high nibble
  add al, '0'            ; Convert to ASCII
  call os_print_chr      ; Print it
  pop ax                 ; Restore the original BCD value
  and al, 0x0F           ; Get low nibble
  add al, '0'            ; Convert to ASCII
  call os_print_chr      ; Print it
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

os_fs_file0_read:
  mov dl, 0
  call os_fs_file_read
ret

os_fs_file1_read:
  mov dl, 1
  call os_fs_file_read
ret

; File System:
os_fs_file_read:
  mov word [os_fs_file_pos], 0
  cmp byte [os_fs_file_loaded], dl
  je .already_loaded
  call os_fs_file_load
  call os_print_error_status
  .already_loaded:
  mov word [os_fs_file_pos], 0
ret

; File System: load file =======================================================
; This function loads a file from the floppy disk to a memory
; Expects: DL = File number
; Returns: CF = 0 on success, CF = 1 on failure
os_fs_file_load:

  mov byte [os_fs_file_loaded], dl

  mov bl, GLYPH_FLOPPY
  call os_print_prompt
  mov si, fs_reading_msg
  call os_print_str

  ; Reset disk system first
  xor ax, ax
  int 0x13               ; Reset disk system
  jc .disk_error

  movzx bx, dl
  shl bx, 1
  mov dx, [os_fs_directory_table + bx]       ; Load effective address with offset

  mov ax, ds
  mov es, ax              ; Make sure ES=DS for disk read
  mov bx, _OS_FS_BUFFER_

  mov ah, 0x02            ; BIOS read sectors function
  mov al, OS_FS_BLOCK_SIZE
  mov ch, 0               ; Cylinder 0
  mov cl, dl              ; Starting sector (file block)
  mov dl, 0x00            ; Drive 0 (first floppy drive)
  int 0x13                ; BIOS disk interrupt
  jc .disk_error          ; Error if carry flag set

  clc                     ; Clear carry flag (success)
  ret

  .disk_error:
    mov byte [os_fs_file_loaded], 0xFF
    stc                   ; Set carry flag (error)
    ret

; File System: display file ====================================================
; This function displays the loaded file contents from memory to the screen
; Expects: None
; Returns: None
os_fs_file_display:
  mov si, _OS_FS_BUFFER_
  add si, [os_fs_file_pos]  ; Add current scroll position

  cmp byte [si], 0          ; Check if the current character is null
  je .empty_file

  mov byte [_OS_STATE_], OS_STATE_FS
  call os_clear_shell

  ; Calculate end of buffer for bounds checking
  lea di, [_OS_FS_BUFFER_ + OS_FS_FILE_SIZE]

  mov cx, OS_FS_FILE_LINES_ON_SCREEN
  mov dl, OS_FS_FILE_CHARS_ON_LINE_80
  push si
  mov si, fs_ruler_80_msg
  .video_mode_adjust:
    cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_40
    jne .done_video_mode_adjust
    mov dl, OS_FS_FILE_CHARS_ON_LINE_40
    mov si, fs_ruler_40_msg
  .done_video_mode_adjust:
  call os_print_str
  pop si

  .line_loop:
    xor dh, dh  ; Move cursor to line 0

    .char_loop:
      cmp si, di
      jge .done               ; Reached end of buffer data

      lodsb

      test al, al
      jz .done                ; Last character

      cmp al, CHR_CR          ; Check for Carriage Return (CR)
      je .char_loop           ; Ignore CR, get next char

      cmp al, CHR_LF          ; Check for Line Feed (LF)
      je .newline             ; LF found, handle end of line

      call os_print_chr       ; Print the character
      inc dh

      cmp dh, dl              ; Check if line is full
      jl .char_loop           ; Line not full, continue reading chars
      jmp .newline

    .newline:
      dec cx                  ; Decrement line counter (one line finished)
      jz .done                ; Last line

      mov ax, CHR_NEW_LINE
      call os_print_chr_double
    jmp .line_loop

  .done:
    mov bl, GLYPH_FLOPPY
    call os_print_prompt
    mov ax, [os_fs_file_pos]
    mov cx, 0x03
    call os_print_num
    mov si, byte_msg
    call os_print_str
ret
  .empty_file:
    mov bl, GLYPH_ERROR
    call os_print_prompt
    mov si, fs_empty_msg
    call os_print_str
ret

; File System: scroll up =======================================================
os_fs_scroll_up:
  cmp word [os_fs_file_pos], OS_FS_FILE_SCROLL_CHARS
  jl .done
  sub word [os_fs_file_pos], OS_FS_FILE_SCROLL_CHARS
  call os_fs_file_display
  .done:
ret

; File System: scroll Down =====================================================
os_fs_scroll_down:
  cmp word [os_fs_file_pos], OS_FS_FILE_SIZE-OS_FS_FILE_SCROLL_CHARS
  jg .done

  mov si, _OS_FS_BUFFER_
  add si, [os_fs_file_pos]
  add si, OS_FS_FILE_SCROLL_CHARS
  cmp byte [si], 0          ; Check if the current character is null
  je .done

  add word [os_fs_file_pos], OS_FS_FILE_SCROLL_CHARS
  call os_fs_file_display
  .done:
ret

; File System: file write ======================================================
; This function writes data to a file on the disk
; Expects: None
; Returns: CF = 0 on success, CF = 1 on error
os_fs_file_write:
  mov bx, GLYPH_FLOPPY
  call os_print_prompt
  mov si, fs_writing_msg
  call os_print_str

  ; Reset disk system first
  xor ax, ax
  int 0x13               ; Reset disk system
  jc .write_error

  ; Set up ES:BX for disk write
  mov ax, ds
  mov es, ax
  mov bx, _OS_FS_BUFFER_

  ; Set up disk write parameters
  mov ah, 0x03           ; BIOS write sectors function
  mov al, OS_FS_BLOCK_SIZE ; Number of sectors to write
  mov ch, 0              ; Cylinder 0
  mov cl, OS_FS_BLOCK_FIRST ; Start from sector defined in constants
  mov dh, 0              ; Head 0
  mov dl, 0x00           ; Drive 0 (first floppy drive)

  int 0x13               ; Call BIOS to write sectors
  jc .write_error        ; Error if carry flag set

  clc                    ; Clear carry flag (success)
  ret

  .write_error:
    stc                  ; Set carry flag (error)
    ret


; CPUID ========================================================================
; This function detects and prints the CPU family
; Expects: None
; Return: None
os_print_cpuid:

  pushfd                      ; Save EFLAGS
  pop eax                     ; Get EFLAGS into EAX
  mov ecx, eax                ; Save original EFLAGS in ECX
  xor eax, 0x200000           ; Toggle bit 21 (ID flag)
  push eax                    ; Push modified value
  popfd                       ; Try to load modified EFLAGS
  pushfd                      ; Get EFLAGS back
  pop eax                     ; into EAX
  push ecx                    ; Restore original EFLAGS
  popfd

  ; Compare bit 21 to see if it changed
  xor eax, ecx                ; If we couldn't change it, EAX will be 0
  test eax, 0x200000          ; Test bit 21
  jz .no_cpuid                ; CPUID not supported

  mov eax, 1                  ; eax = 1 for processor info
  cpuid

  ; Extract family ID (bits 8-11 of ax)
  mov bx, ax
  shr bx, 8                  ; Shift right by 8 bits
  and bx, 0Fh                ; Mask off all but family ID

  ; Print family ID
  cmp bx, 0x8
  jle .known_cpu
  .unknown_cpu:
    mov bx, 0x9
  .known_cpu:
  shl bx, 1                 ; Table is word sized
  mov si, [os_cpu_family_table + bx]
  call os_print_str
ret
  .no_cpuid:
    mov si, cpu_family_3
    call os_print_str
ret

; Splash screen ================================================================
; This function prints the system splash screen
; Expects: None
; Return: None
os_print_splash_screen:
  mov cx, 0x25
  mov dx, 0x0A27
  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_80
  je .skip_40
  mov dl, 0x13
  mov cx, 0x11
  .skip_40:

  ; Logo
  call os_cursor_pos_set
  mov al, GLYPH_MASCOT
  call os_print_chr

  inc dh
  sub dl, 0x3
  call os_cursor_pos_set
  mov si, system_logo_msg
  call os_print_str

  ; Version
  add dh, 0x4
  sub dl, 0x4
  call os_cursor_pos_set
  mov si, version_msg
  call os_print_str

  ; Press ENTER
  inc dh
  sub dl, 0x3
  call os_cursor_pos_set
  mov si, press_enter_msg
  call os_print_str

  ; Frame
  mov dx, 0x0900
  call os_cursor_pos_set
  mov al, GLYPH_FLOOR
  mov ah, cl
  call os_print_chr_mul

  mov al, GLYPH_RAMP_UP
  call os_print_chr
  mov al, GLYPH_CEILING
  mov ah, 0x03
  call os_print_chr_mul

  mov al, GLYPH_RAMP_DOWN
  call os_print_chr
  mov al, GLYPH_FLOOR
  mov ah, cl
  inc ah
  call os_print_chr_mul

  mov dx, 0x0C00
  call os_cursor_pos_set
  mov al, GLYPH_CEILING
  mov ah, cl
  sub ah, 0x3
  call os_print_chr_mul

  mov al, GLYPH_RAMP_DOWN
  call os_print_chr
  mov al, GLYPH_FLOOR
  mov ah, 0x03
  call os_print_chr_mul

  mov al, GLYPH_16BIT_1
  mov ah, GLYPH_16BIT_2
  call os_print_chr_double
  mov al, GLYPH_16BIT_3
  call os_print_chr

  mov al, GLYPH_FLOOR
  mov ah, 0x03
  call os_print_chr_mul

  mov al, GLYPH_RAMP_UP
  call os_print_chr
  mov al, GLYPH_CEILING
  mov ah, cl
  sub ah, 0x2
  call os_print_chr_mul

  ; Set position for printing OS tick
  mov dx, 0x1802
  call os_cursor_pos_set
ret

; Toolbar: Selects next icon ===================================================
; This function selects the next icon in the navigation
; Expects: None
; Returns: None
os_toolbar_icon_next:
  mov bx, OS_TOOLBAR_TABLE_ENTRY_SIZE
  call os_toolbar_icon_change_active
ret

; Toolbar: Selects previous icon ===============================================
; This function selects the previous icon in the navigation
; Expects: None
; Returns: None
os_toolbar_icon_prev:
  mov bx, -OS_TOOLBAR_TABLE_ENTRY_SIZE
  call os_toolbar_icon_change_active
ret

; Toolbar: Change active icon ==================================================
; This function tests if possible and change the active icon to new position
; Expects: BX = new position (+/-)
; Return: CF = out of bouds
os_toolbar_icon_change_active:
  mov si, [_OS_TOOLBAR_SELECTED_]
  add si, bx
  lodsb
  test al, al
  jz .bounded
  cmp al, [_OS_TOOLBAR_STATE_]
  jne .bounded
  add word [_OS_TOOLBAR_SELECTED_], bx
  call os_toolbar_print_hint
  clc
ret
  .bounded:
  stc
ret

; Clear line
; This function clears whole line with spaces
; Expects: DX position
; Returns: None
os_clear_line:
  push dx
  xor dl, dl
  call os_cursor_pos_set
  mov al, CHR_SPACE
  mov ah, 80
  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_80
  je .skip_40
    mov ah, 40
  .skip_40:
  call os_print_chr_mul
  pop dx
  call os_cursor_pos_set
ret

os_toolbar_print_hint:
  mov si, [_OS_TOOLBAR_SELECTED_]
  add si, OS_TOOLBAR_TABLE_ENTRY_SIZE-2
  call os_cursor_pos_get
  push dx
  mov dx, 0x0201
  call os_cursor_pos_set
  call os_clear_line
  mov al, GLYPH_MSG
  mov ah, CHR_SPACE
  call os_print_chr_double
  lodsw
  mov si, ax
  call os_print_str
  pop dx
  call os_cursor_pos_set
ret

; Executes icon command
; This function executes the command associated with the currently selected icon
; Expects: None
; Returns: None
os_icon_execute:
  mov si, [_OS_TOOLBAR_SELECTED_]
  inc si
  lodsb
  mov byte [_OS_TOOLBAR_STATE_], al

  push si
  mov si, os_toolbar_table
  .loop_table:
    lodsb
    cmp al, [_OS_TOOLBAR_STATE_]
    je .position_found
    add si, OS_TOOLBAR_TABLE_ENTRY_SIZE-1
    jmp .loop_table
    .position_found:
      dec si
      mov [_OS_TOOLBAR_SELECTED_], si
  pop si

  add si, 2
  lodsw
  call ax
ret

os_print_toolbar:
  call os_cursor_pos_get
  push dx

  mov dx, 0x000C
  call os_cursor_pos_set

  mov si, os_toolbar_table
  .icons_loop:
    lodsb
    test al, al
    jz .done
    cmp al, [_OS_TOOLBAR_STATE_]
    jne .next_icon

    mov ax, si
    dec ax
    cmp ax, [_OS_TOOLBAR_SELECTED_]
    jne .skip_selector
      call os_cursor_pos_get
      add dh, 0x01
      call os_cursor_pos_set
      mov ax, GLYPH_ICONS_SELECTOR
      call os_print_chr_double
      sub dh, 0x01
      call os_cursor_pos_set
    .skip_selector:

    inc si                        ; skip toolbar target state
    lodsw
    call os_print_chr_double
    mov al, CHR_SPACE
    call os_print_chr

    add si, 4                     ; skip command + desc
    jmp .icons_loop

    .next_icon:
      add si, 7                   ; skip target state, command, desc
      jmp .icons_loop
    .done:

  pop dx
  call os_cursor_pos_set
ret

os_toolbar_back:
  mov byte [_OS_TOOLBAR_STATE_], OS_TOOLBAR_STATE_MAIN
ret

os_init_shell:
  mov byte [_OS_STATE_], OS_STATE_SHELL
  call os_clear_screen
  call os_print_header
  call os_print_welcome_shell
  mov bl, GLYPH_PROMPT
  call os_print_prompt
ret

os_enter_shell:
  mov byte [_OS_STATE_], OS_STATE_SHELL
  call os_clear_screen
  call os_print_header
  mov bl, GLYPH_PROMPT
  call os_print_prompt
ret

os_enter_fs:
  mov byte [_OS_STATE_], OS_STATE_FS
  call os_clear_screen
  call os_print_header
  mov bl, GLYPH_PROMPT
  call os_print_prompt
ret

os_enter_help:
  mov byte [_OS_STATE_], OS_STATE_FS
  call os_clear_screen
  call os_print_header

  mov dl, OS_FS_FILE_ID_MANUAL
  call os_fs_file_read
  call os_fs_file_display
ret

os_mouse_init:
  ; Enable auxiliary mouse device
  call os_mouse_wait_input
  mov al, 0xA8
  out 0x64, al

  ; Enable packet streaming
  call os_mouse_send_cmd
  mov al, 0xF4
  out 0x60, al

  ; Read and discard ACK
  call os_mouse_wait_output
  in al, 0x60

  ; Initialize position to splashcreen logo mascot
  mov ax, 39
  mov bx, 10
  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_80
  jz .skip_40
    mov ax, 19
  .skip_40:
  mov word [_OS_MOUSE_+OS_MOUSE_X], ax
  shl word [_OS_MOUSE_+OS_MOUSE_X], OS_MOUSE_SLOWDOWN
  mov word [_OS_MOUSE_+OS_MOUSE_Y], bx
  shl word [_OS_MOUSE_+OS_MOUSE_Y], OS_MOUSE_SLOWDOWN
ret

; Wait for controller ready for command
os_mouse_wait_input:
  in al, 0x64
  test al, 2
  jnz os_mouse_wait_input
ret

; Wait for data available
os_mouse_wait_output:
  in al, 0x64
  test al, 1
  jz os_mouse_wait_output
ret

; Send command to mouse
os_mouse_send_cmd:
  call os_mouse_wait_input
  mov al, 0xD4
  out 0x64, al
  call os_mouse_wait_input
ret

os_mouse_poll:
  ; Check if mouse has data
  in al, 0x64
  test al, 0x20
  jz .no_data

  ; Read all 3 bytes when available
  call os_mouse_wait_output
  in al, 0x60       ; First byte (buttons and flags)
  mov ah, al        ; Save first byte

  call os_mouse_wait_output
  in al, 0x60       ; Second byte (X movement)
  movsx cx, al      ; Sign-extend X

  call os_mouse_wait_output
  in al, 0x60       ; Third byte (Y movement)
  movsx dx, al      ; Sign-extend Y

  mov al, ah
  and al, 0x07      ; Keep only button bits
  mov [_OS_MOUSE_+OS_MOUSE_BTN], al

  ; Update X position
  add [_OS_MOUSE_+OS_MOUSE_X], cx

  ; Update Y position (invert Y movement)
  neg dx
  add [_OS_MOUSE_+OS_MOUSE_Y], dx

  mov ax, 78
  mov bx, 23
  shl bx, OS_MOUSE_SLOWDOWN
  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_80
  je .skip_40
    mov ax, 38
  .skip_40:
  shl ax, OS_MOUSE_SLOWDOWN

  cmp word [_OS_MOUSE_+OS_MOUSE_X], 4
  jg .check_x_max
  mov word [_OS_MOUSE_+OS_MOUSE_X], 4
  .check_x_max:
    cmp word [_OS_MOUSE_+OS_MOUSE_X], ax
    jle .check_y_min
    mov word [_OS_MOUSE_+OS_MOUSE_X], ax
  .check_y_min:
    cmp word [_OS_MOUSE_+OS_MOUSE_Y], 8
    jg .check_y_max
    mov word [_OS_MOUSE_+OS_MOUSE_Y], 8
  .check_y_max:
    cmp word [_OS_MOUSE_+OS_MOUSE_Y], bx
    jle .no_data
    mov word [_OS_MOUSE_+OS_MOUSE_Y], bx

  clc
  ret
  .no_data:
    stc
    ret

; Void =========================================================================
; This is a placeholder function
; Expects: None
; Returns: None
os_void:
  nop
ret

; Data section =================================================================
version_msg           db 'Version alpha8', 0
system_logo_msg       db OS_GLYPH_ADDRESS+0x0
                      db OS_GLYPH_ADDRESS+0x1
                      db OS_GLYPH_ADDRESS+0x2
                      db OS_GLYPH_ADDRESS+0x3
                      db OS_GLYPH_ADDRESS+0x4
                      db OS_GLYPH_ADDRESS+0x5
                      db OS_GLYPH_ADDRESS+0x6
                      db 0x0
welcome_msg           db 'Welcome to SMOLiX Operating System', 0x0
copyright_msg         db '(C)2025 Krzysztof Krystian Jankowski', 0x0
press_enter_msg       db 'Press ENTER to begin.', 0x0
more_info_msg         db 'Type "h" for help.', 0x0
help_line1_msg        db 'LEFT/RIGHT/ENTER to navigate toolbar', 0x0
help_line3_msg        db 'Available commands:', 0x0
unknown_cmd_msg       db 'Unknown command', 0x0
unsupported_msg       db 'Unsupported', 0x0
supported_msg         db 'Supported', 0x0
hex_ruler_msg         db '0123456789ABCDEF', 0x0
cpu_family_msg        db 'CPU Family: ', 0x0
cpu_family_3          db 'Intel 386',0x0
cpu_family_4          db 'Intel 486',0x0
cpu_family_5          db 'Intel Pentium/MMX',0x0
cpu_family_6          db 'Intel Pentium Pro+',0x0
cpu_family_7          db 'Intel Itanium',0x0
cpu_family_8          db 'AMD Athlon 64',0x0
cpu_family_other      db 'Unknown CPU Vendor',0x0
memory_installed_msg  db 'Memory installed: ', 0x0
kernel_size_msg       db 'Kernel size: ', 0x0
kb_msg                db ' KB', 0x0
byte_msg              db ' B', 0x0
bios_date_msg         db 'BIOS date: ', 0x0
mouse_msg             db 'Mouse: ', 0x0
apm_batt_msg          db 'Battery: ', 0x0
apm_batt_ac           db 'AC power', 0x0
apm_batt_life         db '% charge', 0x0
success_msg           db 'success.', 0x0
failure_msg           db 'failure.', 0x0
fs_reading_msg        db 'Reading data from disk...', 0x0
fs_writing_msg        db 'Writing data to disk...', 0x0
fs_nav_msg            db 'Use UP/DOWN to scroll.', 0x0
fs_empty_msg          db 'No/empty file. Read data first.', 0x0
fs_ruler_80_msg:
db 0xAC,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAF
db 0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xB0
db 0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xB1
db 0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xB2
db 0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xB3
db 0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xB4
db 0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xB5
db 0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAE,0x0
fs_ruler_40_msg:
db 0xAC,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xB0
db 0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xB1
db 0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xB2
db 0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAD,0xAE,0x0
msg_cmd_back          db 'Back', 0x0
msg_cmd_h             db 'Quick help', 0x0
msg_cmd_manual        db 'Full system manual', 0x0
msg_cmd_v             db 'System version', 0x0
msg_cmd_r             db 'Soft reset', 0x0
msg_cmd_R             db 'Hard reboot', 0x0
msg_cmd_D             db 'Shutdown', 0x0
msg_cmd_c             db 'Clear the shell log', 0x0
msg_cmd_x             db 'Toggle between 40/80 screen modes', 0x0
msg_cmd_s             db 'System statistics', 0x0
msg_cmd_tilde         db 'Custom charset', 0x0
msg_cmd_void          db 0x0 ; Nothing
msg_cmd_fs_display    db GLYPH_FLOPPY, ' Display loaded file content', 0x0
msg_cmd_fs_read       db GLYPH_FLOPPY, ' Read file [0]', 0x0
msg_cmd_fs_write      db GLYPH_FLOPPY, ' Write current file', 0x0

os_fs_file_loaded     db 0xFF
os_fs_file_pos        dw 0x00

os_cpu_family_table:
  dw cpu_family_other
  dw cpu_family_other
  dw cpu_family_other
  dw cpu_family_3
  dw cpu_family_4
  dw cpu_family_5
  dw cpu_family_6
  dw cpu_family_7
  dw cpu_family_8
  dw cpu_family_other
  dw 0x0

os_fs_directory_table:
  dw 0x0011
  dw 0x010B
  dw 0x0

; current state, target state
; icon, function, description
os_toolbar_table:
  ; MAIN
  db OS_TOOLBAR_STATE_MAIN, OS_TOOLBAR_STATE_SHELL
  dw GLYPH_ICON_SHELL, os_enter_shell, msg_cmd_c

  db OS_TOOLBAR_STATE_MAIN, OS_TOOLBAR_STATE_FS
  dw GLYPH_ICON_FLOPPY, os_enter_fs, msg_cmd_c

  db OS_TOOLBAR_STATE_MAIN, OS_TOOLBAR_STATE_MAIN
  dw GLYPH_ICON_HELP, os_enter_help, msg_cmd_c

  ; SHELL
  db OS_TOOLBAR_STATE_SHELL, OS_TOOLBAR_STATE_MAIN
  dw GLYPH_ICON_BACK, os_void, msg_cmd_back

  db OS_TOOLBAR_STATE_SHELL, OS_TOOLBAR_STATE_SHELL
  dw GLYPH_ICON_SHELL, os_clear_shell, msg_cmd_c

  db OS_TOOLBAR_STATE_SHELL, OS_TOOLBAR_STATE_SHELL
  dw GLYPH_ICON_CONF, os_print_stats, msg_cmd_s

  db OS_TOOLBAR_STATE_SHELL, OS_TOOLBAR_STATE_SHELL
  dw GLYPH_ICON_X, os_toggle_video_mode, msg_cmd_x

  db OS_TOOLBAR_STATE_SHELL, OS_TOOLBAR_STATE_SHELL
  dw GLYPH_ICON_RESET, os_reset, msg_cmd_r

  db OS_TOOLBAR_STATE_SHELL, OS_TOOLBAR_STATE_SHELL
  dw GLYPH_ICON_REBOOT, os_reboot, msg_cmd_R

  db OS_TOOLBAR_STATE_SHELL, OS_TOOLBAR_STATE_SHELL
  dw GLYPH_ICON_DOWN, os_down, msg_cmd_D

  db OS_TOOLBAR_STATE_SHELL, OS_TOOLBAR_STATE_SHELL
  dw GLYPH_ICON_HELP, os_print_help, msg_cmd_h

  ; FILE SYSTEM
  db OS_TOOLBAR_STATE_FS, OS_TOOLBAR_STATE_MAIN
  dw GLYPH_ICON_BACK, os_void, msg_cmd_back

  db OS_TOOLBAR_STATE_FS, OS_TOOLBAR_STATE_FS
  dw GLYPH_ICON_FS_READ, os_void, msg_cmd_void

  db OS_TOOLBAR_STATE_FS, OS_TOOLBAR_STATE_FS
  dw GLYPH_ICON_FS_LIST, os_void, msg_cmd_void

  db OS_TOOLBAR_STATE_FS, OS_TOOLBAR_STATE_FS
  dw GLYPH_ICON_FS_WRITE, os_void, msg_cmd_void

  db 0x0 ; Terminator

; Commands table ===============================================================
; character (1b) | pointer to function (2b) | description (24b/chars)
os_commands_table:
  db 'h'
  dw os_print_help, msg_cmd_h

  db 'H'
  dw os_load_and_read_manual, msg_cmd_manual

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

  db 's'
  dw os_print_stats, msg_cmd_s

  db '`'
  dw os_print_debug, msg_cmd_tilde

  db 'F'
  dw os_fs_file0_read, msg_cmd_fs_read

  db 'f'
  dw os_fs_file_display, msg_cmd_fs_display

  db 'W'
  dw os_fs_file_write, msg_cmd_fs_write

  db 13
  dw os_icon_execute, msg_cmd_void

  db 27
  dw os_clear_shell, msg_cmd_void

  db 0x0 ; Terminator

os_keyboard_table:
  db OS_STATE_SPLASH_SCREEN, KBD_KEY_ENTER
  dw os_init_shell
  db OS_STATE_SHELL, KBD_KEY_ESCAPE
  dw os_clear_shell
  db OS_STATE_SHELL, KBD_KEY_RIGHT
  dw os_toolbar_icon_next
  db OS_STATE_SHELL, KBD_KEY_LEFT
  dw os_toolbar_icon_prev
  ;db OS_STATE_SHELL, KBD_KEY_ENTER
  ;dw os_icon_execute

  db OS_STATE_FS, KBD_KEY_RIGHT
  dw os_toolbar_icon_next
  db OS_STATE_FS, KBD_KEY_LEFT
  dw os_toolbar_icon_prev
  db OS_STATE_FS, KBD_KEY_ENTER
  dw os_icon_execute

  db OS_STATE_FS, KBD_KEY_UP
  dw os_fs_scroll_up
  db OS_STATE_FS, KBD_KEY_DOWN
  dw os_fs_scroll_down
  db OS_STATE_FS, KBD_KEY_ESCAPE
  dw os_enter_shell
  db 0x0

; Glyphs =======================================================================
; This section includes the glyph definitions
include 'glyphs.asm'

db "P1X"            ; Use HEX viewer to see `P1X` at the end of binary
os_kernel_end:
