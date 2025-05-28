# SmolCoreWar

## Description



## DSKY input

Verb 60 : Noun 00 - show CoreWar instructions, list, overall "main screen"
Verb 60 : Noun 01 - list warriors
Verb 60 : Noun 02 - list code of selected warrior (last one is "new")
Verb 60 : Noun 03 - insert selected warrior into arena
Verb 60 : Noun 10 - start battle simulation (arena screen, ESC to back)
Verb 60 : Noun 11 - end battle arena
Verb 60 : Noun 12 - back to arena screen

Verb 61 : Noun XX - select warrior

Verb 62 : Noun XX - change line to edit of selected warrior

Verb 63 : Noun XX - change opcode XX
Verb 64 : Noun XY - change addressing mode (#,$,@); X for A, Y for B
Verb 65 : Noun XX - value A
Verb 66 : Noun XX - value B (if needed)
Verb 67 : Noun 00 - proceed to next line
Verb 67 : Noun 01 - go to previous line
Verb 67 : Noun 02 - go to beginning
Verb 67 : Noun 03 - go to last line

Opcodes:

0 DAT — data (kills the process)
1 MOV — move (copies data from one address to another)
2 ADD — add (adds one number to another)
3 JMP — jump (continues execution from another address)
4 JZ  — jump if zero
5 JNZ — jump if not zero
6 CMP — compare and skip if equal (combines SEQ/SNE)
7 NOP — no operation

Addressing modes:
0 = # Immediate  (literal value)
1 = $ Direct (relative address)
2 = @ Indirect (pointer)

Values (for A and B):
00-49: Positive values 0 to +49
50-99: Negative values -50 to -1 (subtract 100)

SMOLiX CoreWar Syntax (Intel-style):
INSTRUCTION destination, source

## Example warrior code:
### Imp
100: MOV 1, 0

## Bomber
100: ADD 3, #4      ; Add 4 to position 103 (our pointer)
101: MOV @3, 4      ; Copy position 104 to location pointed to by position 103
102: JMP -2         ; Jump back
103: DAT #4         ; Pointer
104: DAT #0         ; Bomb

## Environment

### Arena seizes
Small: 1000
Big: 2000
