			ORG 00H
	LJMP MAIN

			ORG 300H

MAIN:
	MOV A,#0
	ACALL START_Display			; PROMPT USER TO ENTER MESSAGE
	LCALL START_SERIAL			; RECIEVE MESSAGE & STORE IT IN 30H
	MOV A,#1
	ACALL START_Display			; PROMPT USER TO SELECT ENCRYPT/DECRYPT
	; KEYPAD
	CALL CHECK
	CALL WhichRow
	CALL GET_KEY
	; RESULT IS NOW IN REGISTER A

;----------------------------------START OF LCD PROCEDURES--------
START_Display:
	ACALL INIT_DISPLAY
	SETB P1.3
	MOV DPTR,#MESSAGE
	JZ DISPLAY
	MOV DPTR,#MESSAGE2
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
	ACALL DELAY	; WHILE BUSY FLAG UP, STAY HERE
	RET

STOP:
	RET

;----------------------------------END OF LCD PROCEDURES---------

;----------------------------------START OF SERIAL PROCEDURES----

START_SERIAL:
	CLR SM0			; 
	SETB SM1		; put serial port in 8-bit UART mode
	SETB REN		; enable recieving of serial port

	MOV R1,#0		; R1 contains number of bytes to be sent
	MOV TMOD, #20H		; put timer 1 in 8-bit auto-reload interval timing mode
	MOV TH1, #0FAH		; put -3 in timer 1 high byte (timer will overflow every 3 us)
	MOV TL1, #0FAH		; put same value in low byte 
	SETB TR1		; start timer 1
	MOV R0,#30H		; location to store received string
LOOP:	
	JNB RI, LOOP		; wait for character to be received 
	CLR RI			;
	MOV A,SBUF		; read character
	CJNE A,#0DH, STORE	; if not end of line, store it
	SJMP FINISH_RECIEVE
START_PRINTING_SERIAL:
	MOV R0,#30H		; else, start sending 
PRINT:
	MOV A,@R0		; read character from memory
	MOV SBUF,A		; send it to serial port
LOOP2:  JNB TI,LOOP2		; wait till transmission finish
	CLR TI			;
	INC R0			; increment pointer
	DJNZ R1,PRINT		; check if end of string (# of char)
	SJMP $			

STORE:	
	INC R1			; increment number of characters received 
	MOV @R0,A		; store receive character in memory
	INC R0			; update memory pointer
	SJMP LOOP		; repeat

FINISH_RECIEVE:
	RET
;-------------------------------END OF SERIAL PROCEDURES-----

;-------------------------------START OF LCD PROCEDURES------

GET_KEY:  
       RLC A			;skip D7 data (unused)
GET:
       RLC A                    ;see if any CY bit low
       JNC MATCH                ;if zero, get the key number        
       INC DPTR                 ;point to next col. address
       SJMP GET               ;keep searching
MATCH: CLR A                    ;set A=0 (match is found)
       MOVC A,@A+DPTR           ;get key number from table, store result in A
       RET
;------------
NoKeyPressed:
      MOV P0,#01110000B      ; GROUND all rows
      MOV A,P0               ;  read all col.
      ANL A,#01110000B       ;  masked unused bits
      CJNE A,#01110000B,NoKey   ; check til all keys released, is any col. == 0?
      SJMP NoKeyPressed
NoKey:
      RET
;-------------
CHECK:    
      MOV P0,#01110000B      ; GROUND all rows
      MOV A,P0               ;  read all col.
      ANL A,#01110000B       ;  masked unused bits
      CJNE A,#01110000B,CHECK   ; check til all keys released, is any col. == 0?
DOUBLE_CHECK:           
      MOV A,P0                 ;see if any key is pressed
      ANL A,#01110000B         ;mask unused bits
      CJNE A,#01110000B,PRESSED  ;key pressed, await closure
      SJMP DOUBLE_CHECK
PRESSED:
      RET
;-------------
WhichRow:          ;find which key is is pressed
       MOV P0,#01111110B        ;ground row 0
       MOV A,P0                 ;read all columns
       ANL A,#01110000B         ;mask unused bits
       CJNE A,#01110000B,ROW_0  ;key row 0, find the col.
       MOV P0,#01111101B        ;ground row 1
       MOV A,P0                 ;read all columns
       ANL A,#01110000B         ;mask unused bits 
       CJNE A,#01110000B,ROW_1  ;keyrow 1, find the col.
       MOV P0,#01111011B        ;ground row 2
       MOV A,P0                 ;read all columns
       ANL A,#01110000B         ;mask unused bits
       CJNE A,#01110000B,ROW_2  ;key row 2, find the col.
       MOV P0,#01110111B        ;ground row 3
       MOV A,P0                 ;read all columns
       ANL A,#01110000B         ;mask unused bits
       CJNE A,#01110000B,ROW_3  ;keyrow 3, find the col.
       RET                      ;if none, false input, return

ROW_0: MOV DPTR,#KCODE0         ;set DPTR=start of row 0        
       RET                ;find col. key belongs to
ROW_1: MOV DPTR,#KCODE1         ;set DPTR=start of row 1
       RET                ;find col. key belongs to
ROW_2: MOV DPTR,#KCODE2         ;set DPTR=start of row 2 
       RET                ;find col. key belongs to
ROW_3: MOV DPTR,#KCODE3         ;set DPTR=start of row 3
       RET 


;FOR PROMPTING
MESSAGE: DB "ENTER A MESSAGE" 
		DB 00H
MESSAGE2: DB "Press 1 to Decrypt or 2 to Encrypt" 
		DB 00H
;ASCII LOOK-UP TABLE FOR EACH ROW
      ORG     300H
KCODE3: DB     1,2,3     ;ROW 3
KCODE2: DB     4,5,6     ;ROW 2
KCODE1: DB     7,8,9     ;ROW 1
KCODE0: DB     10,0,11   ;ROW 0
      END
END
