		ORG 00H

            
SCAN:
	CALL CHECK
	CALL WhichRow
	CALL GET_KEY
	CALL NoKeyPressed
	SJMP SCAN


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

;ASCII LOOK-UP TABLE FOR EACH ROW
      ORG     300H
KCODE3: DB     1,2,3     ;ROW 3
KCODE2: DB     4,5,6     ;ROW 2
KCODE1: DB     7,8,9     ;ROW 1
KCODE0: DB     10,0,11   ;ROW 0
      END
