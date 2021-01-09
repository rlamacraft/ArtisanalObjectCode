0x2FF0 // START

// the length of subroutines
0x000D // 0 PRINT NEWLINE
0x0004 // 1 ALLOCATE MEMORY
0x0006 // 2 READ STRING
0x0010 // 3 ECHO
0x0004 // 4 BITWISE OR
0x0005 // 5 LEFT BITSHIFT
0x000A // 6 READ NIBBLE
0x0008 // 7 READ WORD
0x0017 // 8 MAIN
0x0000
0x0000
0x0000
0x0000
0x0000
0x0000
0x0000 // leave null

  // BOOT ROUTINE
  // - Calculate the memory location of subroutines based on their length
  // - Allocates space for the stack
  // - Finishes by jumping to the last subroutine
  LEA R0 0x1EF  | 0xE1EF // next - 0x11 = 0x2FF0
  LEA R1 0x1FE  | 0xE3FE // next - 0x02 = 0x3000
  ADD R6 R0 0   | 0x1C20 // store 0x2FF0 for jumping later
  LEA R2 0x0    | 0xE400 // when looping, jump back to the next instruction
  LDR R3 R0 0   | 0x6600 // get length of subroutine being calculated
  BRANCH = 4    | 0x0404 // null-terminated list, so we're done
  ADD R1 R1 R3  | 0x1243 // cumulative memory location
  STR R1 R0 0   | 0x7200 // update length with cumulative memory location
  ADD R0 R0 0x1 | 0x1021 // move to next
  JMP R2        | 0xC080 // repeat
  LDI R7 0x1    | 0x2E01 // Return with pointer to stack in place
  JMP R1        | 0xC040 // jump to last subroutine
  CONST STACK   | 0x8000

  // PRINT NEWLINE
  // - Modifies R0
	LDI R0 0x02      | 0x2002 // R0 = '\n'
	TRAP TRAP_OUT    | 0xF021 // print char
	RETURN           | 0xC9C0
	CONST '\n'       | 0x000A

  // ALLOCATE MEMORY
  // - Inputs
  // -- R0: Requested number of memory 16-bit words
  // - Outputs
  // -- R0: Address of requested memory
  // - Modifies: R0 R1
  LD R1 HEAD   | 0x2204
  ADD R1 R1 R0 | 0x1240
  LD R0 HEAD   | 0x2002
  ST R1 HEAD   | 0x3201
	RETURN       | 0xC9C0
  VAR HEAD     | 0x8100 // 0x8000 to 0x80FF is for the stack

  // READ LINE
  // - Outputs
  // -- R0: Address of read string
  // - Modifies R0 R1 R2 R3 R4 R5
  // - Assumptions:
  // -- ALLOCATE MEMORY returns a block all zeroed
  // -- User will not type more than 79 characters
  LD R0 _80      | 0x200D // Request 80 words i.e. a line
  LDR R4 R6 0x1  | 0x6981 // ALLOCATE MEMORY
  JSRR R4        | 0x4100
  AND R5 R0 R0   | 0x5A00 // R5 = R0
  AND R1 R0 R0   | 0x5200 // R1 = R0
  LEA R2 0x0     | 0xE400 // Loop back to next
  TRAP IN        | 0xF023 // Read a character
  STR R0 R1 0x0  | 0x7040 // Store that char
  ADD R0 R0 0x16 | 0x1036 // R0 -= '\n'
  BRANCH = 0x2   | 0x0402 // If 0, jump to return
  ADD R1 R1 0x1  | 0x1261 // Increment memory pointer
  JMP R2         | 0xC080 // Repeat
  AND R0 R5 R5   | 0x5145 // R0 = R1
  RETURN         | 0xC9C0
  CONST _80      | 0x0050
  CONST X        | 0xFFF6 // the inverse of '\n'

  // ECHO
  LDR R4 R6 0x2 | 0x6982 // read string
  JSRR R4       | 0x4100
  TRAP PUTS     | 0xF022 // echo it back
  RETURN        | 0xC9C0

  // BITWISE OR
  // - Inputs: R0 R1
  // - Outputs: R0
  // - Modifies: R0 R1
  NOT R0 R0    | 0x903F
  NOT R1 R1    | 0x927F
  AND R0 R0 R1 | 0x5001
  NOT R0 R0    | 0x903F
  RETURN       | 0xC9C0

  // LEFT BITSHIFT
  // - Inputs
  // -- R0: Bitstring
  // -- R1: The number of times; > 0
  // - Outputs
  // -- R0: R0 << R1
  // -- R1: 0x0
  // -- R2: R2 << R1 | overflow(R0 << R1)
  ADD R2 R2 R2      | 0x1482 // R2 = 2 * R2
  AND R0 R0 R0      | 0x5000 // no-op but sets status register
  BR >= 3           | 0x0603 // if R0 < 0
  NOT R2 R2         | 0x94BF //   R2 = R2 | 0x00001
  AND R2 R2 0x11110 | 0x54BE
  NOT R2 R2         | 0x94BF
  ADD R0 R0 R0      | 0x1000 // R0 = 2 * R0
  ADD R1 R1 -1      | 0x127F // R1--
  BR > -9           | 0x03F7 // if R1 > 0, repeat
  RETURN            | 0xC9C0

  // READ NIBBLE
  // - Output: R0
  // - Modifies: R0 R1
  // - Input has to be capital i.e. from set {0-9,A-F}
  TRAP IN      | 0xF023 // R0 = input()
  // subtract 0x39 so that {'0'..'9'} < 0 and {'A'..'F'} > 0
  LD R1 0x5    | 0x2205
  ADD R0 R0 R1 | 0x1001
  // if R0 in {A..F} then add 0x2 else add 0x9
  BR > 0x1     | 0x0201
  ADD R0 0x7   | 0x1027
  ADD R0 0x2   | 0x1022
  RETURN       | 0xC9C0
  0x39         | 0xFFC7

  // READ WORD
  // - Modifies: R0 R1 R2 R3 R4 R5
  // 1. print "0x"
  LEA R0 0x12    | 0xE012 // R0 = "0x"
  TRAP TRAP_PUTS | 0xF022 // print

  // 2. read nibble
  LDR R4 R6 0x6 | 0x6986
  JSRR R4       | 0x4100

  ADD R5 R5 0x3 | 0x1B63 // i
  LEA R3 0x0    | 0xE600 // Loop back here
  // 3. Shift left
  AND R2 R2 0x0     | 0x54A0
  AND R1 R1 0x4 | 0x5264
  LDR R4 R6 0x5 | 0x6985
  JSRR R4       | 0x4100

  // 4. Read another nibble
  AND R2 R0 R0  | 0x5400 // R2 = R0
  LDR R4 R6 0x6 | 0x6986
  JSRR R4       | 0x4100 // R0 = readNibble()
  AND R1 R2 R2  | 0x5282 // R1 = R2
  LDR R4 R6 0x4 | 0x6984
  JSRR R4       | 0x4100 // R0 = R1 | R0

  // 5. Loop
  ADD R5 R5 -0x1 | 0x1B7F // i--
  BR = 0x1       | 0x0401
  JMP R3         | 0xC0C0

  // 4. End
  RETURN        | 0xC9C0
  '0'           | 0x0030
  'x'           | 0x0078
  \00           | 0x0000

  // MAIN
  LDR R4 R6 0x7 | 0x6987 // read word
  JSRR R4       | 0x4100

	AND R2 R2 0x0 | 0x54A0 // bit shift left 4
  AND R1 R1 0x4 | 0x5264
  LDR R4 R6 0x5 | 0x6985
  JSRR R4       | 0x4100

  AND R5 R0 R0  | 0x5A00 // print overflow
  LDR R4 R6 0x0 | 0x6980
  JSRR R4       | 0x4100
  LD R0 7       | 0x2007
  ADD R0 R0 R2  | 0x1002
  TRAP OUT      | 0xF021
  AND R0 R5 R5  | 0x5145

  ADD R1 R1 0x4 | 0x1264 // bit shift left 4 more times
  LDR R4 R6 0x5 | 0x6985
  JSRR R4       | 0x4100

  TRAP HALT     | 0xF025

  0x30          | 0x0030
