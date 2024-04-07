PROCESSOR 18F8722

#include <xc.inc>

; CONFIGURATION (DO NOT EDIT)
; CONFIG1H
CONFIG OSC = HSPLL      ; Oscillator Selection bits (HS oscillator, PLL enabled (Clock Frequency = 4 x FOSC1))
CONFIG FCMEN = OFF      ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
CONFIG IESO = OFF       ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)
; CONFIG2L
CONFIG PWRT = OFF       ; Power-up Timer Enable bit (PWRT disabled)
CONFIG BOREN = OFF      ; Brown-out Reset Enable bits (Brown-out Reset disabled in hardware and software)
; CONFIG2H
CONFIG WDT = OFF        ; Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit))
; CONFIG3H
CONFIG LPT1OSC = OFF    ; Low-Power Timer1 Oscillator Enable bit (Timer1 configured for higher power operation)
CONFIG MCLRE = ON       ; MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled)
; CONFIG4L
CONFIG LVP = OFF        ; Single-Supply ICSP Enable bit (Single-Supply ICSP disabled)
CONFIG XINST = OFF      ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))
CONFIG DEBUG = OFF      ; Disable In-Circuit Debugger

GLOBAL var11
GLOBAL var22

GLOBAL var1
GLOBAL var2
GLOBAL var3
GLOBAL result
GLOBAL counter
    
GLOBAL prevRE0
GLOBAL prevRE1
    
GLOBAL curRE0
GLOBAL curRE1

GLOBAL RE0Clicked
GLOBAL RE1Clicked
    
GLOBAL led1Cursor
GLOBAL led2Cursor
    
GLOBAL led1Open
GLOBAL led2Open  
    
GLOBAL varPORTB
GLOBAL varPORTC
GLOBAL varPORTD

GLOBAL signalingCursor // either 0 or 1

; Define space for the variables in RAM
PSECT udata_acs
var1:
    DS 1 ; Allocate 1 byte for var1
var2:
    DS 1 
var11:
    DS 1
var22:
    DS 1
var3:
    DS 1
counter:
    DS 1 
temp_result:
    DS 1   
result: 
    DS 1
prevRE0:
    DS 1
prevRE1:
    DS 1
curRE0:
    DS 1
curRE1:
    DS 1
RE0Clicked:
    DS 1
RE1Clicked:
    DS 1
led1Cursor:
    DS 1
led2Cursor:
    DS 1
led1Open:
    DS 1
led2Open:
    DS 1
signalingCursor:
    DS 1
varPORTB:
    DS 1
varPORTC:
    DS 1
varPORTD:
    DS 1


PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto       main

PSECT CODE
main:
    clrf var1	; var1 = 0	
    clrf var2
    clrf var3
    clrf result ; result = 0
    
    movlw 128
    movwf counter
    
    clrf prevRE0
    clrf prevRE1
    
    clrf curRE0
    clrf curRE1

    clrf RE0Clicked
    clrf RE1Clicked
    
    clrf led1Cursor
    clrf led2Cursor 
    
    clrf led1Open
    clrf led2Open
    
    clrf varPORTB
    clrf varPORTC
    clrf varPORTD
    
    ; PORTB
    ; LATB
    ; TRISB determines whether the port is input/output
    ; set output ports
    clrf TRISB
    clrf TRISC
    clrf TRISD
    setf TRISE ; PORTE is input
    
    movlw 00001111B
    movwf TRISA
    
    setf PORTB
    setf LATC ; light up all pins in PORTC
    setf LATD
    
    call busy_wait
    
    clrf PORTB
    clrf PORTC
    clrf PORTD
main_loop:
    ; Round robin
    clrf RE0Clicked
    clrf RE1Clicked
    
    movlw 198
    movwf var22 ; var2 = 128
    check_loop:
	setf var11 ; var1 = 255
	inner_start:
	    call check_buttons
	    decf var11
	    bnz inner_start
	incfsz var22
	bra check_loop
	   
    
    
    
    call update_display
    goto main_loop

busy_wait:
    ; for (var2 = 0; var 
    ; for (var1 = 255; var1 != 0; --var1)
    movlw 6
    movwf var3
    outerouter_loop:
	movlw 40
	movwf var2 ; var2 = 128
	outer_loop_start:
	    setf var1 ; var1 = 255
	    loop_start:
		decf var1
		bnz loop_start
	    incfsz var2
	    bra outer_loop_start
	decf var3
	bnz outerouter_loop    
    return

re0_iszero:
    tstfsz prevRE0
    setf RE0Clicked
    return
    
re1_iszero:
    movlw 0 
    tstfsz prevRE1
    setf RE1Clicked
    return
    
check_buttons:
    clrf curRE0
    clrf curRE1
    btfsc PORTE, 0; check RE0, skip if 0
    setf curRE0
    btfsc PORTE, 1
    setf curRE1

    movlw 0
    CPFSGT curRE0
    call re0_iszero
    
    movlw 0
    CPFSGT curRE1
    call re1_iszero
    
    movff curRE0, prevRE0
    movff curRE1, prevRE1
    return   
    
led1Toggle:
    comf led1Open
    clrf led1Cursor
    return
led2Toggle:
    comf led2Open
    clrf led2Cursor
    return
    

update_led1:
    rlncf varPORTB
    incf varPORTB
    bov job
   
    
    return
    job:
     clrf varPORTB
     
     
     return
     
    

    
update_led2:
    incf varPORTC
    rrncf varPORTC
    bov job2
    
    return
    job2:
     clrf varPORTC
    
     return
     
    
    
    
update_display:
    tstfsz RE0Clicked
    comf led2Open
    
    tstfsz RE1Clicked
    comf led1Open
    
    tstfsz led1Open
    call update_led1
    
    movlw 255
    CPFSEQ led1Open
    clrf varPORTB
    
    tstfsz led2Open
    call update_led2
    
    movlw 255
    CPFSEQ led2Open
    clrf varPORTC
    
    tstfsz varPORTD
    clrf PORTD
   
    movlw 1
    CPFSEQ varPORTD
    incf PORTD
    
    movff PORTD, varPORTD
    movff varPORTB, PORTB
    movff varPORTC, LATC

    return
    
    
    
    

    
    
    
    
end resetVec