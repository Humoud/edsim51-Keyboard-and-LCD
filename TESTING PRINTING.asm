MAIN:
	MOV A,#1
	LCALL START_Display			; PROMPT USER TO ENTER MESSAGE
	LCALL delay
	CLR A
	LCALL START_Display			; CLEAR DISPLAY THEN,
								; PROMPT USER TO SELECT ENCRYPT/DECRYPT
	LCALL delay
								; RESULT IS NOW IN REGISTER A
	LCALL CLEAR_LCD
	LCALL DELAY
	
DISPLAY_RESULT:
	LCALL READ_FROM_R0
STOP_PROG:
	SJMP STOP_PROG
;----------------------------------START OF LCD PROCEDURES--------
START_Display:
	SETB P1.3
	CJNE A,#0,FIRST_TIME
SECOND_TIME:
	ACALL CLEAR_LCD
	MOV DPTR,#MESSAGE2
	SJMP DISPLAY
FIRST_TIME:
	ACALL INIT_DISPLAY
	MOV DPTR,#MESSAGE
	SJMP DISPLAY

READ_FROM_R0:				; DISPLAY FROM R0
	MOV R0,#50H
	MOV A,@R0
READ_A:
	CJNE A,#23H,R0_TO_LCD
	RET
R0_TO_LCD:
	MOV A,#'H'
	LCALL SendData
	INC R0
	MOV A,@R0
	SJMP READ_A

CLEAR_LCD:
	CLR A
	MOV A,#1
	ACALL SendCmd		; THIS SHOULD CLEAR THE DISPLAY
	RET
DISPLAY:
	CLR A
	MOVC A,@A+DPTR
	CJNE A,#0,CONT
	LJMP STOP
	
CONT:
	LCALL SendData
	INC DPTR
	SJMP DISPLAY
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
	MOV R3, #50	
	DJNZ R3, $	
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
	RET

SendData:
	SETB P1.3		; P1.3=1 => RS=1 => Because we are sending a Cmd
	ACALL SEND_CHAR	; SEND_CHAR will send every bit in the accumalator
	RET

STOP:
	RET

MESSAGE: DB "ENTER A MESSAGE" 
		DB 00H
MESSAGE2: DB "Press 1 to Decrypt or else to Encrypt" 
		DB 00H

END