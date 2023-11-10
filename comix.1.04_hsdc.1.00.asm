; This software is copyright 2023 by Marcel van Tongeren. You have permission to use, modify,
; copy, and distribute this software so long as this copyright notice is retained.
;
; This software may not be used in commercial applications without express written permission
; from the author.
;
; This file is not meant to be assembled in any way as it only describes the differences between
; FW Revision COMX BASIC V1.03 and COMX BASIC V1.04 & HSDC V1.00.

; CPU Type:
        CPU 1802

; Register Definitions:
R0        EQU 0                  ; Reserved for DMA on COMX
                                 ; Stepped every interrupt routine on COMiX
R1        EQU 1                  ; Interrupt address pointer
R2        EQU 2                  ; Stack pointer
R3        EQU 3                  ; Program counter
R4        EQU 4                  ; SCRT CALL
R5        EQU 5                  ; SCRT RETURN
R6        EQU 6                  ; SCRT return address
R7        EQU 7
R8        EQU 8                  ; R8.0 available
R9        EQU 9
RA        EQU 10                 ; RA available
RB        EQU 11                 ; PointerPointer to line buffer
RC        EQU 12                 ; RC available
RD        EQU 13                 ; RD parameter read/write routine
RE        EQU 14                 ; RE available
RF        EQU 15                 ; RF.1 used in SCRT to save D, RF.0 available

; Startup code to set NTSC or PAL
; ===============================

        ORG  0003DH

        LDI  80H                 ; NTSC LDI 80H - PAL LDI 0
        PLO  R7                  ; R7.0 NTSC/PAL mode
        LDI  0FFH
        PHI  RD                  ; RD.1 = FF
        BR   CLEAR_SCREEN        ; Branch to CLEAR_SCREEN to clear screen
        
        DB   00H                 ; 0x0045 = 0x0056 Not used
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
                                 ; table used to set RAM 0x41C0 - 0x41E0
        DB   0F0H                ; OUT 3
        DB   00H                 ; OUT 4 - low
        DB   57H                 ; OUT 4 - high
        DB   88H                 ; OUT 5 - low (NTSC 88H - PAL 80H)
        DB   00H                 ; OUT 5 - high
        DB   00H                 ; 0x41C5
        DB   0F8H                ; 0x41C6
        DB   00H                 ; 0x41C7
        DB   0F8H                ; 0x41C8
        DB   04H                 ; 0x41C9
        DB   08H                 ; number of character lines (NTSC 08H - PAL 09H)
        DB   0FFH                ; 0x41CB
        DB   0D4H                ; CALL to MUSIC
        DB   0BH
        DB   0BH
        DB   0D5H                ; Return
        DB   0D4H                ; CALL to TONE
        DB   0BH
        DB   11H
        DB   0D5H                ; Return
        DB   0D4H                ; CALL to NOISE
        DB   0BH
        DB   82H
        DB   0D5H                ; Return
        DB   0D4H                ; 'empty' CALL
        DB   0C4H
        DB   0C4H
        DB   0D5H                ; Return
        DB   0D4H                ; 'empty' CALL
        DB   0C4H
        DB   0DH
        DB   0F1H                ; ??
        DB   0D4H                ; 'empty' CALL
        DB   0DH
        DB   0F1H                ; not used / not copied to RAM ??
        DB   0D5H                ; not used / not copied to RAM ??
        DB   00H                 ; not used
        DB   00H                 ; not used

CLEAR_SCREEN
        PLO  RD                  ; RD = 0xFFFF
        SEX  RD                  ; X = RD
CLS_LOOP
        LDI  20H                 ; D = space
CLS_WAIT
        B1   CLS_WAIT            ; Wait for non-display period
        STXD                     ; Store space in video Page RAM
        GHI  RD
        XRI  0F7H
        BNZ  CLS_LOOP            ; Loop until page RAM is empty/clear (space)
        REQ
        SEQ                      ; first Q pulse to activate EF2 as key repeat
        REQ
        SEQ                      ; NTSC SEQ (Q=1) - PAL NOP
                                 ; .. continue in original ROM code ..

; Character Shapes
; ================

        ORG  00740H
        DB   0D4H                ; Character #, with top line 1 pixel lower
        DB   0D4H
        DB   0FEH
        DB   0D4H
        DB   0FEH
        DB   0D4H
        DB   0D4H
        DB   00H
        DB   00H

        ORG  0075BH
        DB   0D0H                ; Character # 1 pixel higher
        DB   0E8H
        DB   0E8H
        DB   0D0H
        DB   0EAH
        DB   0E4H
        DB   0DAH
        DB   00H
        DB   00H

; Main PLOAD/DLOAD Routine
; ========================

        ORG  00DF5H

PLOAD                            ; PLOAD start
        SEP  RD                  
        DB   9EH                 ; Get high byte RAM user start address
        PHI  RC                  
        LDI  00H                 
        PLO  RC                  ; RC = RAM user area start address
        LDI  081H
        PLO  R7                  ; R7.0 = pointer to DEFUS and EOP
        LDI  35H                 ; D = start address of PLOAD routine part 1
        LBR  LOAD                ; Continue at LOAD
        
DLOAD                            ; DLOAD start
        LDI  092H
        PLO  R7                  ; R7.0 = pointer to end array
        SEP  R4
        DW   2BE9H               ; CALL 0x2BE9
        SEP  RD
        DB   94H                 ; Get high byte start array (0x4294)
        PHI  RC
        LDN  RF
        PLO  RC                  ; RC = start address data
        LDI  8BH                 ; D = start address of DLOAD routine part 1
        
LOAD
        PLO  R8                  ; R8.0 = start address of PLOAD or DLOAD routine part 1
        SEP  R4                  
        DW   LINE_END_CHECK      ; CALL end of line check routine
LD_WAIT
        B1   LD_WAIT             ; Wait for non display period to clear cursor 
        SEX  R3                  
        DIS                      
        DB   23H                 ; Disable interrupt 
        GHI  RB                  
        STXD                     
        GLO  RB                  
        STXD                     ; Store RB on stack
        GHI  R7                  
        STXD                     
        GLO  R7                  
        STXD                     ; Store R7 on stack
        LDI  042H                
        PHI  R7                  ; R7 = pointer to DEFUS/EOP for PLOAD
                                 ; R7 = pointer to end array for DLOAD
        LDI  0BFH
        PHI  RF                  
        LDI  0F9H                
        PLO  RF                  ; RF = pointer to delay factors 
        LDA  RF                  
        PLO  RB                  ; RB.0 = delay factor / 2
        LDN  RF                  
        PLO  RF                  ; RF.0 = delay factor 
        LDI  13H                 
        PHI  RA                  
        LDI  44H                 
        PLO  RA                  ; RA = start core LOAD routine (get one byte)
        SEP  RA                  ; Get first byte (.comx file type)
        PHI  RB                  ; RB.1 = file type
        SEP  RA                  ; Get second byte (C)
        SEP  RA                  ; Get third byte (O)
        SEP  RA                  ; Get fourth byte (M)
        PHI RE                   ; RE.1 = high byte length for DLOAD
        GLO  R8
        PLO  R3                  ; R3 / PC = address PLOAD or DLOAD routine part 1
        
LD_0E35                          ; PLOAD routine part 1
        SEP  RA                  ; Get fifth byte (X)
        GHI  RB                  ; Get file type
        SMI  01H                 
        BNZ  LD_PLOAD_TYPE_2_6   ; If file type ≠ 1 branch to type 2/6 check
        
LD_PLOAD_TYPE_1                  ; PLOAD ML
        SEP  RA                  ; Get start address (high byte)
        PHI  RC                  
        SEP  RA                  ; Get start address (low byte)
        PLO  RC                  ; RC = start address
        SEP  RA                  ; Get end address (high byte)
        STR  R2                  
        GHI  RC                  
        SD                       
        PHI  RE                  ; RE.1 = end_high_byte - start_high_byte
        SHRC                     
        PLO  RE                  ; Save borrow bit in RE.0 bit 7
        SEP  RA                  ; Get end address (low byte)
        STR  R2                  
        GLO  RE                  
        SHL                      ; DF = borrow bit from high byte substration
        GLO  RC                  
        SDB                      
        PLO  RE                  ; RE.0 = end_low_byte - start_low_byte - borrow
                                 ; RE = length
        SEP  RA                  ; Get execution address high
        PHI  R7                  ; Store temporarily in R7.1
        LDI  0C7H
        PLO  R8                  ; R8.0 = start address of PLOAD ML routine part 2
        SEP  RA                  ; Get execution address low
        PLO  R7                  ; Store temporarily in R7.0 
        BR   LD_MAIN_LOOP        ; Continue PLOAD routine at LD_MAIN_LOOP
        
LD_PLOAD_TYPE_2_6                ; PLOAD BASIC file type 2 and 6
        GHI  RB                  ; Get file type
        SMI  01H
        BZ   LD_PLOAD_TYPE_2A    ; If file type = 2 branch to PLOAD type 2
LD_PLOAD_TYPE_6A
        SEP  RA                  ; Get sixth byte - DEFUS high byte
        ADI  44H                 ; Add 0x44, D = DEFUS high-byte
        SKP			             ; Skip sixth byte as we already got it
LD_PLOAD_TYPE_2A
        SEP  RA                  ; Get sixth byte - DEFUS high byte
	    STR R7                   ; Store DEFUS high byte in DEFUS location
 	    INC R7
        SEP  RA                  ; Get seventh byte - DEFUS low byte
	    STR R7                   ; Store DEFUS low byte in DEFUS location
 	    INC R7
        GHI  RB                  ; Get file type
        SMI  02H                 
        BZ   LD_PLOAD_TYPE_2B    ; If file type = 2 branch to PLOAD type 2
        SEP  RA                  ; Get length high byte
        PHI  RE                  ; RE.1 = length high byte for filetype 2/6
        GHI  RB                  ; Get file type
        SMI  06H                 
        BZ   LD_PLOAD_TYPE_6B    ; Skip subtraction of 0x44 for type 6
LD_ERROR_39H
        SEP  R4                  ; If file type ≠ 6 error
        DW   1076H               
        DB   39H                 ; ERROR 57 - exit

LD_PLOAD_TYPE_2B
        SEP  RA                  ; Get length high-byte + 0x44
        SMI  44H                 ; Subtract 0x44, D = length high-byte
        PHI  RE                  ; RE.1 = length high byte for filetype 2/6
LD_PLOAD_TYPE_6B
        SEP  RA                  ; Get length low byte
        PLO  RE                  ; RE = length
        SEP  RA                  ; Get byte - ignore
        SEP  RA                  ; Get byte - ignore
        SEP  RA                  ; Get byte - ignore
        LDI  0BDH
        PLO  R8                  ; R8.0 = start address of PLOAD routine part 2
        SEP  RA                  ; Get byte - ignore
        SEP  RA                  ; Get byte - ignore
        SEP  RA                  ; Get byte - ignore
        BR   LD_MAIN_LOOP        ; Continue at LD_MAIN_LOOP
        
LD_0E8B                          ; DLOAD routine part 1
        SEP  RA                  ; Get low byte DLOAD length
        PLO RE                   ; RE = length data
        GHI  RB                  ; Get file type
        XRI  05H
        BZ   LD_DLOAD_TYPE_5     ; If file type = 5 branch to DLOAD type 5
        
LD_ERROR_3AH
        SEP  R4                  
        DW   1076H               
        DB   3AH                 ; ERROR 58 - exit
        
LD_DLOAD_TYPE_5
        SEP  RA                  ; Get length array - high byte
        STR  R7                  ; Store length temporarily on M(R7) - high byte
        INC R7
        SEP  RA                  ; Get length low byte
        STR R7                   ; Store length temporarily on M(R7) - low byte
        LDI  0ADH
        PLO  R8                  ; R8.0 = start address of DLOAD routine part 2

LD_MAIN_LOOP
        DEC  RE                  ; correct length with -1
LD_LOAD_LOOP
        SEP  RA                  ; Get first program/data byte
        STR  RC                  ; Store in destination
        INC  RC                  ; Next destination
        DEC  RE                  ; Length - 1
        GHI  RE                  
        XRI  0FFH                
        BNZ  LD_LOAD_LOOP        ; If RE ≠ 0xFFFF loop
        SEX  R3                  
        RET                     
        DB   23H                 ; Enable interrupt
        GLO  R8                  
        PLO  R3                  ; R3 / PC = address PLOAD, PLOAD ML or DLOAD routine part 2
        
LD_0EAD                          ; DLOAD routine part 2
        SEP  RD
        DB   95H                 ; Get low byte start array (0x4295)
        STR  R2
        LDN  R7                  ; Get low length byte
        ADD
        STR  R7                  ; Store low byte end array (0x4293)
        DEC  R7
        SEP  RD
        DB   94H                 ; Get high byte start array (0x4294)
        STR  R2
        LDN  R7                  ; Get high length byte
        ADC
        STR  R7                  ; Store high byte end array (0x4292)
        LID  99H
        PHI  R7                  ; Set R7.0 to EOD

LD_0EBD				             ; PLOAD routine part 2
        GHI RC                   ; Get EOP or EOD (high byte)
        STR  R7                  ; Store high byte EOP (0x4282) or EOD (0x4299)
        INC  R7
        GLO  RC                  ; Get EOP or EOD (low byte)
        STR  R7                  ; Store low byte EOP (0x4283) or EOD (0x429A)
        SEP  R4
        DW   LD_RESET_DATA
        BR   LD_END              ; Finalize routine

LD_0EC7                          ; PLOAD ML routine part 2
        SEP  R4
        DW   322BH               ; CALL PRINT string routine
        DB   'EXEC: @'
        DB   00H                 ; end string
        GHI  R7                  ; Get high execution address
        SEP  R4
        DW   320FH               ; Call PRINT hex byte
        GLO  R7                  ; Get low execution address
        SEP  R4
        DW   320FH               ; Call PRINT hex byte
        SEP  R4
        DW   2E42H               ; Call PRINT new line

LD_END
        INC  R2
        LDXA
        PLO  R7
        LDXA
        PHI  R7                  ; Fetch R7 from stack
        LDXA
        PLO  RB
        LDX
        PHI  RB                  ; Fetch RB from stack
        SEP  R5                  ; Return
        
        DB   00H
        DB   00H

; Core save Routine
; =================
;
; CALL with SCRT
; RF.1 byte to save
;
        ORG  00F72H

CORE_SAVE
        GHI  RF                  
        STR  R2                  ; Save ‘save’ byte to stack
        LDI  0BFH               
        PHI  RF                  
        LDI  0FAH                
        PLO  RF                  ; RF = 0xBFFA, pointer to delay values
        LDN  RF                  
        ADI  02H                 ; save delay = delay + 2
        PLO  RF                  ; RF.0 = save delay
        LDN  R2                  
        PHI  RF                  ; RF.1 = save byte
        LDI  80H                 
        PLO  R8                  ; R8.0 = bit counter
        GLO  RF                  ; Get save delay
        REQ                      ; Start bit Q = 0
CS_LOOP1
        SMI  01H                 
        BNZ  CS_LOOP1            ; Loop delay time
        GHI  RF                  
        SHR                      ; DF = next bit
        BDF  BIT_1               ; Branch on bit value
CS_BIT_0
        REQ                      ; Q = 0
        BR   CS_CONT              
CS_BIT_1
        SEQ                      ; Q = 1
        SEX  R2                  
CS_CONT
        PHI  RF                  ; RF.1 = RF.1 >> 1
        GLO  R8                  
        SHR                      
        PLO  R8                  ; R8.0 = R8.0 >> 1
        BZ   CS_STOP_BIT         ; If D = 0, 8 bits are done
        SEX  R2                  ; One dummy instruction for timing
        GLO  RF                  
        SMI  05H                 ; Set next delay
        BR   CS_LOOP1            ; Next bit
CS_STOP_BIT
        GLO  RF                  
        SMI  03H                 ; Set next delay
CS_LOOP2
        SMI  01H                 
        BNZ  CS_LOOP2            ; Loop delay time
        SEX  R2                  ; One dummy instruction for timing
        SEQ                      ; Stop bit Q = 1
        GLO  RF                  ; Set next delay
CS_LOOP3
        SMI  01H                
        BDF  CS_LOOP3            ; Loop delay time
        SEP  R5                  ; Return
        
; Multiple word SAVE Routine
; ==========================
;
; RC = pointer to table
; 1: number of words
; 2: high byte to word list (all words will be reduced by 0x4400)
; 3 - end: low byte to word list
;
SAVE_TABLE_RC
        GHI  RE                  
        STXD                     
        GLO  RE                  
        STXD                     
        GLO  RA                  
        STXD                     ; Store RE & RA.0 on stack
        LDA  RC                  
        PLO  RA                  ; RA = number of bytes
        LDA  RC                  
        PHI  RE                  ; RE.1 = high byte to word list
ST_NEXT_WORD
        LDA  RC                  
        PLO  RE                  ; RE.0 = low byte to word list
        LDA  RE                  ; Get high byte word
        SMI  44H                 ; reduce with 0x44
        SEP  R4                  
        DW   CORE_SAVE           ; Save byte over serial connection
        LDA  RE                  ; Get low byte word
        SEP  R4                  
        DW   CORE_SAVE           ; Save byte over serial connection
        DEC  RA                  ; Reduce word counter
        GLO  RA                  ; D = word counter
        BNZ  ST_NEXT_WORD        ; If not zero continue with next word
        INC  R2                  
        LDXA                     
        PLO  RA                  
        LDXA                     
        PLO  RE                  
        LDX                      
        PHI  RE                  ; Get RE & RA.0 from stack
        SEP  R5                  ; Return
        
LD_RESET_DATA
        GLO  R7
        SMI  9AH
        BZ   LD_END              ; If DLOAD don't reset data addresses
        SEP  R4
        DW   2BE9H               ; CALL 0x2BE9
LD_RD_END
        SEP  R5

        DB   00H                 ; 0x0FCf - 0x0FFF Not used
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H

; Welcome message part 1
; ======================

        ORG  01013H

        SEP  R4                  
        DW   322BH               ; CALL PRINT string routine
        DB   0AH                 
        DB   'tuvw NTSC BASIC V1'; tuvw = COMX logo - NTSC for NTSC; PAL for PAL ROM
        DB   00H                 ; end string
        SEP  R4                  
        DW   WELCOM_PART_2       ; CALL welcome part 2 routine

; Bug fix for EDIT x
; ==================

        ORG  010D5H

        BR   103EH               ; System ROM code - changed LBR 103EH to BR 3EH
EDIT_FIX
        LDN  RB                  ; Get first character after EDIT
        SMI  0DH                 ; If any of the values checked SK thru
        LSZ
        SMI  0C0H
        LSZ
        SMI  03H
        LSZ
        SMI  01H
        LSZ
        SMI  01H
        LSZ
        SMI  10H
        LBZ  1808H               ; If not zero - start EDIT command on 1808H
        SEP  R4
        DW   1076H
        DB   06H                 ; Error code 6

; Table for use of setting .comx header
; =====================================

        DB   02H                 ; 2 words 
        DB   10H                 ; Both words are stored on 0x10xx
        DB   0FBH                ; First word is located on 0x10FB - 0x874F CO
        DB   0FDH                ; Second word is loacted on 0x10FD - 0x9158 MX
        DB   05H                 ; 5 words
        DB   42H                 ; All 5 words are stored on 0x42xx
        DB   81H                 ; DEFUS
        DB   83H                 ; EOP
        DB   92H                 ; End array
        DB   94H                 ; Start array
        DB   99H                 ; EOD
        DB   87H                 ; -0x44 => C
        DB   'O'                 ;          O
        DB   91H                 ; -0x44 => M
        DB   'X'                 ;          X

; BAUD command text
; =================

        ORG  0124FH

        DB   'BAUD'              ; BAUD command text, instead of TOUT

; Core load Routine
; =================
;
; CALL routine via SEP Rx with CORE_LOAD in Rx
; Delay factors RB.0 half delay, RF.0 full delay
; Return value, loaded byte in D and RF.1
;
        ORG  01343H

CL_END
        SEP  R3                  ; Return
CORE_LOAD
        B4   CORE_LOAD           ; Wait for stop bit
        LDI  0FFH                
        PHI  RF                  ; RF.0 = 0xFF used to count 8 bits when 0 is shifted back
                                 ;  into DF as well as the result byte
CL_START_BIT
        BN4  CL_START_BIT        ; Wait for start bit
        GLO  RB                  ; Get half delay factor, to end up in the middle of the start bit
        SKP                      ; Skip loading full delay on entry
CL_NEXT_BIT
        GLO  RF                  ; Get delay factor
CL_WAIT_DELAY
        SMI  01H                 
        BNZ  CL_WAIT_DELAY       ; Wait delay - executes 2 instructions per delay value
                                 ; (1 = 2 instr., 2 = 4 instr., etc.)
                                 ;  When 0 -> D=00 and DF=1
        B4   CL_BIT_0            ; Test next bit - on first entry we are still on the start bit,
                                 ;  i.e., 0!
CL_BIT_1
        SKP                      ; If bit=1, leave DF=1
CL_BIT_0
        SHR                      ; If bit=0, set DF=0
        GHI  RF                  ; Get result byte
        SHRC                     ; Shift bit into byte (DF into D7, D0 into DF)
        PHI  RF                  ; RF.1 is keeping result
        SEX  R2                  ; Dummy instruction for timing purpose
        BDF  CL_NEXT_BIT         ; If DF=1, then start bit hasn't shifted thru as yet
        BR   CL_END              ; Branch to return
        
        DB   00H                 ; not used
        DB   00H                 ; not used
        DB   00H                 ; not used

; Main PSAVE Routine
; ==================

PSAVE
        LDN  RB                  ; Get first available byte from line buffer
        XRI  0DH                 ; Check on end of line
        BZ   PS_START            ; If end of line, entry is just PSAVE
        XRI  0C0H                ; Check on : 
        BZ   PS_START            ; If :, entry is just PSAVE : 
        
        SEP  R4                  ; Here we likely have PSAVE start,end or PSAVE start,end,exec
                                 ;  (i.e., PSAVE for machine language
        DW   1DC4H               ; CALL 0x1DC4 which fetches start value from line buffer
        GHI  RC                  ; Routine returns start value in RC
        PHI  RA                 
        GLO  RC                  
        PLO  RA                  ; RA = start
        LDN  RB                  
        XRI  0C2H                ; Check line buffer for a ‘,’
        BZ   PS_ML_CHECK_END     ; If ‘,’ we likely have an end value
PS_ERROR_34H
        SEP  R4                  ; No ‘,‘ so give an ERROR 
        DW   1076H               
        DB   34H                 ; ERROR 52 - exit
PS_ML_CHECK_END
        INC  RB                  ; Increment line buffer pointer
        SEP  R4                  
        DW   1DC4H               ; CALL 0x1DC4 which fetches end value from line buffer
        GHI  RC                  ; Routine returns end value in RC
        PHI  RE                  
        GLO  RC                  
        PLO  RE                  ; RE = end
PS_ML_START
        B1   PS_ML_START         ; Wait for non display period to clear cursor 
        SEX  R3                  
        DIS                      
        DB   23H                 ; Disable interrupt 
        LDI  01H                 
        SEP  R4                  
        DW   CORE_SAVE           ; Save first byte value 1 to indicate file type is ML
        LDI  10H                 
        PHI  RC                  
        LDI  0F0H                
        PLO  RC                  ; RC = 0x10F0, table for COMX header
        SEP  R4                  
        DW   SAVE_TABLE_RC       ; Save bytes on RC table, i.e., COMX
        GHI  RA                  
        SEP  R4                  
        DW   CORE_SAVE           ; Save high byte start
        GLO  RA                  
        SEP  R4                  
        DW   CORE_SAVE           ; Save low byte start
        GHI  RE                  
        SEP  R4                  
        DW   CORE_SAVE           ; Save high byte end
        GLO  RE                  
        SEP  R4                  
        DW   CORE_SAVE           ; Save low byte end
        LDN  RB                  
        XRI  0C2H                ; If line buffer is a , we have an exec value, this is never
                                 ;  used on a COMiX but part of .comx format
        BNZ  PS_ML_NO_EXEC              
        INC  RB                  
        SEP  R4                 
        DW   1DC4H               ; CALL 0x1DC4 which fetches exec value from line buffer
        GHI  RC                  
        SEP  R4                  
        DW   CORE_SAVE           ; Save high byte exec
        GLO  RC                  
        SEP  R4                  
        DW   CORE_SAVE           ; Save low byte exec
        BR   PS_ML_CALC_LENGTH               
        
PS_ML_NO_EXEC
        GHI  RA                  
        SEP  R4                  
        DW   CORE_SAVE           ; Save high byte start as exec 
        GLO  RA                  
        SEP  R4                  
        DW   CORE_SAVE           ; Save low byte start as exec 
        
PS_ML_CALC_LENGTH
        GLO  RE                  
        STR  R2                  
        GLO  RA                  
        SD                       
        PLO  RE                  
        GHI  RE                 
        STR  R2                  
        GHI  RA                  
        SDB                      
        PHI  RE                  ; RE = RE - RA = end - start = length
        BR   PS_CORRECT_LENGTH            
        
PS_START
        B1   PS_START            ; Wait for non display period to clear cursor 
        SEX  R3                  
        DIS                      
        DB   23H                 ; Disable interrupt 
        LDI  06H                 
        SEP  R4                  
        DW   CORE_SAVE           ; Save first byte value 6 to indicate file type is BASIC or
                                 ;  ML+BASIC
        LDI  10H                 
        PHI  RC                  
        LDI  0F0H                
        PLO  RC                  ; RC = 0x10F0, table for COMX header
        SEP  R4                  
        DW   SAVE_TABLE_RC       ; Save bytes on RC table, i.e., COMX
        SEP  R4                  
        DW   SAVE_TABLE_RC       ; Save bytes on RC table, i.e., DEFUS, EOP, end array, start
                                 ;  array, EOD
        SEP  RD                  
        DB   83H                 ; Get EOP high byte
        SMI  44H                 
        PHI  RE                  
        LDN  RF                  
        PLO  RE                  ; RE = EOP - 0x4400, length
        LDI  44H                 
        PHI  RA                  
        LDI  00H                 
        PLO  RA                  ; RA = 0x4400, start 
        
PS_CORRECT_LENGTH
        DEC  RE                  ; RE = RE - 1
        LBR  SV_SAVE_LOOP        ; Continue at main SAVE LOOP
        
READ_FIX
        GHI  RE
        LBZ  22F2H               ; If RE.1 = 0 - no data is available so branch to error 32
        LBR  22D9H               ; Execute READ command
        
        DB   00H                 ; not used

; Welcome message part 2
; ======================

        ORG  014B4H

WELCOM_PART_2
        SEP  R4                  
        DW   322BH               ; CALL PRINT string routine
        DB   '.04'               ; Finish first line (.04 from V1.04)
        DB   0DH                
        DB   0AH                 
        DB   0AH                 
        DB   'HIGH SPEED DIRECT CONNECT V1.00'
        DB   0DH                 
        DB   0AH                 
        DB   0AH                 
        DB   00H                 ; end string
        LDI  0BFH                
        PHI  RF                  
        LDI  0F9H                
        PLO  RF                  ; RF = 0xBFF9, pointer to delay values
        LDI  03H                 
        STR  RF                  ; Set half delay default to 3 for COMiX and 2 for COMX
        INC  RF                  
        LDI  05H                 
        STR  RF                  ; Set delay default to 5 for COMiX and 4 for COMX
        SEP  R5                  ; Return
        
        DB   00H                 ; 0x14EE = 0x14FD Not used
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 

; Changes in jump table
; =====================

        ORG  0152EH

        DW   PSAVE               ; 0x1361
        DW   PLOAD               ; 0x0DF7
        
        ORG  01540H

        DW   DSAVE               ; 0x1672
        DW   DLOAD               ; 0x0E02
  
        ORG  01564H
      
        DW   EDIT_FIX            ; 0x10D7

        ORG  01568H
      
        DW   BAUD                ; 0x16C0

; Main DSAVE Routine
; ==================

        ORG  01672H

DSAVE
        SEP  R4                  
        DW   LINE_END_CHECK      ; CALL end of line check routine
DS_WAIT 
        B1   DS_WAIT             ; Wait for non display period to clear cursor 
        SEX  R3                  
        DIS                      
        DB   23H                 ; Disable interrupt
        LDI  05H
        SEP  R4
        DW   CORE_SAVE           ; Save first byte value 5 to indicate file type is data
        LDI  16H
        PHI  RC
        LDI  0EFH
        PLO  RC                  ; RC = 0x16EF, table for CO header
        SEP  R4
        DW   SAVE_TABLE_RC       ; Save bytes on RC table, i.e., COMX
        SEP  RD                  
        DB   94H                 ; Get start array (high byte)
        PHI  RA                  ; RA.1 = start array (high byte)
        LDN  RF                  ; Get start array (low byte)
        STR  R2                  ; Store on stack
        PLO  RA                  ; RA = start array pointer
        SEP  RD
        DB   9AH                 ; Get EOD (low byte)
        SM                       ; EOD - start array (low byte)
        PLO  RE                  ; RE.0 = EOD - start array
        GHI  RA                  ; Get start array (high byte)
        STR  R2                  ; Store on stack
        SEP  RD                  
        DB   99H                 ; Get EOD (high byte)
        SMB                      ; EOD - start array - borrow (high byte)
        PHI  RE                  ; RE = length data part
        SEP  R4
        DW   CORE_SAVE           ; Save byte over serial connection
        GLO RE
        SEP  R4
        DW   CORE_SAVE           ; Save byte over serial connection
        GLO  RA                  ; Get start array (low byte)
        STR  R2                  ; Store on stack
        SEP  RD                  
        DB   93H                 ; Get end array (low byte)
        SM                       ; End array - start array (low byte)
        PLO RC                   ; RC.0 = array length (low byte)
        GHI  RA                  ; Get high EOP
        STR  R2                  ; Store on stack
        SEP  RD                  ;
        DB   92H                 ; Get end array (high byte)
        SMB                      ; End array - start array - borrow (high byte)
        SEP  R4
        DW   CORE_SAVE           ; Save byte over serial connection
        GLO RC
        SEP  R4
        DW   CORE_SAVE           ; Save byte over serial connection
        DEC  RE                  ; correct length with -1

SV_SAVE_LOOP
        LDA  RA                  ; Get first program/data byte
        SEP  R4                  
        DW   CORE_SAVE           ; Save byte over serial connection
        DEC  RE                  ; Length - 1
        GHI  RE                  ; Get length (high byte)
        XRI  0FFH                
        BNZ  SV_SAVE_LOOP        ; Loop until length = -1
        SEX  R3                  
        RET                      
        DB   23H                 ; Enable interrupt
        SEP  R5                  ; Return
        
; BAUD Routine
; ============

BAUD                             
        LDI  0BFH
        PHI  RF
        LDI  0FAH
        PLO  RF                  ; RF = delay pointer, 0xBFFA
BD_LOOP1
        BN4  BD_LOOP1            ; Wait for start bit
        LDI  01H
BD_LOOP2
        ADI  01H     
        B4   BD_LOOP2            ; Loop until D0
BD_LOOP3
        ADI  01H     
        B4   BD_LOOP3            ; Loop until D1 (return / 0x0D)
        SHR                      ; Divide by 2 to get delay for 1 bit
        SMI  013H                ; Subtract 13 to get the right delay factor
        PLO  R8                  ; Store delay factor in R8.0
        STR  RF                  ; Store on 0xBFFA
        DEC  RF                  ; RF = 0xBFF9
        SHR                      ; Divide by 2 to get half delay factor
        BNF  BD_EVEN
        ADI  01                  ; +1 if value is uneven
BD_EVEN
        STR  RF                  ; Store on 0xBFF9
        LDI  0H
        PHI  R8
        PLO  RA
        PHI  RA
        SEP  R5

        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   00H
        DB   01H                 ; 1 words
        DB   10H                 ; word is stored on 0x10xx
        DB   0FBH                ; word is located on 0x10FB - 0x874F CO
        
; Line end check routine
; ======================

LINE_END_CHECK
        LDN  RB                  ; Get character from line buffer
        XRI  0DH                 
        BZ   LEC_RETURN          ; Return if 0xD  
LEC_ERROR_2AH
        SEP  R4                  
        DW   1076H               
        DB   2AH                 ; ERROR 42 - exit
LEC_RETURN
        SEP  R5                  ; Return

; Part of LIST 
; ============
;
; Corrected to avoid crash when using BAUD in a BASIC program
;
        ORG  017B3H

        LDN  RA                  ; Get byte from memory where BASIC program is stored          
        XRI  0D2H                ; Check on 0xD2      
        BNZ  R17D4               ; If NOT 0xD2 continue on 0x17D4 (this was 0x17C4 where 0xB4
                                 ;  was checked)
        INC  RA                  ; Special handling for 0xD2 commands - irrelevant for our case...          
        SEP  R4                            
        DW   1DB5H                
        SEP  R4                     
        DW   3239H               
        SEP  R4                  
        DW   2FB1H               
        BR   1734H                     
        DB   00H                 ; Special handling of TOUT removed - note this also crashed in
                                 ;  original BASIC
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                 
        DB   00H                
        DB   00H                
        DB   00H                 
        DB   00H                 
R17D4
        LDN  RA                  ; Continue check for other special commands

; Line error FIX for >=65535
; ==========================

        ORG  01AD7H
        
LINE_NUMBER_FIX
        GLO  R7
        SMI  0D0H
        BNZ  LNF_ORIG_1          ; If R7 is not 0D0H not a number
        LDA  R9                  ; R9 is pointer to 4 byte number
        BNZ  LNF_ERROR           ; If 1st byte (highest) is not zero number is > 65535 -> error
        LDA  R9
        BNZ  LNF_ERROR           ; If 2nd byte not zero number is > 65535 -> error
        LDN  R9
        SMI  0FFH                ; If 3rd byte is not 0xFF number is not 65535
        BNZ  LNF_ORIG_2          ; Continue original code
        INC  R9
        LDN  R9
        DEC  R9                  ; Set R9 to the right location
        SMI  0FFH
        BZ   LNF_ERROR           ; If 4th byte (lowest) is 0xFF number is 65535 -> error
        BR   LNF_ORIG_2          ; Continue original code
LNF_ORIG_1
        INC  R9                  ; Original code
        INC  R9                  ; Original code
LNF_ORIG_2
        LBR  34F7H               ; Original code (LBR 34F7H instead of BR F7H)
LNF_ERROR
        SEP  R4
        DW   1076H
        DB   2CH                 ; Error code 44

; Part of command entry
; =====================
;
; Corrected to avoid crash when using BAUD in a BASIC program
;
        
        ORG  02AE2H

R2AE2
        LDA  RB                  ; Get byte from command line         
        INC  R8                            
        XRI  0D2H                        
        BZ   R2AF0                      
        XRI  01H                      
        BZ   R2AF0                     
        XRI  67H                 ; Check if command is 0xB4, i.e. TOUT/BAUD       
        BR   R2AFA               ; Changed BNZ to BR so 0xB4 is handled as any other command       
R2AF0
        INC  RB                           
        INC  RB                           
        INC  RB                            
        INC  RB                            
        INC  R8                      
        INC  R8                   
        INC  R8                  
        INC  R8                  
        BR   R2AE2                 
R2AFA
        XRI  0B9H                ; Continue command handling...       

; Part of command entry 
; =====================
;
; Corrected to avoid crash when using BAUD in a BASIC program
;
        
        ORG  02D70H

R2D70
        LDA  RA                  ; Get byte from command line          
        XRI  0D2H                       
        BZ   R2D7D               
        XRI  01H                 
        BZ   R2D7D               
        XRI  67H                 ; Check if command is 0xB4, i.e. TOUT/BAUD       
        BR   R2D83               ; Changed BNZ to BR so 0xB4 is handled as any other command          
R2D7D
        INC  RA                      
        INC  RA                    
        INC  RA                 
        INC  RA                 
        BR   R2D70              
R2D83
        XRI  0B9H                ; Continue command handling...    
   
; Part of command entry
; =====================
;
; Corrected to avoid crash when using line numbers >=65535
;
        ORG  034E6H
        
        LBR  LINE_NUMBER_FIX     ; Execute line number checks
        DB   00H

; Part of READ command
; ====================
;
; Corrected to avoid crash when READ when there are no DATA statements
;
        ORG  03D0AH
        
        SEP  R4
        DW   READ_FIX             ; Execute READ check

        END

