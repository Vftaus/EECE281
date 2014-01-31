$MODDE2
org 0000H
   ljmp MyProgram
org 002BH
	ljmp Timer2_ISR
	
$include(var.asm)

org 1337H

$include(math32.asm)
$include(Temp_lookup.asm)
$include(comms.asm)
$include(decision.asm)
$include(utilities.asm)

;-------------------------------------------------------------------;
;first reads from channel 0 of the adc (thermocouple temp)
;then reads from channel 1 of the adc (lm335)
;stores sum of reading 64 times to adc1 and adc0
READ_ADC:
	mov x+0, #0
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
	mov R2, #64
READ_ADC_LOOP:
	lcall D0_SPI
	mov y+0, R4
	mov y+1, R5
	mov y+2, R6
	mov y+3, R7
	lcall add32
	djnz R2, #0, READ_ADC_LOOOP
STORE_ADC:
	mov x+0, adc0+0
	mov x+1, adc0+1
	mov x+2, adc1+0
	mov x+3, adc1+1	
	ret
	
DO_SPI:	
DO_SPI0:
	orl P0MOD, #0001110b ; CE, SCLK, MOSI as outputs
	anl P0MOD, #1111110b ; MISO as input
	clr SCLK ; mode 0,0 default
	clr CE_ADC ; CS is low start
	mov R4, #0
	mov R5, #0
	mov R1, #17 ; counter
	mov R0, #0C0H
DO_SPI_LOOP0:
	mov a, R0
	rlc a
	mov R0, a
	mov MOSI, c
	setb SCLK
	mov c, MISO
	mov a, R4
	rlc a
	mov R4, a
	mov a, R5
	rlc a
	mov R5, a
	clr SCLK
	djnz R1, DO_SPI_LOOP0
	setb CE_ADC
	mov a, R5
	anl a, #03H
	mov R5, a

	lcall SPIDelay
	
DO_SPI1:
	orl P0MOD, #0001110b ; CE, SCLK, MOSI as outputs
	anl P0MOD, #1111110b ; MISO as input
	clr SCLK ; mode 0,0 default
	clr CE_ADC ; CS is low start
	mov R6, #0
	mov R7, #0
	mov R1, #17 ; counter
	mov R0, #0C8H
DO_SPI_LOOP1:
	mov a, R0
	rlc a
	mov R0, a
	mov MOSI, c
	setb SCLK
	mov c, MISO
	mov a, R6
	rlc a
	mov R6, a
	mov a, R7
	rlc a
	mov R7, a
	clr SCLK
	djnz R1, DO_SPI_LOOP1
	setb CE_ADC
	mov a, R7
	anl a, #03H
	mov R7, a
SPI_done:
	ret

;---------------------------------------------;    

;converting values in adc0 and 1 to tempo and tempa
;in the form first byte number second byte decimal

;------------------------------------------------;

DO_MATH:
MATH_TO:
	mov x+0, adc1+0
	mov x+1, adc1+1
	mov x+2, #0
	mov x+3, #0
	load_y(500) ; idk what this is
	lcall mul32
	mov x+0, x+1
	mov x+1, x+2
	mov x+2, x+3
	mov x+3, #0
	Load_y(69926) ; this seems cool
	lcall sub32
	mov tempo+0, x+0
	mov tempo+1, x+1
	
MATH_TA:
	mov x+0, adc0+0
	mov x+1, adc0+1
	mov x+2, #0
	mov x+3, #0
	load_y(4654) ;the ratio of adc reading to temp
	lcall mul32
	lcall hex2bcd
	; now the temperature reading is in bcd
	; only care about bcd+4, bcd+3 and bcd+2
	mov wtfbbq+0, bcd+2
	mov wtfbbq+1, bcd+3
	mov wtfbbq+2, bcd+4
	;last bcd byte contains decimal part
	mov bcd+0, wtfbbq+0
	mov bcd+1, #0
	mov bcd+2, #0
	mov bcd+3, #0
	mov bcd+4, #0
	lcall bcd2hex
	mov tempa+0, x+0
	mov bcd+0, wtfbbq+1
	mov bcd+1, wtfbbq+2
	mov bcd+2, #0
	mov bcd+3, #0
	mov bcd+4, #0
	lcall bcd2hex
	mov tempa+1, x+0
	mov tempa+2, x+1
	
MATH_DONE:
	ret
	
;-----------------------------------------------;
	
MyProgram:
	LCALL InitDE2
    LCALL InitSerialPort
	LCALL Init_timer2
	LCALL READ_ADC
	LCALL DO_MATH
	
Forever:
	lcall decision
	lcall CommsMain
	lcall CommsCmd
    SJMP Forever
    
END
