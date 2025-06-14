; ==============================================================================
; SMOLiX: Real Mode, Raw Power.
; It is a simple kernel that runs in real mode as God intended.
;
; ==============================================================================
; Copyright (C) 2025 Krzysztof Krystian Jankowski
; This is free and open software. See LICENSE for details.
; ==============================================================================
;
; Should run on any x86 processor and system that supports legacy BIOS boot.
; Tested hardware:
; * CPU: 486 DX4, 100Mhz
; * Graphics: VGA
; * RAM: 24MB (OS recognize up to 640KB only)
;
; Theoretical minimum requirements:
; * CPU: 386 SX, 16Mhz
; * Graphics: EGA Enchanced (8x16)
; * RAM: 512KB
;
; ==============================================================================

org 0x0000

_OS_MEMORY_BASE_                equ 0x2000    ; Define memory base address
_OS_TICK_                       equ _OS_MEMORY_BASE_ + 0x00   ; 4b
_OS_VIDEO_MODE_                 equ _OS_MEMORY_BASE_ + 0x04   ; 1b
_OS_STATE_                      equ _OS_MEMORY_BASE_ + 0x05   ; 1b

_OS_DSKY_STATE_                 equ _OS_MEMORY_BASE_ + 0x06   ; 1b
_OS_DSKY_VERB_                  equ _OS_MEMORY_BASE_ + 0x07   ; 2b
_OS_DSKY_NOUN_                  equ _OS_MEMORY_BASE_ + 0x09   ; 2b
_OS_RNG_                        equ _OS_MEMORY_BASE_ + 0x0B   ; 2b
_OS_INACTIVE_TIMER_             equ _OS_MEMORY_BASE_ + 0x0D   ; 2b
_OS_VIRTUAL_SCREEN_             equ _OS_MEMORY_BASE_ + 0x0F   ; 1b

_OS_GAME_TICK_                  equ _OS_MEMORY_BASE_ + 0x10   ; 1b
_OS_GAME_STARTED_               equ _OS_MEMORY_BASE_ + 0x11   ; 1b
_OS_GAME_SCORE_                 equ _OS_MEMORY_BASE_ + 0x12   ; 1b
_OS_GAME_CURRENT_LEVEL_         equ _OS_MEMORY_BASE_ + 0x13   ; 2b
_OS_GAME_FLOPPY_                equ _OS_MEMORY_BASE_ + 0x15   ; 1b
_OS_GAME_ENTITIES_              equ _OS_MEMORY_BASE_ + 0x16   ; 6b per entity
_POS_X                          equ 0x0
_POS_Y                          equ 0x1
_DIR                            equ 0x2
_FRAME                          equ 0x3
_DIRT                           equ 0x4
_LAST_TILE                      equ 0x5
; space for 10 entities
_OS_FS_FLOPPY_DRIVE_            equ _OS_MEMORY_BASE_ + 0x040    ; 1b
_OS_FS_FILE_LOADED_             equ _OS_MEMORY_BASE_ + 0x041    ; 1b
_OS_FS_FILE_POS_                equ _OS_MEMORY_BASE_ + 0x042    ; 2b
_OS_FS_FILE_SIZE_               equ _OS_MEMORY_BASE_ + 0x044    ; 2b
_OS_FS_BUFFER_                  equ _OS_MEMORY_BASE_ + 0x046    ; 8kb
; space for 8kb file
_OS_COREWAR_PROG_PC_            equ _OS_MEMORY_BASE_ + 0x0200   ; 2b * 2 progs
_OS_COREWAR_ARENA_              equ _OS_MEMORY_BASE_ + 0x2010   ; 2kb
; space for 2kb arena

OS_STATE_INIT                   equ 0x01
OS_STATE_SPLASH_SCREEN          equ 0x02
OS_STATE_SHELL                  equ 0x03
OS_STATE_FS                     equ 0x04
OS_STATE_GAME                   equ 0x05
OS_STATE_COREWAR                equ 0x06

OS_VIRT_PAGE_SHELL              equ 0x00
OS_VIRT_PAGE_FS                 equ 0x01
OS_VIRT_PAGE_GAME               equ 0x02
OS_VIRT_PAGE_SCR_SAVER          equ 0x03
OS_VIRT_PAGE_COREWAR            equ 0x03

OS_DSKY_STATE_IDLE              equ 0x00
OS_DSKY_STATE_VERB_INPUT        equ 0x01
OS_DSKY_STATE_NOUN_INPUT        equ 0x02
OS_DSKY_STATE_EXECUTING         equ 0x03

OS_VIDEO_MODE_40                equ 0x00      ; 40x25
OS_VIDEO_MODE_80                equ 0x03      ; 80x25

OS_SCREEN_SAVER_TIME            equ 0x09FF

OS_FS_BLOCK_SIZE                equ 0x10
OS_FS_FILE_SIZE                 equ 0x2000
OS_FS_FILE_NOT_LOADED           equ 0xFF
OS_FS_FILE_LAST                 equ 0x3
OS_FS_FILE_LINES_ON_SCREEN      equ 0x15
OS_FS_FILE_CHARS_ON_LINE_80     equ 80-1
OS_FS_FILE_CHARS_ON_LINE_40     equ 40-1
OS_FS_FILE_SCROLL_CHARS         equ 160
OS_FS_FILE_ID_MANUAL            equ 0x00

OS_GAME_DELAY                   equ 0x02

GAME_COLOR_POT                  equ 0x1A
GAME_COLOR_DOOR                 equ 0x1D
GAME_COLOR_FLOPPY               equ 0x1E
GAME_COLOR_BROOM                equ 0x1C
GAME_COLOR_RAT                  equ 0x1F
GAME_COLOR_FLOOR                equ 0x12
GAME_HORIZONTAL_WALL            equ 0x0
GAME_VERTICAL_WALL              equ 0x1

OS_COLOR_WHITE_ON_BLUE          equ 0x1F
OS_COLOR_WHITE_ON_GREEN         equ 0x2F
OS_COLOR_WHITE_ON_RED           equ 0x4F
OS_COLOR_WHITE_ON_BLACK         equ 0x0F
OS_COLOR_GREEN_ON_BLACK         equ 0x02
OS_COLOR_DARK_GRAY_ON_BLACK     equ 0x08
OS_COLOR_BLACK_ON_BLUE          equ 0x10
OS_COLOR_BLUE_ON_BLUE           equ 0x11
OS_COLOR_GREEN_ON_BLUE          equ 0x12
OS_COLOR_CYAN_ON_BLUE           equ 0x13
OS_COLOR_RED_ON_BLUE            equ 0x14
OS_COLOR_MAGENTA_ON_BLUE        equ 0x15
OS_COLOR_BROWN_ON_BLUE          equ 0x16
OS_COLOR_LIGHT_GRAY_ON_BLUE     equ 0x17
OS_COLOR_DARK_GRAY_ON_BLUE      equ 0x18
OS_COLOR_LIGHT_BLUE_ON_BLUE     equ 0x19
OS_COLOR_LIGHT_GREEN_ON_BLUE    equ 0x1A
OS_COLOR_LIGHT_CYAN_ON_BLUE     equ 0x1B
OS_COLOR_LIGHT_RED_ON_BLUE      equ 0x1C
OS_COLOR_LIGHT_MAGENTA_ON_BLUE  equ 0x1D
OS_COLOR_YELLOW_ON_BLUE         equ 0x1E
OS_COLOR_WHITE_ON_BLUE          equ 0x1F


BYTE                            equ 0x01
WORD                            equ 0x02

OS_SOUND_STARTUP                equ 1500
OS_SOUND_SUCCESS                equ 1700
OS_SOUND_ERROR                  equ 2500

OS_GLYPH_ADDRESS                equ 0xB0
GLYPH_PROMPT                    equ 0xB0
GLYPH_MSG                       equ 0xB1
GLYPH_ERROR                     equ 0xB2
GLYPH_SYSTEM                    equ 0xB3
GLYPH_FLOPPY                    equ 0xB4
GLYPH_CAL                       equ 0xB5
GLYPH_MEM                       equ 0xB6
GLYPH_BAT                       equ 0xB7
; placeholder 0xB8
; placeholder 0xB9
GLYPH_MASCOT                    equ 0xBA
GLYPH_GAME_RAT_IDLE_L           equ 0xBA
GLYPH_GAME_RAT_WALK1_L          equ 0xBB
GLYPH_GAME_RAT_WALK2_L          equ 0xBC
GLYPH_GAME_RAT_IDLE_R           equ 0xBD
GLYPH_GAME_RAT_WALK1_R          equ 0xBE
GLYPH_GAME_RAT_WALK2_R          equ 0xBF
OS_GLYPH_LOGO                   equ 0xC0
; LOGO                              0xC0 - 0xC6
GLYPH_CEILING                   equ 0xC7
GLYPH_FLOOR                     equ 0xC8
GLYPH_RAMP_UP                   equ 0xC9
GLYPH_RAMP_DOWN                 equ 0xCA
GLYPH_16BIT_1                   equ 0xCB
GLYPH_16BIT_2                   equ 0xCC
GLYPH_16BIT_3                   equ 0xCD
GLYPH_RULER_START               equ 0xCE
GLYPH_RULER_MIDDLE              equ 0xCF
GLYPH_RULER_END                 equ 0xD0
GLYPH_RULER_NO                  equ 0xD1
; Ruler numbers 10-70               0xD1 - 0xD7
GLYPH_GAME_WALL_CORNER          equ 0xD8
GLYPH_GAME_WALL_HORIZONTAL      equ 0xD9
GLYPH_GAME_WALL_VERTICAL        equ 0xDA
GLYPH_GAME_TILE_A               equ 0xDB
GLYPH_GAME_TILE_B               equ 0xDC
GLYPH_GAME_TILE_C               equ 0xDD
; placeholders                      0xDE - 0xDF
GLYPH_GAME_DIRT1                equ 0xE0
GLYPH_GAME_DIRT2                equ 0xE1
GLYPH_GAME_DIRT3                equ 0xE2
GLYPH_GAME_BROOM1               equ 0xE3
GLYPH_GAME_BROOM2               equ 0xE4
GLYPH_GAME_POT                  equ 0xE5
GLYPH_GAME_POT_BROKEN           equ 0xE6
GLYPH_GAME_DOOR                 equ 0xE7

CHR_DOT                         equ '.'
CHR_SPACE                       equ ' '
CHR_CR                          equ 0x0D
CHR_LF                          equ 0x0A
CHR_NEW_LINE                    equ 0x0A0D
CHR_LIST                        equ 0x1A
CHR_SLASH                       equ '/'
CHR_ARROW_RIGHT                 equ 0x1A

DSKY_KEY_VERB                   equ 'v'
DSKY_KEY_NOUN                   equ 'n'
DSKY_KEY_ENTER                  equ 0x1C
DSKY_KEY_CLEAR                  equ 0x01

KBD_KEY_LEFT                    equ 0x4B
KBD_KEY_RIGHT                   equ 0x4D
KBD_KEY_UP                      equ 0x48
KBD_KEY_DOWN                    equ 0x50
KBD_KEY_ESCAPE                  equ 0x01
KBD_KEY_ENTER                   equ 0x1C
KBD_KEY_BACKSPACE               equ 0x0E
KBD_KEY_TAB                     equ 0x0F
KBD_KEY_PAGEUP                  equ 0x49
KBD_KEY_PAGEDOWN                equ 0x51
KBD_KEY_HOME                    equ 0x47
KBD_KEY_END                     equ 0x4F
KBD_KEY_INSERT                  equ 0x52

; ==============================================================================
;
; CORE SYSTEM LOOP
;
; ==============================================================================

; Initialize OS ================================================================
; This is the main entry
os_init:
  mov byte [_OS_FS_FLOPPY_DRIVE_], dl
  mov byte [_OS_STATE_], OS_STATE_INIT
  mov byte [_OS_DSKY_STATE_], OS_DSKY_STATE_IDLE
  mov word [_OS_DSKY_VERB_], 0x0
  mov word [_OS_DSKY_NOUN_], 0x0
  mov byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_40
  mov byte [_OS_FS_FILE_LOADED_], OS_FS_FILE_NOT_LOADED
  mov dword [_OS_TICK_], 00
  mov word [_OS_INACTIVE_TIMER_], OS_SCREEN_SAVER_TIME
  mov byte [_OS_VIRTUAL_SCREEN_], OS_VIRT_PAGE_SHELL
  mov byte [_OS_GAME_TICK_], OS_GAME_DELAY

; Entry point / System reset ===================================================
; resets the system.
; Expects: None
; Returns: None
os_reset:
  mov ah, 0x00		    ; Set video mode
	mov al, [_OS_VIDEO_MODE_]
	int 0x10            ; 80x25 text mode
  call os_load_all_glyphs

  call os_sound_init
  mov byte [_OS_STATE_], OS_STATE_SPLASH_SCREEN
  mov ax, OS_SOUND_STARTUP
  call os_sound_play
  call os_cursor_hide
  call os_clear_screen
  call os_display_splash_screen

; Main system loop =============================================================
; This is the main loop of the operating system.
; It waits for user input and interprets it.
; Expects: None
; Returns: None
os_main_loop:

  .check_keyboard:
    mov ah, 01h         ; BIOS keyboard status function
    int 16h             ; Call BIOS interrupt
    jz .continue

    mov word [_OS_INACTIVE_TIMER_], OS_SCREEN_SAVER_TIME

    mov ah, 00h         ; BIOS keyboard read function
    int 16h

    cmp byte [_OS_STATE_], OS_STATE_SHELL
    jne .no_command_key

  .check_dsky_command:
    test al, al
    jz .no_command_key

    call os_dsky_process_input

    jmp .continue

  .no_command_key:
    call os_interpret_kb

  .continue:
    cmp word [_OS_INACTIVE_TIMER_], 0x0
    je .screen_saver
    cmp byte [_OS_STATE_], OS_STATE_SHELL
    je .print_shell
    cmp byte [_OS_STATE_], OS_STATE_SPLASH_SCREEN
    je .print_splash
    cmp byte [_OS_STATE_], OS_STATE_GAME
    je .cpu_delay
    cmp byte [_OS_STATE_], OS_STATE_COREWAR
    je .cpu_delay

  .print_shell:
    mov al, OS_VIRT_PAGE_SHELL
    call os_virual_screen_set
  .print_header:
    call os_cursor_pos_get
    push dx
    call os_print_header
    call os_dsky_display
    pop dx
    call os_cursor_pos_set
    jmp .cpu_delay

  .screen_saver:
    mov word [_OS_INACTIVE_TIMER_], 0x01
    mov al, OS_VIRT_PAGE_SCR_SAVER
    call os_virual_screen_set
    call os_display_screen_saver
    jmp .cpu_delay

  .print_splash:
    mov al, OS_VIRT_PAGE_SHELL
    call os_virual_screen_set
    call os_display_splash_screen

  .cpu_delay:
    xor ax, ax            ; Function 00h: Read system timer counter
    int 0x1a              ; Returns tick count in CX:DX
    mov bx, dx            ; Store low word of tick count
    mov si, cx            ; Store high word of tick count
    .wait_loop:
      xor ax, ax
      int 0x1a
      cmp cx, si          ; Compare high word
      jne .tick_changed
      cmp dx, bx          ; Compare low word
      je .wait_loop       ; If both are the same, keep waiting
    .tick_changed:

  .update_system_tick:
    cmp dword [_OS_TICK_], 0xF0000000
    jb .skip_tick_reset
      mov dword [_OS_TICK_], 0
    .skip_tick_reset:
    inc dword [_OS_TICK_]

  call os_sound_stop

  cmp byte [_OS_STATE_], OS_STATE_GAME
  je .game_loop
  cmp byte [_OS_STATE_], OS_STATE_COREWAR
  je .corewar_loop

  dec word [_OS_INACTIVE_TIMER_]
  jmp .skip_custom_loops

  .game_loop:
  cmp byte [_OS_GAME_STARTED_], 0
  jz .skip_custom_loops
    dec byte [_OS_GAME_TICK_]
    jnz .skip_custom_loops
      mov byte [_OS_GAME_TICK_], OS_GAME_DELAY
      call os_game_loop

  jmp .skip_custom_loops

  .corewar_loop:
  cmp byte [_OS_GAME_STARTED_], 0
  jz .skip_custom_loops
    dec byte [_OS_GAME_TICK_]
    jnz .skip_custom_loops
      mov byte [_OS_GAME_TICK_], OS_GAME_DELAY
      call os_corewar_arena_display

  .skip_custom_loops:
jmp os_main_loop

; ==============================================================================
;
; DSKY FUNCTIONS
;
; ==============================================================================

os_dsky_display:
  mov dx, 0x000D
  call os_cursor_pos_set
  mov si, verb_msg
  call os_print_str

  mov bl, OS_COLOR_WHITE_ON_BLACK
  cmp byte [_OS_DSKY_STATE_], OS_DSKY_STATE_VERB_INPUT
  jne .skip_verb_color
    mov bl, OS_COLOR_WHITE_ON_RED
  .skip_verb_color:

  mov al, [_OS_DSKY_VERB_]
  call os_print_bcd_color

  mov dx, 0x0018
  call os_cursor_pos_set
  mov si, noun_msg
  call os_print_str

  mov bl, OS_COLOR_WHITE_ON_BLACK
  cmp byte [_OS_DSKY_STATE_], OS_DSKY_STATE_NOUN_INPUT
  jne .skip_noun_color
    mov bl, OS_COLOR_WHITE_ON_RED
  .skip_noun_color:

  mov al, [_OS_DSKY_NOUN_]
  call os_print_bcd_color
ret

os_dsky_process_input:
  cmp al, DSKY_KEY_VERB
  je .process_verb
  cmp al, DSKY_KEY_NOUN
  je .process_noun
  cmp ah, DSKY_KEY_ENTER
  je .process_enter
  cmp ah, DSKY_KEY_CLEAR
  je .process_clear

  call os_convert_keypad_numbers

  .check_if_digit:
    sub al, '0'
    cmp al, 0
    jl .done
    cmp al, 9
    jg .done
    jmp .process_digit

  .process_digit:
    cmp byte [_OS_DSKY_STATE_], OS_DSKY_STATE_VERB_INPUT
    je .process_verb_digit
    cmp byte [_OS_DSKY_STATE_], OS_DSKY_STATE_NOUN_INPUT
    je .process_noun_digit
    jmp .done
    .process_verb_digit:
      mov bl, al                      ; Save new digit
      mov al, byte [_OS_DSKY_VERB_]   ; Save original value
      and al, 0x0F                    ; Mask the lower nibble
      shl al, 4                       ; Shift nibble to upper nibble
      add al, bl                      ; Add the new digit in lower nibble
      mov byte [_OS_DSKY_VERB_], al   ; Save
      jmp .done
    .process_noun_digit:
      mov bl, al                      ; Save new digit
      mov al, byte [_OS_DSKY_NOUN_]   ; Save original value
      and al, 0x0F                    ; Mask the lower nibble
      shl al, 4                       ; Shift nibble to upper nibble
      add al, bl                      ; Add the new digit
      mov byte [_OS_DSKY_NOUN_], al   ; Save
      jmp .done

  .process_verb:
    mov byte [_OS_DSKY_VERB_], 0x0
    mov byte [_OS_DSKY_STATE_], OS_DSKY_STATE_VERB_INPUT
  jmp .done

  .process_noun:
    mov byte [_OS_DSKY_NOUN_], 0x0
    mov byte [_OS_DSKY_STATE_], OS_DSKY_STATE_NOUN_INPUT
  jmp .done

  .process_enter:
    mov byte [_OS_DSKY_STATE_], OS_DSKY_STATE_EXECUTING
    call os_dsky_execute_command
    mov byte [_OS_DSKY_STATE_], OS_DSKY_STATE_IDLE
  jmp .done

  .process_clear:
    mov byte [_OS_DSKY_VERB_], 0x0
    mov byte [_OS_DSKY_NOUN_], 0x0
    mov byte [_OS_DSKY_STATE_], OS_DSKY_STATE_IDLE
  jmp .done

  .done:
ret

os_dsky_print_executing:
  mov bl, GLYPH_SYSTEM
  call os_print_prompt

  mov si, executed_msg
  call os_print_str

  mov si, verb_msg
  call os_print_str

  mov al, [_OS_DSKY_VERB_]
  call os_print_bcd

  mov al, CHR_SPACE
  mov ah, al
  call os_print_chr_double

  mov si, noun_msg
  call os_print_str

  mov ax, [_OS_DSKY_NOUN_]
  call os_print_bcd

  mov al, CHR_SPACE
  mov ah, al
  call os_print_chr_double

  mov al, GLYPH_SYSTEM
  mov ah, CHR_ARROW_RIGHT
  call os_print_chr_double

  mov eax, [_OS_TICK_]
  call os_print_num
ret

; Execute DSKY command
os_dsky_execute_command:
  call os_dsky_print_executing

  mov si, os_dsky_commands_table
  mov bl, byte [_OS_DSKY_VERB_]
  mov bh, byte [_OS_DSKY_NOUN_]
  .command_loop:
    lodsb
    cmp al, 0xFF          ; Check for terminator
    je .unknown_command   ; If we at the end then command was not found

    cmp al, bl
    je .verb_match
    ; skip noun, cmd, msg
    add si, BYTE + WORD + WORD
    jmp .next_command
    .verb_match:
      lodsb
      cmp al, bh
      je .noun_match
      cmp al, 0xFF
      je .pass_noun_as_param

      add si, WORD + WORD ; cmd, msg
      jmp .next_command
    .pass_noun_as_param:
      mov dl, bh
    .noun_match:
      lodsw
      jmp .command_found
    .next_command:
  jmp .command_loop

  .unknown_command:
    mov bl, GLYPH_ERROR
    call os_print_prompt
    mov si, unknown_cmd_msg
    call os_print_str
    jmp .done

  .command_found:
    mov bl, GLYPH_MSG
    call os_print_prompt
    mov si, [si]
    call os_print_str
    call ax
    jc .error
  .done:
    mov ax, OS_SOUND_ERROR
    call os_sound_play
    clc
ret
.error:
  mov ax, OS_SOUND_ERROR
  call os_sound_play
  stc
ret

os_dsky_commands_table:
  ; Help
  db 0x00, 0x00
  dw os_display_quick_help, msg_cmd_help
  db 0x00, 0x01
  dw os_enter_manual, msg_cmd_manual

  ; System informations
  db 0x01, 0x00
  dw os_print_tick, msg_cmd_tick
  db 0x01, 0x01
  dw os_display_kernel_version, msg_cmd_version
  db 0x01, 0x02
  dw os_display_system_stats, msg_cmd_stats
  db 0x01, 0x03
  dw os_glyphs_print_all, msg_cmd_glyphs

  ; Core
  db 0x10, 0x00
  dw os_reset, msg_cmd_reset
  db 0x10, 0x01
  dw os_reboot, msg_cmd_reboot
  db 0x10, 0x02
  dw os_down, msg_cmd_down
  db 0x11, 0x00
  dw os_toggle_video_mode, msg_cmd_display

  ; Shell
  db 0x20, 0x00
  dw os_enter_shell, msg_cmd_clear_shell

  ; File System
  db 0x30, 0x00
  dw os_fs_list_files, msg_cmd_fs_list
  db 0x31, 0xFF
  dw os_fs_select_file, msg_cmd_fs_read
  db 0x32, 0x00
  dw os_fs_display_buffer, msg_cmd_fs_display
  db 0x32, 0x01
  dw os_void, msg_cmd_fs_edit
  db 0x32, 0x02
  dw os_fs_file_write, msg_cmd_fs_write
  db 0x32, 0x03
  dw os_fs_clear_buffer, msg_cmd_fs_clear_buf

  ; Printing
  db 0x40, 0x00
  dw os_printer_print_fs_buffer, msg_cmd_print

  ; Game
  db 0x50, 0x00
  dw os_enter_game, msg_cmd_game

  ; CoreWar
  db 0x60, 0x00
  dw os_corewar_prog_list, msg_cmd_cw_list
  db 0x60, 0x10
  dw os_corewar_enter_arena, msg_cmd_cw_enter_arena



; Verb 60 : Noun 00 - show CoreWar instructions, list, overall "main screen"
; Verb 60 : Noun 01 - list warriors
; Verb 60 : Noun 02 - list code of selected warrior (last one is "new")
; Verb 60 : Noun 03 - insert selected warrior into arena
; Verb 60 : Noun 10 - start battle simulation (arena screen, ESC to back)
; Verb 60 : Noun 11 - end battle arena
; Verb 60 : Noun 12 - back to arena screen
; Verb 61 : Noun XX - select warrior
; Verb 62 : Noun XX - change line to edit of selected warrior
; Verb 63 : Noun XX - change opcode XX
; Verb 64 : Noun XY - change addressing mode (#,$,@); X for A, Y for B
; Verb 65 : Noun XX - value A
; Verb 66 : Noun XX - value B (if needed)
; Verb 67 : Noun 00 - proceed to next line
; Verb 67 : Noun 01 - go to previous line
; Verb 67 : Noun 02 - go to beginning
; Verb 67 : Noun 03 - go to last line

  ; Terminator
  db 0xFF

; ==============================================================================
;
; SYSTEM FUNCTIONS
;
; ==============================================================================

; Print System Tick ============================================================
; prints system tick to the screen.
; Expects: None
; Returns: None
os_print_tick:
  mov bl, GLYPH_SYSTEM
  call os_print_prompt
  mov eax, [_OS_TICK_]
  call os_print_num
ret

; Gets Cursor Position =========================================================
; gets the current cursor position on the screen.
; Expects: None
; Returns: DX = column, DX = row
os_cursor_pos_get:
  mov ax, 0x0300    ; Get cursor position and size
  mov bh, [_OS_VIRTUAL_SCREEN_]
  int 0x10          ; Call BIOS
ret

; Sets Cursor Position =========================================================
; sets the cursor position on the screen.
; Expects: DX = column (0-79), DX = row (0-24)
; Returns: None
os_cursor_pos_set:
  mov ax, 0x0200    ; Set cursor position
  mov bh, [_OS_VIRTUAL_SCREEN_]
  int 0x10          ; Call BIOS
ret

; Print Header =================================================================
; prints the header information to the screen.
; Expects: None
; Returns: None
os_print_header:
  mov dx, 0x014F    ; 2 rows, 80 columns
  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_80
  je .set_color
    mov dl, 0x27      ; 40 columns
  .set_color:
  mov ax, 0x0600    ; Function 06h (scroll window up)
  mov bh, OS_COLOR_WHITE_ON_GREEN
  mov cx, 0x0000    ; Top left corner (row 0, col 0)
  int 0x10

  call os_cursor_pos_reset

  mov dl, 58
  mov dh, 69
  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_80
  je .skip_40
    mov dl, 31
    mov dh, 29
  .skip_40:

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
ret

; Print Error Status ===========================================================
; prints the status of the last operation.
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

; Print prompt =================================================================
; prints the prompt for the user.
; Expects: BL = type of glyph
; Returns: None
os_print_prompt:
  push ax
  mov ax, CHR_NEW_LINE
  call os_print_chr_double
  mov al, CHR_SPACE
  call os_print_chr
  mov al, bl                ; The glyph

  mov bl, OS_COLOR_LIGHT_BLUE_ON_BLUE
  cmp al, GLYPH_ERROR
  jne .skip_color_err
    mov bl, OS_COLOR_RED_ON_BLUE
  .skip_color_err:
  cmp al, GLYPH_SYSTEM
  jne .skip_color_sys
    mov bl, OS_COLOR_YELLOW_ON_BLUE
  .skip_color_sys:

  call os_print_chr_color
  mov al, CHR_SPACE
  call os_print_chr
  pop ax
ret

; System shutdown ==============================================================
; shuts down or restarts the system.
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

; Reboot System ================================================================
; reboots the system.
; Expects: None
; Returns: None
os_reboot:
  jmp 0FFFFh:0000h


; Hide cursor ==================================================================
; hides the cursor.
; Expects: None
; Returns: None
os_cursor_hide:
  mov ah, 0x01       ; Set cursor type function
  mov cx, 0x2000     ; Bit 15 set (0x2000) disables the cursor
  int 0x10           ; Call BIOS
ret

; Show cursor ==================================================================
; shows the cursor.
; Expects: None
; Returns: None
os_cursor_show:
  mov ah, 0x01       ; Set cursor type function
  mov cx, 0x0607     ; Normal cursor (start scan line 6, end scan line 7)
  int 0x10           ; Call BIOS
ret

; Get random ===================================================================
; generates a random number
; Expects: None
; Returns: AX - Random number
os_get_random:
    mov ax, [_OS_RNG_]
    inc ax
    rol ax, 1
    xor ax, 0x1337
    add ax, [_OS_TICK_]
    mov [_OS_RNG_], ax
ret

; Print character ==============================================================
; prints a character to the screen.
; Expects: AL = character to print
; Returns: None
os_print_chr:
  push ax
  mov ah, 0x0e    ; BIOS teletype output function
  mov bh, [_OS_VIRTUAL_SCREEN_]
  int 0x10        ; BIOS teletype output function
  pop ax
ret

; Print character with color ===================================================
; prints a character to the screen with a specified color.
; Expects: AL = character to print, BL = color
; Returns: None
os_print_chr_color:
  pusha
  mov ah, 0x09    ; BIOS function to print character with color
  mov bh, [_OS_VIRTUAL_SCREEN_]
  mov cx, 0x01    ; Number of characters to print
  int 0x10        ; BIOS teletype output function
  ; Move cursor forward after printing
  call os_cursor_pos_get
  inc dl                  ; Move cursor one position right
  call os_cursor_pos_set
  popa
ret

; Print Two Characters =========================================================
; prints two characters to the screen.
; Expects: AL = first character, AH = second character
; Returns: None
os_print_chr_double:
  call os_print_chr
  mov al, ah
  call os_print_chr
ret

; Print Character Multiple Times ===============================================
; prints a character multiple times to the screen.
; Expects: AL = character
;          AH = number of times to print
; Returns: None
os_print_chr_mul:
  push cx
  movzx cx, ah
  .char_loop:
    call os_print_chr
  loop .char_loop
  pop cx
ret

; Print string =================================================================
; prints a string to the screen.
; Expects: SI = pointer to string
; Returns: None
os_print_str:
  pusha
  mov bh, [_OS_VIRTUAL_SCREEN_]
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

; Read Character ==============================================================
; reads a character from the screen.
; Expects: DX = coordinates of cursor position
; Returns: AL = character read from keyboard
os_read_chr:
  mov ah, 02h         ; First set cursor position
  mov bh, [_OS_VIRTUAL_SCREEN_]
  int 10h            ; Move cursor
  mov ah, 08h        ; Then read character
  int 10h            ; Call BIOS interrupt
ret

; Print Number =================================================================
; prints a number in decimal format
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
; toggles between 40 and 80 column video modes
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


; Clear screen =================================================================
; clears the screen with primary colors.
; Expects: None
; Returns: None
os_clear_screen:
  mov al, CHR_SPACE
  mov bl, OS_COLOR_WHITE_ON_BLUE
  call os_fill_screen_with_glyph
ret

; Cursor position reset ========================================================
; resets the cursor position to the top left of the screen.
; Expects: None
; Returns: None
os_cursor_pos_reset:
  mov bh, [_OS_VIRTUAL_SCREEN_]
  mov ah, 0x2       ; Set cursor
  mov dx, 0x0000    ; DH = row 0, DL = column 0 (top-left)
  int 0x10
ret

; Print a BCD value ============================================================
; prints a BCD value to the console.
; Expects: AX = BCD value
; Returns: None
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

; Print BCD with Color =========================================================
; prints a BCD value with a specific color
; Expects: AL = BCD value to print, BL = color attribute
; Returns: None
os_print_bcd_color:
  push ax                ; Save the original BCD value
  shr al, 4              ; Get high nibble
  add al, '0'            ; Convert to ASCII
  call os_print_chr_color ; Print it with color
  pop ax                 ; Restore the original BCD value
  and al, 0x0F           ; Get low nibble
  add al, '0'            ; Convert to ASCII
  call os_print_chr_color ; Print it with color
ret

; ==============================================================================
;
; KEYBOARD FUNCTIONS
;
; ==============================================================================


; Mathematical conversion for keypad scan codes
; Input: AH = scan code
; Output: AL = ASCII digit ('0'-'9') or 0 if not keypad
os_convert_keypad_numbers:
  cmp ah, 0x47      ; Keypad 7
  je .keypad_7
  cmp ah, 0x48      ; Keypad 8
  je .keypad_8
  cmp ah, 0x49      ; Keypad 9
  je .keypad_9
  cmp ah, 0x4B      ; Keypad 4
  je .keypad_4
  cmp ah, 0x4C      ; Keypad 5
  je .keypad_5
  cmp ah, 0x4D      ; Keypad 6
  je .keypad_6
  cmp ah, 0x4F      ; Keypad 1
  je .keypad_1
  cmp ah, 0x50      ; Keypad 2
  je .keypad_2
  cmp ah, 0x51      ; Keypad 3
  je .keypad_3
  cmp ah, 0x52      ; Keypad 0
  je .keypad_0
ret

.keypad_0: mov al, '0'
ret
.keypad_1: mov al, '1'
ret
.keypad_2: mov al, '2'
ret
.keypad_3: mov al, '3'
ret
.keypad_4: mov al, '4'
ret
.keypad_5: mov al, '5'
ret
.keypad_6: mov al, '6'
ret
.keypad_7: mov al, '7'
ret
.keypad_8: mov al, '8'
ret
.keypad_9: mov al, '9'
ret

; Interpret keyboard input =====================================================
; interprets the keyboard input and performs associated action.
; Expects: AH = character to interpret (control)
; Returns: None
os_interpret_kb:
  mov si, os_keyboard_table
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
    add si, BYTE
    .next_entry:
    add si, WORD
  jmp .loop_kbd

  .found:
    lodsw           ; Load next command address
    call ax         ; call the command address
    mov ax, OS_SOUND_SUCCESS
    call os_sound_play
    clc
ret

  .unknown:
    mov ax, OS_SOUND_ERROR
    call os_sound_play
    stc
ret

os_keyboard_table:
  db OS_STATE_SPLASH_SCREEN, KBD_KEY_ENTER
  dw os_enter_shell
  db OS_STATE_SHELL, KBD_KEY_ESCAPE
  dw os_clear_shell

  db OS_STATE_FS, KBD_KEY_PAGEUP
  dw os_fs_scroll_up
  db OS_STATE_FS, KBD_KEY_PAGEDOWN
  dw os_fs_scroll_down
  db OS_STATE_FS, KBD_KEY_ESCAPE
  dw os_enter_shell

  db OS_STATE_GAME, KBD_KEY_UP
  dw os_game_player_move
  db OS_STATE_GAME, KBD_KEY_DOWN
  dw os_game_player_move
  db OS_STATE_GAME, KBD_KEY_LEFT
  dw os_game_player_move
  db OS_STATE_GAME, KBD_KEY_RIGHT
  dw os_game_player_move
  db OS_STATE_GAME, KBD_KEY_ENTER
  dw os_game_start
  db OS_STATE_GAME, KBD_KEY_ESCAPE
  dw os_enter_shell

  db OS_STATE_COREWAR, KBD_KEY_ENTER
  dw os_corewar_arena_simulate
  db OS_STATE_COREWAR, KBD_KEY_ESCAPE
  dw os_enter_shell

  db 0x0

; ==============================================================================
;
; GLYPHS FUNCTIONS
;
; ==============================================================================

; Glyphs =======================================================================
; This section includes the glyphs definitions
include 'glyphs.asm'

; Load glyph ===================================================================
; loads a custom glyph into the VGA font memory using BIOS.
; Expects: AL = character code to replace
; Returns: None
os_load_glyph:
  pusha
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
; loads all custom glyphs into the VGA font memory using BIOS.
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

; Print all glyphs =============================================================
; prints loaded glyphs.
; Expects: None
; Returns: None
os_glyphs_print_all:
mov dx, 0
mov cx, 0x02
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

; Fill rectangle with glyph ====================================================
; fills a rectangular area of the screen with a specified glyph character.
; Expects:
;   AL - glyph character to fill with
;   BL - color attribute
os_fill_screen_with_glyph:
  call os_cursor_pos_reset
  mov bh, [_OS_VIRTUAL_SCREEN_]
  mov ah, 0x09         ; BIOS function to write character and attribute
  mov cx, 2000         ; 80x25 = 2000 characters on screen
  cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_80
  je .skip_40
  shr cx, 1
  .skip_40:
  int 0x10             ; Call BIOS
  call os_cursor_pos_reset
ret

; ==============================================================================
;
; SOUND SYSTEM FUNCTIONS
;
; ==============================================================================

; Sound Initialization =========================================================
; initializes the sound system.
; Expects: None
; Returns: None
os_sound_init:
   mov al, 182         ; Binary mode, square wave, 16-bit divisor
   out 43h, al         ; Write to PIT command register[2]
ret

; Sound Play ===================================================================
; sets the sound to play a tone
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
; stops the sound playback
; Expects: None
; Returns: None
os_sound_stop:
  in al, 61h
  test al, 00000011b    ; Check if bits 0 and 1 are set
  jz .already_stopped   ; If both bits clear, sound is already off
  and al, 11111100b     ; Clear bits 0-1
  out 61h, al           ; Disable speaker output
  .already_stopped:
ret

; ==============================================================================
;
; SHELL FUNCTIONS
;
; ==============================================================================

; Enter/restart shell ==========================================================
; initializes the shell state and prints welcome message
; Expects: None
; Returns: None
os_enter_shell:
  mov byte [_OS_STATE_], OS_STATE_SHELL
  mov al, OS_VIRT_PAGE_SHELL
  call os_virual_screen_set
  call os_clear_screen
  call os_print_header
  call os_display_welcome_shell
ret

; Clear Shell ==================================================================
; clears the shell and resets the display.
; Expects: None
; Returns: None
os_clear_shell:
  pusha
  call os_clear_screen
  call os_print_header
  popa
ret

; ==============================================================================
;
; FILE SYSTEM
;
; ==============================================================================

;  Cylinder, Head, Sector, Filename
os_fs_directory_table:
  db 0x00, 0x00, 0x12, 'Full System Manual          ', 0x0
  db 0x00, 0x01, 0x10, 'ASCII Art gallery           ', 0x0
  db 0x01, 0x00, 0x0E, 'Notepad                     ', 0x0
  db 0x01, 0x01, 0x0C, 'Kernel change log           ', 0x0
  db 0xFF

; File System: list files ======================================================
; lists the files on the floppy disk.
; Expects: None
; Returns: None
os_fs_list_files:
  mov bl, GLYPH_FLOPPY
  call os_print_prompt
  mov si, fs_files_list_msg
  call os_print_str

  xor cx, cx
  xor bx, bx
  .list_loop:
    mov bx, cx
    shl bx, 5
    cmp byte [os_fs_directory_table+bx], 0xFF
    je .done
    add bx, 3
    mov si, os_fs_directory_table
    add si, bx
    mov bl, GLYPH_FLOPPY
    cmp byte cl, [_OS_FS_FILE_LOADED_]
    jne .not_selected
    mov bl, GLYPH_MEM
    .not_selected:
    call os_print_prompt
    mov ax, cx
    call os_print_num
    mov al, CHR_SPACE
    call os_print_chr

    call os_print_str

    inc cx
  jmp .list_loop

  .done:
  mov bl, GLYPH_FLOPPY
  call os_print_prompt
  mov si, fs_select_file_msg
  call os_print_str
ret

; File System: select file =====================================================
; selects a file from the floppy disk to load
; Expects: DL = file id
; Returns: CF = 0 on success, CF = 1 on failure
os_fs_select_file:
  call os_fs_load_buffer
ret

os_fs_clear_buffer:
  mov di, _OS_FS_BUFFER_
  xor ax, ax
  mov cx, OS_FS_FILE_SIZE/2
  rep stosw               ; Clear buffer

  clc
ret

; File System: load buffer =====================================================
; loads a file from the floppy disk to a memory
; Expects: DL = file id
; Returns: CF = 0 on success, CF = 1 on failure
os_fs_load_buffer:
  cmp byte [_OS_FS_FILE_LOADED_], dl
  je .already_loaded

  call os_fs_clear_buffer

  .load_new_buffer:
    mov byte [_OS_FS_FILE_LOADED_], dl
    mov word [_OS_FS_FILE_POS_], 0x0

  .draw_prompt:
    mov bl, GLYPH_FLOPPY
    call os_print_prompt
    mov si, fs_reading_msg    ; Reading...
    call os_print_str

  .reset_disk:
    xor dl, dl
    xor ax, ax
    int 0x13               ; Reset disk system
    jc .disk_error

  .preapare_file_position:
    movzx bx, [_OS_FS_FILE_LOADED_]
    shl bx, 5
    mov ch, [os_fs_directory_table + bx]      ; Cylinder
    mov dh, [os_fs_directory_table + bx + 1]  ; Head
    mov cl, [os_fs_directory_table + bx + 2]  ; Sector

  .prepare_es:
    mov ax, ds
    mov es, ax              ; Make sure ES=DS for disk read
    mov bx, _OS_FS_BUFFER_

  .read_data_from_floppy:
    mov ah, 0x02            ; Read sectors function
    mov al, OS_FS_BLOCK_SIZE
    mov dl, [_OS_FS_FLOPPY_DRIVE_]
    int 0x13                ; BIOS disk interrupt
    jc .disk_error          ; Error if carry flag set

  .already_loaded:
    mov si, success_msg
    call os_print_str
  clc                     ; Clear carry flag (success)
ret
  .disk_error:
    mov byte [_OS_FS_FILE_LOADED_], OS_FS_FILE_NOT_LOADED
    mov si, failure_msg
    call os_print_str
    stc                   ; Set carry flag (error)
ret

; File System: display buffer ==================================================
; displays the loaded file contents from memory to the screen
; Expects: None
; Returns: None
os_fs_display_buffer:
  mov si, _OS_FS_BUFFER_
  add si, [_OS_FS_FILE_POS_]  ; Add current scroll position

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
    mov ax, [_OS_FS_FILE_POS_]
    mov cx, 0x03
    call os_print_num
    mov si, byte_msg
    call os_print_str
    mov al, CHR_SPACE
    call os_print_chr
    mov si, fs_read_footer_msg
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
  cmp byte [_OS_STATE_], OS_STATE_FS
  jne .done

  cmp word [_OS_FS_FILE_POS_], OS_FS_FILE_SCROLL_CHARS
  jl .done
  sub word [_OS_FS_FILE_POS_], OS_FS_FILE_SCROLL_CHARS
  call os_fs_display_buffer
  .done:
ret

; File System: scroll Down =====================================================
os_fs_scroll_down:
  cmp byte [_OS_STATE_], OS_STATE_FS
  jne .done

  cmp word [_OS_FS_FILE_POS_], OS_FS_FILE_SIZE-OS_FS_FILE_SCROLL_CHARS
  jg .done

  mov si, _OS_FS_BUFFER_
  add si, [_OS_FS_FILE_POS_]
  add si, OS_FS_FILE_SCROLL_CHARS
  cmp byte [si], 0          ; Check if the current character is null
  je .done

  add word [_OS_FS_FILE_POS_], OS_FS_FILE_SCROLL_CHARS
  call os_fs_display_buffer
  .done:
ret

; File System: file write ======================================================
; writes data to a file on the disk
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
  mov cl, 0 ; Start from sector defined in constants
  mov dh, 0              ; Head 0
  mov dl, [_OS_FS_FLOPPY_DRIVE_]

  int 0x13               ; Call BIOS to write sectors
  jc .write_error        ; Error if carry flag set

  clc                    ; Clear carry flag (success)
  ret

  .write_error:
    stc                  ; Set carry flag (error)
    ret

; ==============================================================================
;
; SYSTEM INFORMATION FUNCTIONS
;
; ==============================================================================

; System version ===============================================================
; returns the version of the kernel.
; Expects: None
; Returns: None
os_display_kernel_version:
  mov bl, GLYPH_SYSTEM
  call os_print_prompt
  mov si, version_msg
  call os_print_str
ret

; Expects: None
; Returns: None
os_display_screen_saver:
  mov cx, 0x20
  .char_loop:
  push cx
    call os_get_random

    .bound_y:
      and al, 0x1F      ; 0-31 values
      cmp al, 25        ; row bound
      jl .no_bound_y
      jmp .skip_drawing_char
      .no_bound_y:

    .set_column_bound:
      and ah, 0x7F      ; 0-127 values
      mov bl, 80
      cmp byte [_OS_VIDEO_MODE_], OS_VIDEO_MODE_80
      je .skip_40
      mov bl, 40
      .skip_40:

    .bound_x:
      cmp ah, bl
      jl .no_bound_x
      jmp .skip_drawing_char
      .no_bound_x:

    .set_cursor:
      mov dh, al        ; DL = column (AH), DH = row (AL)
      mov dl, ah
      call os_cursor_pos_set

    .draw_random_char:
      call os_get_random
      mov bl, al
      and al, 0x07
      add al, OS_GLYPH_ADDRESS

      mov bl, byte [_OS_TICK_+1]
      and bl, 0x7
      add bl, OS_COLOR_GREEN_ON_BLACK
      call os_print_chr_color

    .skip_drawing_char:
    pop cx
  loop .char_loop
ret

; Virtual screen ===============================================================
; Set the virtual screen mode.
; Parameters: None
; Returns: None
os_virual_screen_set:
  push ax
  mov byte [_OS_VIRTUAL_SCREEN_], al
  mov ah, 0x05
  int 0x10
  pop ax
ret

; Print help message ===========================================================
; Prints the help message to the screen.
; Expects: None
; Returns: None
os_display_quick_help:
  mov bl, GLYPH_SYSTEM
  call os_print_prompt
  mov si, available_cmds_msg
  call os_print_str

  ; Listing of all commands
  mov si, os_dsky_commands_table
  .cmd_loop:
    lodsb         ; Current character in AL
    cmp al, 0xFF   ; Test if 0, terminator
    jz .done

    mov bl, CHR_LIST
    call os_print_prompt          ; Prompt

    call os_print_bcd

    mov al, ':'
    call os_print_chr

    lodsb
    call os_print_bcd

    mov al, CHR_SPACE
    call os_print_chr

    add si, WORD  ; Skip address, point to description pointer
    push si                       ; Saves os_commands_table
    mov si, [si]                  ; Gets the description message address
    call os_print_str             ; Print description string
    pop si                        ; Restore os_commands_table

    add si, WORD      ; Move to next command
    jmp .cmd_loop
.done:
ret

; Print welcome message ========================================================
; Prints the welcome message to the screen.
; Expects: None
; Returns: None
os_display_welcome_shell:
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

; Print statistics =============================================================
; Prints system statistics.
; Expects: None
; Returns: None
os_display_system_stats:
  mov bl, GLYPH_SYSTEM
  call os_print_prompt
  mov si, cpu_family_msg
  call os_print_str
  call os_display_cpuid

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
ret

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

; CPUID ========================================================================
; Detects and prints the CPU family
; Expects: None
; Return: None
os_display_cpuid:
  ; Check for CPUID support before executing to not crash 386 PCs
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

  ; Safe to execute CPUID instruction
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
; prints the system splash screen
; Expects: None
; Return: None
os_display_splash_screen:
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
  sub dl, 0x2
  call os_cursor_pos_set
  mov si, version_msg
  call os_print_str

  ; Press ENTER
  inc dh
  sub dl, 0x5
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

; Print full manual ============================================================
; initializes the help state
; Expects: None
; Returns: None
os_enter_manual:
  mov byte [_OS_STATE_], OS_STATE_FS
  call os_clear_shell

  mov dl, OS_FS_FILE_ID_MANUAL
  call os_fs_load_buffer
  jc .error
  call os_fs_display_buffer
ret
  .error:
  mov byte [_OS_STATE_], OS_STATE_SHELL ; give back the control
  stc
ret

; ==============================================================================
;
; PRINTING SYSTEM (DOT-MATRIX PRINTERS)
;
; ==============================================================================


; ==============================================================================
;
; PRINTING SYSTEM (DOT-MATRIX PRINTERS)
;
; ==============================================================================

; Initialize Printer ===========================================================
; initializes the printer.
; Expects: None
; Returns: CF = 0 for success, CF = 1 for error
os_printer_init:
  .check_status:
    mov dx, 0x379      ; Status port of LPT1
    in al, dx          ; Read status

    ; Check status bits:
    ; Bit 7 (0x80): BUSY (1 = Busy, 0 = Ready)
    ; Bit 6 (0x40): ACK (0 = Acknowledged)
    ; Bit 5 (0x20): Paper Out (1 = Out)
    ; Bit 4 (0x10): Selected (1 = Selected)
    ; Bit 3 (0x08): Error (1 = Error)
    movzx ax, al
    call os_print_num

    ; Check important status bits:
    ; - Bit 4 (0x10) should be 1 (Selected)
    ; - Bit 5 (0x20) should be 0 (Paper present)
    ; Don't check BUSY as it can be 1 or 0
    mov ah, al         ; Save status
    and al, 0x30       ; Mask bits 4,5 (Selected, Paper Out)
    cmp al, 0x10       ; Should be Selected=1, PaperOut=0
    jne .printer_error

  .reset_printer:
    mov dx, 0x37A      ; Control port
    mov al, 0x08       ; Set bit 3 (Initialize printer)
    out dx, al

  .set_auto_lf:
    mov dx, 0x37A      ; Control port
    mov al, 0x0C       ; Set proper control bits (includes Auto LF)
    out dx, al

  clc                ; Clear carry flag (success)
ret

  .printer_error:
    stc                ; Set carry flag (error)
ret

; Print Character to Printer ===================================================
; sends a character to the printer.
; Expects: AL = character to print
; Returns: CF = 0 for success, CF = 1 for error
os_printer_char:
  mov bl, al         ; Save character

  ; Send character to data port
  mov dx, 0x378      ; Data port
  mov al, bl         ; Restore character
  out dx, al

  ; Longer delay before strobe
  mov cx, 0xFFFF
  .delay_loop1:
    loop .delay_loop1

  ; Strobe the printer
  mov dx, 0x37A      ; Control port
  mov al, 0x0D       ; Set strobe bit (and keep other control bits)
  out dx, al

  ; Longer delay while strobed
  mov cx, 0xFFFF
  .delay_loop2:
    loop .delay_loop2

  ; Reset strobe
  mov al, 0x0C       ; Clear strobe bit (keep other control bits)
  out dx, al

  ; Wait for BUSY to go high (printer accepting data)
  mov dx, 0x379      ; Status port
  .wait_ready:
    in al, dx
    test al, 0x40    ; Check if printer is ready (ACK)
    jz .wait_ready
ret


; Print String to Printer ======================================================
; sends a string to the printer.
; Expects: SI = pointer to null-terminated string
; Returns: CF = 0 for success, CF = 1 for error
os_printer_string:
  .next_char:
    lodsb               ; Load next character from SI into AL
    test al, al          ; Check for null terminator
    jz .done

    call os_printer_char
  jmp .next_char
  .done:

  call os_printer_send_lfcr
ret

; Printing: send LF&CR =========================================================
; is used to move the printer head to the next line.
; Expects: None
; Returns: None
os_printer_send_lfcr:
  mov al, 0x0A            ; Line Feed
  call os_printer_char
  mov al, 0x0D            ; Carriage Return (just to be safe)
  call os_printer_char
ret

; Printing: send Feed ==========================================================
; is used to move the printer head to the next page.
; Expects: None
; Returns: None
os_printer_send_feed:
  mov al, 0x0C              ; Form feed character
  call os_printer_char
ret

; Print test =================================================================
; prints a test data to the printer.
; TODO: CHANGE TO PROPER FILE BUFFER PRINTING
; Expects: None
; Returns: None
os_printer_print_fs_buffer:
  mov bl, GLYPH_SYSTEM
  call os_print_prompt
  mov si, os_printer_printing_msg
  call os_print_str

  call os_printer_init
  jc .error_init

  mov si, _OS_FS_BUFFER_
  cmp byte [si], 0          ; Check if the current character is null
  je .empty_file

  call os_printer_string

  .success_print:
  mov bl, GLYPH_SYSTEM
  call os_print_prompt
    mov si, success_msg
    call os_print_str
    clc
ret
  .empty_file:
    mov bl, GLYPH_ERROR
    call os_print_prompt
    mov si, fs_empty_msg
    call os_print_str
    stc
ret
  .error_init:
    mov bl, GLYPH_ERROR
    call os_print_prompt
    mov si, failure_msg
    call os_print_str
    stc
ret

; ==============================================================================
;
; THE GAME FUNCTIONS
;
; ==============================================================================


; ==============================================================================
;
; THE GAME FUNCTIONS
;
; ==============================================================================

; Enter Game ===================================================================
; initializes the game state and draws welcome screen
; Expects: None
; Returns: None
os_enter_game:
  mov byte [_OS_STATE_], OS_STATE_GAME
  mov al, OS_VIRT_PAGE_GAME
  call os_virual_screen_set
  mov byte [_OS_GAME_STARTED_], 0x0
  call os_clear_screen

  mov dx, 0x0303
  call os_cursor_pos_set
  mov al, GLYPH_GAME_TILE_A
  mov ah, 0x23
  call os_print_chr_mul

  mov dx, 0x0504
  call os_cursor_pos_set
  mov al, GLYPH_GAME_TILE_A
  mov ah, 0x21
  call os_print_chr_mul

  mov dx, 0x0607
  call os_cursor_pos_set
  mov al, GLYPH_GAME_TILE_A
  mov ah, 0x1A
  call os_print_chr_mul

  mov dx, 0x070B
  call os_cursor_pos_set
  mov al, GLYPH_GAME_TILE_A
  mov ah, 0x12
  call os_print_chr_mul

  mov dx, 0x080D
  call os_cursor_pos_set
  mov al, GLYPH_GAME_TILE_A
  mov ah, 0x0E
  call os_print_chr_mul

  ; Game name
  mov dx, 0x0406
  call os_cursor_pos_set
  mov si, game_name_msg
  call os_print_str

  ; Rat
  mov dx, 0x0714
  call os_cursor_pos_set
  mov al, GLYPH_GAME_RAT_IDLE_R
  call os_print_chr

  ; Instructions
  mov dx, 0x0A00
  call os_cursor_pos_set
  mov si, game_instructions_table
  .instructions_loop:
    lodsw
    test ax, ax
    jz .done

    mov bx, ax
    push si
    mov si, bx
    call os_print_str
    inc dh
    call os_cursor_pos_set
    pop si
  jmp .instructions_loop
  .done:

  ; copy
  mov dx, 0x1402
  call os_cursor_pos_set
  mov si, copyright_msg
  call os_print_str
ret

game_instructions_table:
  dw game_instruction1_msg
  dw game_instruction2_msg
  dw game_instruction3_msg
  dw game_instruction4_msg
  dw game_instruction5_msg
  dw 0x0

; Game start ===================================================================
; Thus functuion starts game, draws board and initiates entities
; Expects: None
; Returns: None
os_game_start:
  mov byte [_OS_GAME_STARTED_], 0x1
  mov byte [_OS_GAME_SCORE_], 0x0

  ; Level 0
  mov byte [_OS_GAME_CURRENT_LEVEL_], GLYPH_GAME_TILE_A
  mov byte [_OS_GAME_CURRENT_LEVEL_+1], GAME_COLOR_FLOOR

  .init_entities:
    ; initialize player
    mov si, _OS_GAME_ENTITIES_
    mov byte [si+_POS_X], 0x24
    mov byte [si+_POS_Y], 0x02
    mov byte [si+_DIR], 0x0
    mov byte [si+_FRAME], 0x0
    mov byte [si+_DIRT], 0x0
    mov al, [_OS_GAME_CURRENT_LEVEL_]
    mov byte [si+_LAST_TILE], al

    add si, 0x06
    ; initialize broom
    mov byte [si+_POS_X], 0x0C
    mov byte [si+_POS_Y], 0x0D
    mov byte [si+_DIR], 0x0
    mov byte [si+_FRAME], 0x1
    mov byte [si+_DIRT], 0x0
    mov al, [_OS_GAME_CURRENT_LEVEL_]
    mov byte [si+_LAST_TILE], al

    add si, 0x06
    ; initialize broom
    mov byte [si+_POS_X], 0x0F
    mov byte [si+_POS_Y], 0x12
    mov byte [si+_DIR], 0x0
    mov byte [si+_FRAME], 0x1
    mov byte [si+_DIRT], 0x0
    mov al, [_OS_GAME_CURRENT_LEVEL_]
    mov byte [si+_LAST_TILE], al

    add si, 0x06
    ; terminator
    mov byte [si], 0x0

  ; draw level
  call os_clear_screen

  ; fill tiles
  mov al, [_OS_GAME_CURRENT_LEVEL_]
  mov bl, [_OS_GAME_CURRENT_LEVEL_+1]
  call os_fill_screen_with_glyph

  ; horizontal walls
  push 0x0000
  push 0x0B
  push 0x001B
  push 0x0B
  push 0x050C
  push 0x0E
  push 0x0D00
  push 0x06
  push 0x0D14
  push 0x12
  push 0x1114
  push 0x10
  push 0x1607 ; position
  push 0x1D   ; length
  push 0x0700 ; number of walls + type
  call os_game_spawn_walls

  ; vertical walls
  push 0x0100
  push 0x0C
  push 0x010C
  push 0x04
  push 0x011B
  push 0x04
  push 0x0127
  push 0x0C
  push 0x0D07
  push 0x09
  push 0x0D14
  push 0x04
  push 0x1225   ; pos
  push 0x04     ; length
  push 0x0701   ; number of walls + type
  call os_game_spawn_walls

  ; props
  push 0x0404
  push 0x0F09
  push 0x0420
  push 0x1420
  push GAME_COLOR_POT
  mov al, GLYPH_GAME_POT
  mov ah, 0x04
  push ax
  call os_game_spawn_items

  push 0x0608
  push 0x0B1C
  push GAME_COLOR_FLOPPY
  mov al, GLYPH_FLOPPY
  mov ah, 0x02
  push ax
  call os_game_spawn_items

  push 0x1425
  push GAME_COLOR_DOOR
  mov al, GLYPH_GAME_DOOR
  mov ah, 0x01
  push ax
  call os_game_spawn_items

  ; player
  call os_game_player_draw
ret

os_game_draw_horizontal_wall: ; IN: DX pos, CL len
  call os_cursor_pos_set
  mov al, GLYPH_GAME_WALL_CORNER
  call os_print_chr
  mov al, GLYPH_GAME_WALL_HORIZONTAL
  mov ah, cl
  call os_print_chr_mul
  mov al, GLYPH_GAME_WALL_CORNER
  call os_print_chr
ret

os_game_draw_vertical_wall: ; IN: DX pos, CL len
  .vertical_walls_loop:
    call os_cursor_pos_set
    mov al, GLYPH_GAME_WALL_VERTICAL
    call os_print_chr
    inc dh
  loop .vertical_walls_loop
ret

os_game_score_msg       db 'SCORE',0x00
os_game_high_score_msg  db 'HISCORE',0x00
os_game_level_msg       db 'LEVEL',0x00

os_game_draw_status_bar:
  mov dx, 0x1804
  call os_cursor_pos_set

  mov si, os_game_level_msg
  call os_print_str
  mov al, 0x01
  mov bl, OS_COLOR_LIGHT_CYAN_ON_BLUE
  call os_print_bcd_color

  mov al, CHR_SPACE
  mov ah, CHR_SPACE
  call os_print_chr_double

  mov si, os_game_score_msg
  call os_print_str
  mov al, byte [_OS_GAME_SCORE_]

  call os_print_bcd_color

  mov al, CHR_SPACE
  mov ah, CHR_SPACE
  call os_print_chr_double

  mov si, os_game_high_score_msg
  call os_print_str
  mov al, 0x99

  call os_print_bcd_color
ret

os_game_spawn_walls:
  push bp
  mov bp, sp          ; save stack pointer

  mov al, [bp+5]      ; get number of items
  shl al, 2           ; double for word + double for 2 elements per entry
  add al, 2           ; initial values
  mov [.return+1], al ; set return value for clearing stack

  mov si, 0x6         ; positions position
  movzx cx, [bp+5]      ; number of items
  .item_loop:
    push cx

    mov cl, [bp+si]   ; length
    mov dx, [bp+si+2] ; position

    cmp byte [bp+4], GAME_HORIZONTAL_WALL
    je .horizontal_wall
    .vertical_wall:
      call os_game_draw_vertical_wall
      jmp .next_entry
    .horizontal_wall:
      call os_game_draw_horizontal_wall
    .next_entry:
    add si, 4         ; next entry

    pop cx
  loop .item_loop

  mov sp, bp
  pop bp
  .return:
ret 0xFF

os_game_spawn_items:
  push bp
  mov bp, sp          ; save stack pointer

  mov al, [bp+5]      ; get number of items
  inc al              ; one more for the color
  shl al, 1           ; double for word
  add al, 2           ; length + glyph values
  mov [.return+1], al ; set return value for clearing stack

  mov si, 0x8         ; positions position
  mov cl, [bp+5]      ; number of items
  .item_loop:
    mov dx, [bp+si]   ; position
    call os_cursor_pos_set
    mov al, [bp+4]    ; character
    mov bl, [bp+6]    ; color
    call os_print_chr_color
    add si, 2         ; next entry
  loop .item_loop

  mov sp, bp
  pop bp
  .return:
ret 0xFF

; Draw player ==================================================================
; draws the player on the screen
; Expects: None
; Returns: None
os_game_player_draw:
  mov byte dl, [_OS_GAME_ENTITIES_+_POS_X]
  mov byte dh, [_OS_GAME_ENTITIES_+_POS_Y]
  call os_cursor_pos_set
  mov al, GLYPH_GAME_RAT_IDLE_R
  cmp byte [_OS_GAME_ENTITIES_+_DIR], 0x0
  je .skip_draw_left
  mov al, GLYPH_GAME_RAT_IDLE_L
  .skip_draw_left:
  mov bl, [_OS_GAME_ENTITIES_+_FRAME]
  shr bl, 1
  add al, bl
  mov bl, GAME_COLOR_RAT
  call os_print_chr_color
ret

; Draw broom ===================================================================
; draws the broom on the screen
; Expects: SI - entity pointer
; Returns: None
os_game_broom_draw:
  mov byte dl, [si+_POS_X]
  mov byte dh, [si+_POS_Y]
  call os_cursor_pos_set
  mov al, GLYPH_GAME_BROOM1
  add al, [si+_FRAME]
  mov bl, GAME_COLOR_BROOM
  call os_print_chr_color
ret

; Validate position ============================================================
; Validates the new position
; Expects: DX - position
; Returns: Carry if can't move (wall)
;          AL - tile type
os_game_validate_pos:
  call os_read_chr
  cmp al, [_OS_GAME_CURRENT_LEVEL_]
  je .can_move
  cmp al, GLYPH_GAME_DIRT1
  je .can_move
  cmp al, GLYPH_GAME_DIRT2
  je .can_move
  cmp al, GLYPH_GAME_DIRT3
  je .can_move
  stc
  ret
.can_move:
  clc
  ret

; Player movement ==============================================================
; moves the player
; Expects: BL - keyboard input
; Returns: None
os_game_player_move:

  .clear_background:
    push bx
    mov word dx, [_OS_GAME_ENTITIES_]
    call os_cursor_pos_set
    mov al, [_OS_GAME_ENTITIES_+_LAST_TILE]
    mov bl, [_OS_GAME_CURRENT_LEVEL_+1]
    call os_print_chr_color
    pop bx

  .check_direction:
    cmp bl, KBD_KEY_UP
    je .up
    cmp bl, KBD_KEY_DOWN
    je .down
    cmp bl, KBD_KEY_LEFT
    je .left
    cmp bl, KBD_KEY_RIGHT
    je .right
    jmp .skip_move

  .up:
    dec dh
    jmp .validate

  .down:
    inc dh
    jmp .validate

  .left:
    dec dl
    mov byte [_OS_GAME_ENTITIES_+_DIR], 0x0
    jmp .validate

  .right:
    inc dl
    mov byte [_OS_GAME_ENTITIES_+_DIR], 0x1
    jmp .validate

  .validate:
    call os_game_validate_pos
    jc .check_obstacle
    jmp .move_player

  .check_obstacle:
    cmp al, GLYPH_FLOPPY
    je .get_floppy
    cmp al, GLYPH_GAME_POT
    je .broke_pot
    jmp .skip_move  ; Enything else is probably a wall
    .get_floppy:
      ; remove floppy from map
      call os_cursor_pos_set
      mov al, [_OS_GAME_CURRENT_LEVEL_]
      mov bl, [_OS_GAME_CURRENT_LEVEL_+1]
      call os_print_chr_color

      add byte [_OS_GAME_SCORE_], 0x10
      ; beep
      jmp .move_player
    .broke_pot:
      ; broke the pot
      call os_cursor_pos_set
      mov al, GLYPH_GAME_POT_BROKEN
      mov bl, GAME_COLOR_POT
      call os_print_chr_color
      ; spawn dirt around
      mov si, os_game_positions_around
      mov cx, 0x8
      .dirt_loop:
        push dx
        lodsb
        add dl, al
        lodsb
        add dh, al
        call os_cursor_pos_set
        call os_get_random
        and ax, 0x3
        dec ax
        js .skip_dirt
        add al, GLYPH_GAME_DIRT1
        call os_print_chr
        .skip_dirt:
        pop dx
      loop .dirt_loop
      ; add points
      mov al, byte [_OS_GAME_SCORE_]
      add al, 0x5
      daa
      mov byte [_OS_GAME_SCORE_], al
      jmp .skip_move

  .move_player:
    mov byte [_OS_GAME_ENTITIES_+_LAST_TILE], al
    mov word [_OS_GAME_ENTITIES_], dx
    mov byte [_OS_GAME_ENTITIES_+_FRAME], 0x05
  .skip_move:
    call os_game_player_draw
ret

os_game_positions_around:
db -1, -1, -1, 0, -1, 1, 0, -1, 0, 1, 1, -1, 1, 0, 1, 1

; Move broom ===================================================================
; moves the broom, handles edge detection and bouncing
; Expects: SI: Entitie memory location; BL: 0=up, 1=right, 2=down, 3=left
; Returns: None
os_move_broom:

  .clear_background:
    push bx
    mov word dx, [si]
    call os_cursor_pos_set
    mov al, [si+_LAST_TILE]
    mov bl, [_OS_GAME_CURRENT_LEVEL_+1]
    call os_print_chr_color
    pop bx

  .check_move:
    cmp bl, 0
    je .up
    cmp bl, 1
    je .right
    cmp bl, 2
    je .down
    cmp bl, 3
    je .left
    jmp .skip_move

  .up:
    dec dh
    jmp .validate

  .down:
    inc dh
    jmp .validate

  .left:
    dec dl
    jmp .validate

  .right:
    inc dl
    jmp .validate

  .validate:
    call os_game_validate_pos
    jc .skip_move

  .move_player:
    mov byte [si+_LAST_TILE], al
    mov word [si], dx
  .skip_move:
    call os_game_broom_draw
    mov byte [si+_DIR], bl
ret

; Broom AI =====================================================================
; Random movement or follow player
; Expects: SI: Entitie memory location;
; Returns: None
os_game_broom_ai:
  call os_get_random
  and ax, 0x03        ; Values 0-3
  cmp ax, 0x01
  jl .follow_y        ; follow player vertically if 0
  je .follow_x        ; or horizontally if 1
  ; random move otherwise if 2-3

  .randome_move_xy:
    call os_get_random
    and ax, 0x03
    mov dx, ax
    jmp .move

  .follow_x:
    mov al, [_OS_GAME_ENTITIES_+_POS_X]
    cmp al, [si+_POS_X]
    jl .positive_x
    jg .negative_x
    jmp .move
    .negative_x:
    mov dx, 0x1
    jmp .move
    .positive_x:
    mov dx, 0x3
    jmp .move

  .follow_y:
    mov al, [_OS_GAME_ENTITIES_+_POS_Y]
    cmp al, [si+_POS_Y]
    jl .positive_y
    jg .negative_y
    je .move
    .negative_y:
    mov dx, 0x2
    jmp .move
    .positive_y:
    mov dx, 0x0
    jmp .move

  .move:
    mov bl, dl
    call os_move_broom
ret

; Game loop ====================================================================
; handles the main game loop
; Expects: None
; Returns: None
os_game_loop:
  cmp byte [_OS_GAME_ENTITIES_+_FRAME], 0x0
  je .idle
    dec byte [_OS_GAME_ENTITIES_+_FRAME]
    call os_game_player_draw
  .idle:

  mov si, _OS_GAME_ENTITIES_
  add si, 0x06
  .entites_loop:
    mov al, [si]
    test al,al
    jz .done

    call os_game_broom_ai
    call os_game_broom_draw
    cmp byte [si+_FRAME], 0x0
    jz .rewind
    mov byte [si+_FRAME], 0x0
    jmp .skip_rewind
    .rewind:
    mov byte [si+_FRAME], 0x01
    .skip_rewind:
    add si, 0x06
  jmp .entites_loop
  .done:
  call os_game_draw_status_bar
ret


; ==============================================================================
;
; COREWAR
;
; ==============================================================================

os_corewar_prog_list:
mov bl, GLYPH_MSG
call os_print_prompt

  mov si, os_corewar_example_imp
  xor cx, cx
  .memory_loop:
    mov al, [si]
    cmp al, 0xFF
    je .done
    call os_corewar_instruction_decode
    inc cx
  jmp .memory_loop
  .done:

  mov bl, GLYPH_MSG
  call os_print_prompt

  mov si, os_corewar_example_bomber
  xor cx, cx
  .memory_loop2:
    mov al, [si]
    cmp al, 0xFF
    je .done2
    call os_corewar_instruction_decode
    inc cx
  jmp .memory_loop2
  .done2:
ret

OS_CW_PROG_ID_MASK  equ 0x9F
OS_CW_PROG_ID_SHIFT equ 0x05
OS_CW_OPCODE_MASK   equ 0x1F
OS_CW_MODE_MASK     equ 0xC0
OS_CW_MODE_SHIFT    equ 0x06
OS_CW_SIGN_MASK     equ 0x20
OS_CW_SIGN_SHIFT    equ 0x05
OS_CW_VALUE_MASK    equ 0x0F

; in SI, BX
os_corewar_instruction_decode:
  mov bl, GLYPH_MSG
  call os_print_prompt

  ; PROG_ID
  mov al, '['
  call os_print_chr

  mov ax, cx
  call os_print_num

  mov al, ']'
  mov ah, ' '
  call os_print_chr_double

  xor ax, ax
  ; OPCODE
  lodsb
  call os_corewar_two_operands
  setc dl
  call os_corewar_print_opcode

  mov al, ' '
  call os_print_chr

  ; Destination
  xor ax,ax
  lodsb
  push ax
  call os_corewar_print_mode
  pop ax
  call os_corewar_print_sign_value

  cmp dl, 1
  jz .skip_operand

  mov al, ','
  mov ah, ' '
  call os_print_chr_double

  xor ax,ax
  lodsb
  push ax
  call os_corewar_print_mode
  pop ax
  call os_corewar_print_sign_value
ret
  .skip_operand:
  inc si
ret

; in AL
; out CF
os_corewar_two_operands:
  movzx bx, al
  and bl, OS_CW_OPCODE_MASK
  push si
  mov si, os_corewar_opcodes_operands
  cmp byte [si+bx], 2
  pop si
  jz .has_two
  stc
ret
  .has_two:
  clc
ret

; in AL
os_corewar_print_prog_id:
  and al, OS_CW_PROG_ID_MASK
  shr al, OS_CW_PROG_ID_SHIFT
  call os_print_num
ret

; in AL
os_corewar_print_opcode:
  and al, OS_CW_OPCODE_MASK
  push si
  mov si, os_corewar_opcodes_table
  shl al, 0x2
  add si, ax
  call os_print_str
  pop si
ret

; in AL
os_corewar_print_mode:
  and al, OS_CW_MODE_MASK
  shr al, OS_CW_MODE_SHIFT
  mov di, os_corewar_modes_table
  add di, ax
  mov al, [di]
  call os_print_chr
ret

; in AL
os_corewar_print_sign_value:
  mov bl, al
  and bl, OS_CW_SIGN_MASK
  shr bl, OS_CW_SIGN_SHIFT
  cmp bl, 0x0
  jz .skip_sign
    push ax
    mov al, '-'
    call os_print_chr
    pop ax
  .skip_sign:
  and al, OS_CW_VALUE_MASK
  call os_print_num
ret

os_corewar_enter_arena:
  mov byte [_OS_STATE_], OS_STATE_COREWAR

  mov di, _OS_COREWAR_ARENA_
  mov cx, 1000*3
  xor ax, ax
  rep stosw

  mov si, os_corewar_example_bomber
  mov di, _OS_COREWAR_ARENA_
  add di, 3*12
  mov word [_OS_COREWAR_PROG_PC_], di
  mov cx, 3*5
  rep movsb

  mov si, os_corewar_example_imp
  mov di, _OS_COREWAR_ARENA_
  add di, 3*512
  mov word [_OS_COREWAR_PROG_PC_+2], di
  mov cx, 3
  rep movsb

  mov al, CHR_SPACE
  mov bl, OS_COLOR_DARK_GRAY_ON_BLACK
  call os_fill_screen_with_glyph

  call os_corewar_arena_display
ret

os_corewar_arena_start:

ret

os_corewar_arena_simulate:
  mov si, word [_OS_COREWAR_PROG_PC_+2]
  mov di, si

  .prepare_opcode:
  movzx ax, byte [si]
  and al, OS_CW_OPCODE_MASK
  movzx dx, al      ; DL -> opcode

  .prepare_target:
    movzx ax, byte [si+1]
    movzx bx, al      ; BL -> prepare target
    and bl, OS_CW_VALUE_MASK

  .set_target:
    and al, OS_CW_MODE_MASK
    shr al, OS_CW_MODE_SHIFT
    ; there is no imidiate target
    cmp al, 0x01
    jz .set_direct_target
    cmp al, 0x02
    jz .set_indirect_target

  .set_direct_target:
    imul bx, 3
    add di, bx        ; DI -> target set
    jmp .prepare_source
  .set_indirect_target:
    mov al, byte [si+bx]
    and al, OS_CW_VALUE_MASK
    imul ax, 3
    add di, ax      ; DI -> target set
    jmp .prepare_source

  .prepare_source:
    movzx ax, byte [si+2]
    movzx bx, al      ; BL -> prepare source
    and bl, OS_CW_VALUE_MASK
  .set_source:
    and al, OS_CW_MODE_MASK
    shr al, OS_CW_MODE_SHIFT
    cmp al, 0x00
    jz .set_imidiate_source
    cmp al, 0x01
    jz .set_direct_source
    cmp al, 0x02
    jz .set_indirect_source

    .set_imidiate_source:
      ; AL -> value
      ; DL -> source set
      mov dh, 0x1
      jmp .execute_opcode
    .set_direct_source:
      imul bx, 3
      add si, bx        ; SI -> source set
      jmp .execute_opcode
    .set_indirect_source:
      mov al, byte [si+bx]
      and al, OS_CW_VALUE_MASK
      imul ax, 3
      add si, ax      ; SI -> source set
      jmp .execute_opcode


  .execute_opcode:
  cmp dl, 0x01
  jz .opcode_mov
  jmp .processed

  .opcode_mov:
    cmp dh, 0x1
    jz .imidiate_mov
    mov cx, 3
    rep movsb
    jmp .processed
    .imidiate_mov:
    mov ah, [di]
    and ah, 0xC0
    add ah, al
    or ah, 0x80
    mov [di], ah
    jmp .processed


  .processed:
    ; jmp = di - 3
    ; rest = next instruction
    add word [_OS_COREWAR_PROG_PC_+2], 3

  .done:
    call os_corewar_arena_display
ret

os_corewar_arena_display:
  call os_cursor_pos_reset
  xor ax,ax
  mov si, _OS_COREWAR_ARENA_
  mov cx, 40*24
  xor dx, dx
  .arena_loop:
    lodsb
    test al, 0x20
    jz .print_empty

    push si
    mov si, os_corewar_opcodes_table
    and ax, OS_CW_OPCODE_MASK
    shl al, 2
    add si, ax
    mov byte al, [si]
    pop si
    mov bl, OS_COLOR_GREEN_ON_BLACK

    jmp .print

    .print_empty:
      mov al, CHR_DOT
      mov bl, OS_COLOR_DARK_GRAY_ON_BLACK

    .print:
      call os_print_chr_color

    .check_new_line:
      inc dx
      cmp dx, 40
      jnz .skip_new_line

    .new_line:
      mov al, CHR_CR
      mov ah, CHR_LF
      call os_print_chr_double
      xor dx, dx
    .skip_new_line:


    add si, 2
  loop .arena_loop
ret

os_corewar_opcodes_table:
  db 'DAT', 0x0   ; data (kills the process)
  db 'MOV', 0x0   ; move (copies data from one address to another)
  db 'ADD', 0x0   ; add (adds one number to another)
  db 'JMP', 0x0   ; jump (continues execution from another address)
  db 'JZ ', 0x0   ; jump if zero
  db 'JNZ', 0x0   ; jump if not zero
  db 'CMP', 0x0   ; compare and skip if equal
  db 'NOP', 0x0   ; no operation

OS_CW_DAT equ 0x00
OS_CW_MOV equ 0x01
OS_CW_ADD equ 0x02
OS_CW_JMP equ 0x03
OS_CW_JZ  equ 0x04
OS_CW_JNZ equ 0x05
OS_CW_CMP equ 0x06
OS_CW_NOP equ 0x07

os_corewar_opcodes_operands:
  db 1  ; DAT
  db 2  ; MOV
  db 2  ; ADD
  db 1  ; JMP
  db 1  ; JZ
  db 1  ; JNZ
  db 2  ; CMP
  db 0  ; NOP

os_corewar_modes_table:
  db '#'  ;  Immediate  (data)
  db '$'  ;  Direct    (relative address of data)
  db '@'  ;  Indirect  (pointer to data)

os_corewar_example_imp:
  db 0x21, 0x41, 0x40   ; MOV $1, $0
  db 0xFF

os_corewar_example_bomber:
  db 0x22, 0x43, 0x04   ; ADD $3, #4
  db 0x21, 0x82, 0x43   ; MOV @2, $3
  db 0x23, 0x62, 0x00   ; JMP $-2
  db 0x20, 0x04, 0x00   ; DAT #4
  db 0x20, 0x00, 0x00   ; DAT #0
  db 0xFF

; =============================================================================
;
; THE VOID
;
; =============================================================================

; Void =========================================================================
; This is a placeholder function.
; Expects: None
; Returns: None
os_void:
  nop
ret

; ==============================================================================
;
; DATA SECTION
;
; ==============================================================================

version_msg           db 'Version 0x0D', 0
system_logo_msg:
db OS_GLYPH_LOGO+0x0
db OS_GLYPH_LOGO+0x1
db OS_GLYPH_LOGO+0x2
db OS_GLYPH_LOGO+0x3
db OS_GLYPH_LOGO+0x4
db OS_GLYPH_LOGO+0x5
db OS_GLYPH_LOGO+0x6
db 0x0
welcome_msg           db 'Welcome to SMOLiX Operating System', 0x0
copyright_msg         db '(C)2025 Krzysztof Krystian Jankowski', 0x0
press_enter_msg       db 'Press ENTER to begin.', 0x0
verb_msg              db 'VERB',CHR_ARROW_RIGHT,0x0
noun_msg              db 'NOUN',CHR_ARROW_RIGHT,0x0
more_info_msg         db 'Type VERB 00, NOUN 00 for help', 0x0
executed_msg          db 'Executing ', 0x0
available_cmds_msg    db 'VERB:NOUN Command:', 0x0
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
kb_msg                db 'KB', 0x0
byte_msg              db 'B', 0x0
bios_date_msg         db 'BIOS date: ', 0x0
apm_batt_msg          db 'Battery: ', 0x0
apm_batt_ac           db 'AC power', 0x0
apm_batt_life         db '% charge', 0x0
success_msg           db 'success.', 0x0
failure_msg           db 'failure.', 0x0

fs_files_list_msg     db 'Files on floppy:', 0x0
fs_select_file_msg    db 'Type VERB 31, NOUN <number>', 0x0
fs_reading_msg        db 'Reading data from disk...', 0x0
fs_writing_msg        db 'Writing data to disk...', 0x0
fs_empty_msg          db 'Empty buffer. Read data first.', 0x0
fs_read_footer_msg    db 'PAGEUP/DOWN scroll, ESC close', 0x0

os_printer_printing_msg db 'Printing...', 0x0

game_name_msg         db '- - - D I R T Y - R A T - - -', 0x0
game_instruction1_msg db 'Your mission is to collect all floppies.', 0x0
game_instruction2_msg db 'Go to a flower pot to get dirt on you.', 0x0
game_instruction3_msg db 'Spread it on the ground and avoid broom.', 0x0
game_instruction4_msg db 'Use the arrow keys to move the rat.', 0x0
game_instruction5_msg db 'Press ENTER to start, ESC to quit game.', 0x0

msg_cmd_help          db 'Quick help', 0x0
msg_cmd_manual        db 'Full system manual', 0x0
msg_cmd_version       db 'System version', 0x0
msg_cmd_reset         db 'Soft reset', 0x0
msg_cmd_reboot        db 'Hard reboot', 0x0
msg_cmd_down          db 'Shutdown', 0x0
msg_cmd_clear_shell   db 'Clear the shell log', 0x0
msg_cmd_display       db 'Toggle 40/80 screen modes', 0x0
msg_cmd_stats         db 'System statistics', 0x0
msg_cmd_glyphs        db 'Custom charset', 0x0
msg_cmd_void          db 0x0 ; Nothing
msg_cmd_fs_list       db 'List files', 0x0
msg_cmd_fs_display    db 'Display buffer content', 0x0
msg_cmd_fs_read       db 'Read file (noun) to buffer', 0x0
msg_cmd_fs_write      db 'Write file to floppy', 0x0
msg_cmd_fs_clear_buf  db 'Clear file buffer', 0x0
msg_cmd_fs_edit       db 'Edit current buffer', 0x0
msg_cmd_game          db 'Play "Dirty Rat" game', 0x0
msg_cmd_print         db 'Print current file (LPT1)', 0x0
msg_cmd_tick          db 'System tick', 0x0
msg_cmd_cw_list       db 'List program', 0x0
msg_cmd_cw_enter_arena db 'Enter arena', 0x0
fs_ruler_80_msg:
db GLYPH_RULER_START,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_NO+0x00
db GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_NO+0x01
db GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_NO+0x02
db GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_NO+0x03
db GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_NO+0x04
db GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_NO+0x05
db GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_NO+0x06
db GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_END, 0x0
fs_ruler_40_msg:
db GLYPH_RULER_START,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_NO+0x00
db GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_NO+0x01
db GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_NO+0x02
db GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_MIDDLE,GLYPH_RULER_END, 0x0

db "P1X"            ; Use HEX viewer to see `P1X` at the end of binary
os_kernel_end:
