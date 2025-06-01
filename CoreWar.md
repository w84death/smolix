# SmolCoreWar

## Description
Simplified, custom version of a Core War. A programming game introduced in 1984 by D. G. Jones and A. K. Dewdney. In the game, two or more battle programs, known as warriors, compete for control of a virtual computer.

## Opcodes

0 DAT — data (kills the process)
1 MOV — move (copies data from one address to another)
2 ADD — add (adds one number to another)
3 JMP — jump (continues execution from another address)
4 JZ  — jump if zero
5 JNZ — jump if not zero
6 CMP — compare and skip if equal (combines SEQ/SNE)
7 NOP — no operation

## Addressing modes
0 = # Immediate  (literal value)
1 = $ Direct (relative address)
2 = @ Indirect (pointer)

## Assembly style
SMOLiX CoreWar Syntax (Intel-style):
INSTRUCTION destination, source

## Example warrior code:
### Imp
100: MOV 1, 0

## Bomber
100: ADD $3, #4      ; Add 4 to position 103 (our pointer)
101: MOV @2, $3      ; Copy position 104 to location pointed to by position 103
102: JMP $-2         ; Jump back
103: DAT #4          ; Pointer
104: DAT #0          ; Bomb

## Environment

### Arena seizes
Small: 1000
Big: 2000

## Memory layout
Classinc IMP:
[0] MOV $1, $0

Is represented in 3 bytes:
db 0x01, 0x41, 0x40

First byte is Program ID and Opcode
EMPTY >> 7 + PROG_ID >> 5 + OPCODE & 16
0 0000000

Second and third are values with adressing mode
MODE >> 6 + SIGN >> 5 + VALUE & 16
00 0 00000

MOV $1, $0
MOV = 1*32 + 1 = 33 / 0x21
$1 = 1*64 + 0*32 + 1 = 65 / 0x41
$0 = 1*64 + 0*32 + 0 = 64 / 0x40



ADD $3, #4    ; 1*32 + 2 = 34 . 1*64 + 0*32 + 3 . 0*64 + 0*32 + 4
MOV @2, $3    ; 1*32 + 1 = 33 . 2*64 + 0*32 + 2 . 1*64 + 0*32 + 3
JMP $-2       ; 1*32 + 3 = 35 . 1*64 + 1*32 + 2 . 0
DAT #4        ; 1*32 + 0 = 32 . 0*64 + 0*32 + 4 . 0
DAT #0        ; 1*32 + 0 = 32 . 0*64 + 0
