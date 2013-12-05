; Initialization sequence: 
; 1. send high nibble for function set
; 2. send high nibble of function set
; 3. send low nibble of function set
; 4. send turn display ON (2 nibbles in sequence)
; 5. send entry mode (2 nibbles in sequence)
;------------------------------------------------------------------
; Assumptions: 
; -sending low nibble right after high nibble require NO wait
; exceptions for above rule is 1st nibble of initialization step
; -function set: can only use DL=0, N=1, F=0
; -RS connected to P1.3
; -E  connected to P1.2
; -RW connected to ground (can only write LCD)
; -D7-D4 (data input) connect to P1.7-P1.4
;------------------------------------------------------------------
; -string to be displayed is called MyString
; -string terminated by 0H 


				ORG 00H
START:
	ACALL INIT_DISPLAY
	SETB P1.3
	MOV A,#'C'
	LCALL SendData
	LJMP STOP
; -------  procedure init_display -------
INIT_DISPLAY:	
	CLR P1.3
	ANL P1,#00000111B	; ZERO ALL BITS EXCEPT THE LAST ONE, AND P1.3=0 => RS=0 => Send Cmd
	ORL P1,#00100000B	; P1=0010 DDDD WHERE D = DON'T CARE 	
	SETB P1.2		; 
	CLR P1.2		; send high nibble	
	ACALL delay		; wait					
													
	SETB P1.2		; (set function)	<<EXCEPTION>>
	CLR P1.2		; send high nibble (2nd time)

	ANL P1,#00000111B	; ZERO ALL BITS EXCEPT THE LAST ONE, AND P1.3=0 => RS=0 => Send Cmd
	ORL P1,#10000000B	; P1=1000 DDDD WHERE D = DON'T CARE 
	SETB P1.2		; 
	CLR P1.2		; send low nibble
	ACALL delay		; wait

	ANL P1,#00001111B ; (Turn ON LCD - high nibble) ~ 0 0 0 0 --> 0 0 0 0
	SETB P1.2		; 
	CLR P1.2		; send high nibble

	ANL P1,#11110111B	; clear bits 1-3
	ORL P1,#11110000B	; set bits 7-4, (Turn ON LCD - low nibble) ~> 1 D C B --> 1 1 1 1, display ON, Cursor ON, Blink ON
	SETB P1.2		; 
	CLR P1.2		; send low nibble
	ACALL delay		; wait 

	ANL P1,#00001111B ; (set entry mode - high nibble) ~ 0 0 0 0 --> 0 0 0 0  	
	SETB P1.2		; 
	CLR P1.2		; send high nibble

	ORL P1,#01100000B	; (set entry mode - low nibble) ~> 0 1 I/D S --> 0 1 1 0
	SETB P1.2		; cursor direction right, No display shift
	CLR P1.2		; sent low nibble
	ACALL delay		; wait
	RET

; -------  procedure delay -------
delay:	
	MOV R0, #50	
	DJNZ R0, $	
	RET
; -------  procedure SEND CHAR -------
SEND_CHAR:	
	MOV C, ACC.7	; 
	MOV P1.7, C		; 
	MOV C, ACC.6	; 
	MOV P1.6, C		; FIRST 4 BITS
	MOV C, ACC.5	; 
	MOV P1.5, C		; 
	MOV C, ACC.4	; 
	MOV P1.4, C		
		
	SETB P1.2		; 
	CLR P1.2		; send high nibble
	
	MOV C, ACC.3	; 
	MOV P1.7, C		; 
	MOV C, ACC.2	; 
	MOV P1.6, C		; SECOND 4 BITS
	MOV C, ACC.1	; 
	MOV P1.5, C		; 
	MOV C, ACC.0	; 
	MOV P1.4, C		

	SETB P1.2		; 
	CLR P1.2		; send low nibble	
	ACALL delay		; wait
	RET
; -------  end procedure sendcharacter -------

SendCmd:
	CLR P1.3		; P1.3=0 => RS=0 => Because we are sending a Cmd
	ACALL SEND_CHAR	; SEND_CHAR will send every bit in the accumalator
	STAY_CMD:
	JB P1.7, STAY_CMD	; WHILE BUSY FLAG UP, STAY HERE
	RET

SendData:
	SETB P1.3		; P1.3=0 => RS=0 => Because we are sending a Cmd
	ACALL SEND_CHAR	; SEND_CHAR will send every bit in the accumalator
	STAY_DATA:
	JB P1.7, STAY_DATA	; WHILE BUSY FLAG UP, STAY HERE
	RET

STOP:
	SJMP STOP