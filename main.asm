;==================================================================
;---------  CODE THIET KE MACH DEN BAO GIAO THONG NGA TU ----------
;==================================================================
;////////////////////// KHAI BAO BAN DAU //////////////////////////
;==================================================================
TIME EQU R2					;BIEN THOI GIAN
DO13 BIT P1.0				;noi den do 1 va 3 voi port 1.0
VANG13 BIT P1.1				;noi den vang 1 va 3 voi port 1.1
XANH13 BIT P1.2				;noi den xanh 1 va 3 voi port 1.2
DO24 BIT P1.3				;noi den do 2 va 4 voi port 1.3
VANG24 BIT P1.4				;noi den vang 2 va 4 voi port 1.4
XANH24 BIT P1.5				;noi den xanh 2 va 4 voi port 1.5
DTIME EQU 04H				;THOI GIAN SANG DEN DO LUU O THANH GHI R4, DO KHONG CO LENH MOV R1,R4 NEN PHAI DUNG CHE DO TRUC TIEP
VTIME EQU 05H				;THOI GIAN SANG DEN VANG LUU O THANH GHI R5
XTIME EQU 06H				;THOI GIAN SANG DEN XANH LUU O THANH GHI R6
BLINK EQU 1					;THOI GIAN NHAP NHAY DEN VANG SAU 23H, CHU KI LA 2S
TEMP EQU R7					;BIEN TAM THOI
RSEC DATA 23H				;LUU THOI GIAN THUC - GIAY
RMIN DATA 24H				;LUU THOI GIAN THUC	- PHUT
RHOUR DATA 25H				;LUU THOI GIAN THUC	- GIO
AUTO_MOD BIT PSW.1			;CO CHE DO TU DONG HOAC BANG TAY. MAC DINH THEO LUAT GIAO THONG THI CAC MOC THOI GIAN TOI THIEU LA NHU DEFAULT
							;NEU LINH HOAT THI CO THE BAT DAU MODE SOM HOAC KEO DAI LAU HON, KHONG THE THU NHO HON. 
							;NEU DA DIEU KHIEN BANG TAY THI KHONG CON TU DONG, PHAI RESET
;
SCL BIT P1.6				;DATA
SDA BIT P1.7				;CLOCK
DS1307W EQU 0D0H			;CHE DO 8051 GHI VAO RTC
DS1307R EQU 0D1H			;CHE DO 8051 DOC TU RTC
FLAGS DATA 20H				;CAC CO CAN THIET CHO I2C
LASTREAD BIT FLAGS.0		;CO DANH CHO BYTE CUOI CUNG, SE KHONG CO ACKNOWLEDGE
_12_24 BIT FLAGS.1
PM_AM BIT FLAGS.2
OSC BIT FLAGS.3
SQW BIT FLAGS.4
ACK BIT FLAGS.5				;ACKNOWLEDGE TREN 8051
BUS_FAULT BIT FLAGS.6
_2W_BUSY BIT FLAGS.7		;HAI DAY DANG BAN, CHUA SAN SANG CHO NHIEM VU TIEP THEO
BITCOUNT DATA 21H			;DUNG DE KIEM TRA XEM DU 8 BIT CHUA
;
;==================================================================
ORG 0000H					;RESET CHUONG TRINH CHAY O CHE DO BINH THUONG
	LJMP MAIN
ORG 0003H					;NGAT PHUC VU NUT BAM CHUYEN CHE DO THAP DIEM: SAU 23H DEN 5H
	CLR AUTO_MOD			;KHI DIEU KHIEN BANG TAY THI MAT TU DONG CHO DEN KHI RESET
	LCALL THAPDIEM
	RETI
ORG 000BH
	LJMP ISR_DELAY1			;NGAT PHUC VU DELAY 1S
ORG 0013H
	CLR AUTO_MOD			;KHI DIEU KHIEN BANG TAY THI MAT TU DONG CHO DEN KHI RESET
	LCALL CAODIEM			;NGAT PHUC VU NUT BAM CHUYEN CHE DO CAO DIEM
	RETI 
;==================================================================
;//////////////////////// CHUONG TRINH CHINH //////////////////////
;==================================================================
ORG 0030H
MAIN:
;START CONFIGURATION
	MOV TMOD,#21H			;TIMER0 CHAY MODE1, TIMER0 CHAY MODE2 DANH CHO I2C
	MOV TL0,#38H			;45000 CHU KI
    MOV TH0,#50H			;45000 CHU KI
	SETB PT0				;UU TIEN NGAT TIMER0
	MOV IE,#10000111B		;CHO PHEP NGAT TIMER0 VA INT0
	CLR IE0					;XOA CO BAO NGAT INT0
	CLR IE1					;XOA CO BAO NGAT INT1
	SETB IT0				;NGAT INT0 THEO SUON XUONG
	SETB IT0				;;NGAT INT1 THEO SUON XUONG
	CLR	TF0					;XOA CO TRAN TIMER0
	SETB TR0				;TIMER0 BAT DAU DEM
	MOV R3,#0				;R3 TRONG ISR
	MOV P1,#0				;dua port 1 ve muc logic 0 de tat het den
	MOV DPTR,#MALED			;khai bao con tro DPTR tro toi mang MALED
	MOV XTIME,#10			;DAT THOI GIAN CHO O CHE DO BINH THUONG, MAC DINH
	MOV DTIME,#15			
	MOV VTIME,#5
	SETB AUTO_MOD			;MAC DINH CHE DO TU DONG
;

	MOV TH1,#0FDH 	 		; Initialize the serial port for 9600 baud.
	MOV SCON,#52H
	SETB TR1				;BAT TIMER1
	SETB SDA ; ENSURE SDA HIGH
	LCALL SCL_HIGH ; ENSURE SCL HIGH
	CLR ACK ; CLEAR STATUS FLAGS
	CLR BUS_FAULT
	CLR _2W_BUSY
;FINISH CONFIGURATION

LAPTONG:
;------------------------------------------------------------------	
	LCALL KT_CHEDO			;KIEM TRA GIO DE TU DONG CHON CHE DO PHU HOP
	MOV TIME,XTIME			;DAT THOI GIAN SANG
	MOV R0,DTIME			;DAT SO DEM CHO 13
	MOV R1,XTIME			;DAT SO DEM CHO 24
LAP1:
	LCALL HIENSO			;HIEN SO RA LEG 7 SEG THEO PHUONG PHAP QUET LED
    LCALL B1				;BAT TAT DEN LED
    CJNE TIME,#0FFH,LAP1	;LAP LAI CHO DEN LUC DU XTIME THI THOI LAN TIME THI THOI	
							;NEU DE OFFH THI R0 BI DEM THEM 1S, CON NEU DE 00H THI R1 CHUA DEM SO 0           
;------------------------------------------------------------------	
	LCALL KT_CHEDO
	MOV TIME,VTIME	
	MOV R0,VTIME		
	MOV R1,VTIME			
LAP2:	
	LCALL HIENSO
    LCALL B2
    CJNE TIME,#0FFH,LAP2           
;------------------------------------------------------------------
	LCALL KT_CHEDO	
    MOV TIME,XTIME
	MOV R0,XTIME			
	MOV R1,DTIME			
LAP3:	
	LCALL HIENSO
    LCALL B3
    CJNE TIME,#0FFH,LAP3         
;------------------------------------------------------------------	
	LCALL KT_CHEDO
	MOV TIME,VTIME		
	MOV R0,VTIME
	MOV R1,VTIME			
LAP4:	
	LCALL HIENSO
    LCALL B4
    CJNE TIME,#0FFH,LAP4          
;------------------------------------------------------------------	
    LJMP LAPTONG

;==================================================================
;///////////////// CHUONG TRINH CON CUA CAC NGAT //////////////////
;==================================================================
ISR_DELAY1:
	MOV TL0,#38H		;45000 CHU KI
    MOV TH0,#50H
    INC R3				;20 LAN NGAT THI SE GIAM TIME 1 LAN
    CJNE R3,#20,EXIT1	;20 x 45000 x 1.085us ~ 1000ms = 1s
    MOV R3,#0
    DEC TIME
	DEC R0				;GIAM SO DEM1
	DEC R1				;GIAM SO DEM2
EXIT1:
	RETI
;==================================================================
;///////////////// CHUONG TRINH CON CAC CHE DO  ///////////////////
;==================================================================
CAODIEM:				;KHI CAO DIEM
	MOV XTIME,#15		;DAT THOI GIAN CHO CAO DIEM, DEN VANG VAN GIU NGUYEN
	MOV DTIME,#20		;
	RET
;------------------------------------------------------------------
THAPDIEM:				;SAU 23H
	CLR P3.0			;TAT 4 DEN HIEN SO
	CLR P3.1
	CLR P3.6
	CLR P3.7
	CLR DO13			;TAT CAC DEN DO VA XANH
	CLR DO24
	CLR XANH13
	CLR XANH24
LAP_TONG_THAPDIEM:
		
	MOV TIME,#BLINK		;THOI GIAN NHAP NHAY DEN VANG
						;THAY DOI TIME CUA MAIN
						;TIMER VAN TIEP TUC DEM TRONG LUC NAY, NHUNG THOI KHONG QUAN TAM				
LAP1_THAPDIEM:	
	SETB VANG13			;BAT DEN VANG
	SETB VANG24
    CJNE TIME,#0H,LAP1_THAPDIEM
	
	MOV TIME,#BLINK
LAP2_THAPDIEM:	
	CLR VANG13			;TAT DEN VANG
	CLR VANG24													    
    CJNE TIME,#0H,LAP2_THAPDIEM
	LCALL KT_CHEDO		;TRONG VONG LAP RIENG NAY THI CUNG PHAI KIEM TRA GIO
	SJMP LAP_TONG_THAPDIEM
	RET
;==================================================================
;///////////////// CHUONG TRINH CON BAT TAT LED ///////////////////
;==================================================================
B1:	
	CLR DO24			;tat den do 2 va 4
	CLR VANG13			;tat den vang 1 va 3
	SETB DO13			;bat den do 1 va 3
	SETB XANH24			;bat den xanh 2 va 4
	RET
B2:	
	CLR XANH24			;tat den xanh 2 va 4
	SETB VANG24			;bat den vang 2 va 4
	RET
B3:	
	CLR DO13			;tat den do 1 va 3
	CLR VANG24			;tat den vang 2 va 4
	SETB DO24			;bat den do 2 va 4
	SETB XANH13			;bat den xanh 1 va 3
	RET
B4:	
	CLR XANH13			;tat den xanh 1 va 3
	SETB VANG13			;bat den vang 1 va 3
	RET
;==================================================================
;///////////////// CHUONG TRINH CON HIEN SO 7-SEG /////////////////
;==================================================================
HIENSO:		
	MOV A,R1		
	MOV B,#10		
	DIV AB			;LAY SO HANG CHUC VA DON VI	
	MOVC A,@A+DPTR
	MOV P0,A		;7SEG10 HIEN SO HANG CHUC
	SETB P3.0		;BAT 7SEG10
	CLR P3.1		;TAT 7SEG11
	CLR P3.0		;TAT 7SEG10
	MOV A,B
	MOVC A,@A+DPTR
	MOV P0,A		;7SEG11 HIEN SO HANG DON VI
	SETB P3.1		;BAT 7SEG11
	CLR P3.0		;TAT 7SEG10
	CLR P3.1
	MOV A,R0
	MOV B,#10
	DIV AB			;LAY SO HANG CHUC VA DON VI
	MOVC A,@A+DPTR
	MOV P2,A		;7SEG20 HIEN SO HANG CHUC
	SETB P3.6
	CLR P3.7
	CLR P3.6
	MOV A,B
	MOVC A,@A+DPTR
	MOV P2,A		;7SEG21 HIEN SO HANG DON VI
	SETB P3.7
	CLR P3.6
	CLR P3.7
	RET
;==================================================================
;/////////// CHUONG TRINH CON CHUYEN MA BCD SANG MA HEXA //////////
;==================================================================
BCD_HEX:
	MOV B,#10H		;LAY TUNG CHU SO BIEU DIEN
	DIV AB
	MOV TEMP,B 		;CAT HANG DON VI
	MOV B,#10
	MUL AB
	ADD A,TEMP		;Ax10+TEMP
	RET
;==================================================================
;//////////////// CHUONG TRINH CON KIEM TRA CHE DO ////////////////
;==================================================================
KT_CHEDO:
	JNB AUTO_MOD,THOAT_KT_CHEDO	;NEU KHONG PHAI CHE DO TU DONG THI KHONG CHAY PHAN DUOI
	CLR LASTREAD ; FLAG TO CHECK FOR LAST READ
	LCALL SEND_START ; SEND 2WIRE START CONDITION
	MOV A,#DS1307W ; SEND DS1307 WRITE COMMAND
	LCALL SEND_BYTE
	MOV A,#01H ; SET POINTER TO REG ON DS1307; CHUONG TRINH CHUAN DAT 02H DE LAY HOUR
	LCALL SEND_BYTE
	LCALL SEND_STOP ; SEND STOP CONDITION
	LCALL SEND_START ; SEND START CONDITION
	MOV A,#DS1307R ; SEND DS1307 READ COMMAND
	LCALL SEND_BYTE
	SETB LASTREAD
	LCALL READ_BYTE ; READ A BYTE OF DATA
	LCALL SEND_STOP
	LCALL BCD_HEX
	CJNE A,RHOUR,XET_GIO	;XEM GIO DA THAY DOI CHUA
	SJMP THOAT_KT_CHEDO		;NEU CHUA THI KHONG XET
XET_GIO:
	MOV RHOUR,A 	; MOVE DATA INTO SCRATCHPAD MEMORY
;BAT DAU KIEM TRA	
	CJNE A,#01,CHECK5H	;KIEM TRA 23H - BAT DAU THAP DIEM; CHUONG TRINH CHUAN DAT 23
	LCALL THAPDIEM
CHECK5H:	;KIEM TRA 5H - KET THUC THAP DIEM
	CJNE A,#02,CHECK7H
	LJMP 00H
CHECK7H:	;BAT DAU CAO DIEM 1
	CJNE A,#03,CHECK9H
	LJMP CAODIEM
CHECK9H:	;KET THUC CAO DIEM 1
	CJNE A,#04,CHECK18H	
	LJMP 00H
CHECK18H:	;BAT DAU CAO DIEM 2
	CJNE A,#05,CHECK20H
	LJMP CAODIEM
CHECK20H:	;KET THUC CAO DIEM 2
	CJNE A,#06,THOAT_KT_CHEDO	
	LJMP 00H
THOAT_KT_CHEDO: 
	RET	
;-----------------------------------------------------------------------
; THIS SUB SENDS THE START CONDITION
;-----------------------------------------------------------------------
SEND_START: ;
	SETB _2W_BUSY ; INDICATE THAT 2WIRE OPERATION IN PROGRESS
	CLR ACK ; CLEAR STATUS FLAGS
	CLR BUS_FAULT
	JNB SCL,FAULT ; CHECK FOR BUS CLEAR
	JNB SDA,FAULT ; BEGIN START CONDITION
	SETB SDA ;
	LCALL SCL_HIGH ; SDA
	CLR SDA
	;
	LCALL DELAY ; SCL ^START CONDITION
	CLR SCL
	RET
	FAULT:
	SETB BUS_FAULT ; SET FAULT STATUS
	RET ; AND RETURN
;-----------------------------------------------------------------------
; THIS SUB SENDS THE STOP CONDITION
;-----------------------------------------------------------------------
SEND_STOP: ;
	CLR SDA ; SDA
	LCALL SCL_HIGH ;
	SETB SDA ; SCL ^STOP CONDITION
	CLR _2W_BUSY
	RET
;-----------------------------------------------------------------------
; THIS SUB SENDS ONE BYTE OF DATA TO THE DS1307
;-----------------------------------------------------------------------
SEND_BYTE:
	MOV BITCOUNT,#08H ; SET COUNTER FOR 8 BITS
SB_LOOP:
	JNB ACC.7,NOTONE ; CHECK TO SEE IF BIT 7 OF ACC IS A 1
	SETB SDA ; SET SDA HIGH (1)
	JMP ONE
NOTONE:
	CLR SDA ; CLR SDA LOW (0)
ONE:
	LCALL SCL_HIGH ; TRANSITION SCL LOW-TO-HIGH
	RL A ; ROTATE ACC LEFT ONE BIT
	CLR SCL ; TRANSITION SCL HIGH-TO-LOW
	DJNZ BITCOUNT,SB_LOOP ; LOOP FOR 8 BITS
	SETB SDA ; SET SDA HIGH TO LOOK FOR ACKNOWLEDGE PULSE
	LCALL SCL_HIGH ; TRASITION SCL LOW-TO-HIGH
	CLR ACK ; CLEAR ACKNOWLEDGE FLAG
	JNB SDA,SB_EX ; CHECK FOR ACK OR NOT ACK
	SETB ACK ; SET ACKNOWLEDGE FLAG FOR NOT ACK
SB_EX:
	LCALL DELAY ; DELAY FOR AN OPERATION
	CLR SCL ; TRANSITION SCL HIGH-TO-LOW
	LCALL DELAY ; DELAY FOR AN OPERATION
	RET
;-----------------------------------------------------------------------
; THIS SUB READS ONE BYTE OF DATA FROM THE DS1307
;-----------------------------------------------------------------------
READ_BYTE:
	MOV BITCOUNT,#008H ; SET COUNTER FOR 8 BITS OF DATA
	MOV A,#00H ;
	SETB SDA ; SET SDA HIGH TO ENSURE LINE FREE
READ_BITS:
	LCALL SCL_HIGH ; TRANSITION SCL LOW-TO-HIGH
	MOV C,SDA ; MOVE DATA BIT INTO CARRY BIT \
	RLC A ; ROTATE CARRY BIT INTO ACC.0
	CLR SCL ; TRANSITION SCL HIGH-TO-LOW
	DJNZ BITCOUNT,READ_BITS ; LOOP FOR 8 BITS
	JB LASTREAD,ACKN ; CHECK TO SEE IF THIS IS THE LAST READ
	CLR SDA ; IF NOT LAST READ, SEND ACKNOWLEDGE BIT
ACKN:
	LCALL SCL_HIGH ; PULSE SCL TO TRANSIMIT ACKNOWLEDGE
	CLR SCL ; OR NOT ACKNOWLEDGE BIT
	RET
;----------------------------------------------------------------------- 
; THIS SUB SETS THE CLOCK LINE HIGH
;-----------------------------------------------------------------------
SCL_HIGH:
	SETB SCL ; SET SCL HIGH
	JNB SCL,$ ; LOOP UNTIL STRONG 1 ON SCL
	RET
;----------------------------------------------------------------------- 
; THIS SUB DELAY THE BUS
;-----------------------------------------------------------------------
DELAY:
	NOP ; DELAY FOR BUS TIMING
	RET
;-----------------------------------------------------------------------
; THIS SUB DELAYS 4 CYCLES
;-----------------------------------------------------------------------
DELAY_4:
	NOP ; DELAY FOR BUS TIMING
	NOP
	NOP
	NOP
	RET
;==================================================================
;/////////////////////// BANG THAM CHIEU LED  /////////////////////
;==================================================================
;su dung LED 7 thanh anode chung
;bang tham chieu MALED tu so 0 den so 9		
MALED: DB 0C0H,0F9H,0A4H,0B0H,99H,92H,82H,0F8H,80H,90H	;khai bao mang du lieu MALED	
;------------------------------------------------------------------		
	END