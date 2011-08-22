	include P16F84A.INC
	__CONFIG(_RC_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF);

; constants
LBTN	equ	RA3
RBTN	equ	RA4
LSCORE	equ	RA1
RSCORE	equ	RA0
ERR	equ	RA2

STOREINW	equ	0
STOREINF	equ	1

STATE_BEGIN	equ	0
STATE_BLAST	equ	1
DIR_RIGHT	equ	0
DIR_LEFT	equ	1

PLAYDLY		equ	0x10

; ram
STATE		equ	0x10
DIRECTION	equ	0x11
DELAY_CNT_OUTER	equ	0x12
DELAY_CNT_INNER	equ	0x13
BLAST_CNT	equ	0x14

	org	0

; setup for "electronic ping-pong board"
; PORTB[7-0]: output green LEDs
; PORTA[4-3]: input right/left buttons
;      [2]:   output red error LED
;      [1-0]: output LED "score"
init
	bsf	STATUS, RP0
	clrw
	movwf	TRISB
	movlw	b'00011000'
	movwf	TRISA
	bcf	STATUS, RP0
	clrw
	movwf	PORTA
	movwf	PORTB

	; set initial state: begin
	movlw	STATE_BEGIN
	movwf	STATE

	; set initial direction: left -> right
	movlw	DIR_LEFT
	movwf	DIRECTION

main
	; check state
	movfw	STATE
	sublw	STATE_BEGIN
	btfsc	STATUS, Z
	call	state_begin

	movfw	STATE
	sublw	STATE_BLAST
	btfsc	STATUS, Z
	call	state_blast

	goto	main

state_begin
	movlw	0x8
	movwf	BLAST_CNT

	; check direction
	movfw	DIRECTION
	sublw	DIR_RIGHT
	btfsc	STATUS, Z
	call	right_direction

	movfw	DIRECTION
	sublw	DIR_LEFT
	btfsc	STATUS, Z
	call	left_direction

	return

state_blast
	; check direction
	movfw	DIRECTION
	sublw	DIR_RIGHT
	btfsc	STATUS, Z
	call	update_right

	movfw	DIRECTION
	sublw	DIR_LEFT
	btfsc	STATUS, Z
	call	update_left

	decf	BLAST_CNT, STOREINF
	btfsc	STATUS, Z
	call	chg_dir_and_start_over

	return

update_left
	bcf	STATUS, C
	rrf	PORTB, STOREINF
	movlw	PLAYDLY
	call	delay
	return

update_right
	bcf	STATUS, C
	rlf	PORTB, STOREINF
	movlw	PLAYDLY
	call	delay
	return

chg_dir_and_start_over
	movlw	STATE_BEGIN
	movwf	STATE

	movfw	DIRECTION
	sublw	DIR_RIGHT
	btfsc	STATUS, Z
	goto	set_direction_left

	movfw	DIRECTION
	sublw	DIR_LEFT
	btfsc	STATUS, Z
	goto	set_direction_right

	return

set_direction_left
	movlw	DIR_LEFT
	movwf	DIRECTION
	return

set_direction_right
	movlw	DIR_RIGHT
	movwf	DIRECTION
	return

left_direction
	; turn on left-most play LED
	movlw	b'10000000'
	movwf	PORTB

	; wait for button press
	btfss	PORTA, LBTN
	call	left_blast
	btfss	PORTA, RBTN
	call	error_press

	return

right_direction
	; turn on right-most play LED
	movlw	b'00000001'
	movwf	PORTB

	; check for button press
	btfss	PORTA, LBTN
	call	error_press
	btfss	PORTA, RBTN
	call	right_blast

	return

left_blast
right_blast
	movlw	STATE_BLAST
	movwf	STATE
	return

error_press
	; turn off all play LEDS
	clrw
	movwf	PORTB
	movwf	PORTA
	call	flash_err
	return

flash_err
	bsf	PORTA, ERR
	movlw	0x40
	call	delay
	bcf	PORTA, ERR
	movlw	0x40
	call	delay

	bsf	PORTA, ERR
	movlw	0x40
	call	delay
	bcf	PORTA, ERR
	movlw	0x40
	call	delay

	bsf	PORTA, ERR
	movlw	0x40
	call	delay
	bcf	PORTA, ERR
	movlw	0x40
	call	delay

	return

; delay by the value passed in W
delay
	movwf	DELAY_CNT_OUTER
delay_outer
	movlw	0xff
	movwf	DELAY_CNT_INNER
delay_inner
	decfsz	DELAY_CNT_INNER, STOREINF
	goto	delay_inner
	decfsz	DELAY_CNT_OUTER, STOREINF
	goto	delay_outer

	return

	end