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
ENDZONE		equ	0x3

; ram
STATE		equ	0x10
DIRECTION	equ	0x11
DELAY_CNT_OUTER	equ	0x12
DELAY_CNT_INNER	equ	0x13
BLAST_CNT	equ	0x14
BALLSAVE	equ	0x15

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

	; set initial direction: left
	movlw	DIR_LEFT
	movwf	DIRECTION

	; clear "save"
	clrw
	movwf	BALLSAVE

main
	; reset score
	bcf	PORTA, LSCORE
	bcf	PORTA, RSCORE
	; check state
	movfw	STATE
	sublw	STATE_BEGIN
	btfsc	STATUS, Z
	call	state_begin
	movfw	STATE
	sublw	STATE_BLAST
	btfsc	STATUS, Z
	call	state_blast
	; loop forever
	goto	main

state_begin
	; set count
	movlw	0x7
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
	btfss	STATUS, Z
	goto	state_blast_check_dir_left
	call	update_right
	goto	state_blast_dec
state_blast_check_dir_left
	movfw	DIRECTION
	sublw	DIR_LEFT
	btfsc	STATUS, Z
	call	update_left
state_blast_dec
	decf	BLAST_CNT, STOREINF
	btfsc	STATUS, Z
	goto	check_for_save
	return
check_for_save
	movfw	BALLSAVE
	sublw	1
	btfss	STATUS, Z
	call	score
	call	chg_dir_and_start_over
	return

update_left
	bcf	STATUS, C
	rrf	PORTB, STOREINF
	; check for button press
	btfss	PORTA, RBTN
	goto	update_left_btn_right
	goto	update_left_done
update_left_btn_right
	movlw	ENDZONE
	subwf	BLAST_CNT, STOREINW
	btfsc	STATUS, C
	goto	update_left_early
	goto	update_left_save
update_left_early
	; "catch" too early
	bsf	PORTA, LSCORE
	call	flash_err
	call	chg_dir_and_start_over
	return
update_left_save
	movlw	1
	movwf	BALLSAVE
update_left_done
	movlw	PLAYDLY
	call	delay
	return

update_right
	bcf	STATUS, C
	rlf	PORTB, STOREINF
	; check for button press
	btfss	PORTA, LBTN
	goto	update_right_btn_left
	goto	update_right_done
update_right_btn_left
	movlw	ENDZONE
	subwf	BLAST_CNT, STOREINW
	btfsc	STATUS, C
	goto	update_right_early
	goto	update_right_save
update_right_early
	; catch too early
	bsf	PORTA, RSCORE
	call	flash_err
	call	chg_dir_and_start_over
	return
update_right_save
	movlw	1
	movwf	BALLSAVE
update_right_done
	movlw	PLAYDLY
	call	delay
	return

chg_dir_and_start_over
	; reset "save"
	clrw
	movwf	BALLSAVE
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
	call	blink_left
	return
set_direction_right
	movlw	DIR_RIGHT
	movwf	DIRECTION
	call	blink_right
	return

left_direction
	; turn on left-most play LED
	movlw	b'10000000'
	movwf	PORTB
	; check for button press
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

score
	clrf	PORTB
	; check direction
	movfw	DIRECTION
	sublw	DIR_RIGHT
	btfsc	STATUS, Z
	call	score_right
	movfw	DIRECTION
	sublw	DIR_LEFT
	btfsc	STATUS, Z
	call	score_left
	return

score_left
	bsf	PORTA, LSCORE
	movlw	0x60
	call	delay
	bcf	PORTA, LSCORE
	movlw	0x30
	call	delay
	bsf	PORTA, LSCORE
	movlw	0x60
	call	delay
	bcf	PORTA, LSCORE
	movlw	0x30
	call	delay
	bsf	PORTA, LSCORE
	movlw	0x60
	call	delay
	bcf	PORTA, LSCORE
	movlw	0x30
	call	delay
	bsf	PORTA, LSCORE
	movlw	0x60
	call	delay
	bcf	PORTA, LSCORE
	movlw	0x30
	call	delay
	return

score_right
	bsf	PORTA, RSCORE
	movlw	0x60
	call	delay
	bcf	PORTA, RSCORE
	movlw	0x30
	call	delay
	bsf	PORTA, RSCORE
	movlw	0x60
	call	delay
	bcf	PORTA, RSCORE
	movlw	0x30
	call	delay
	bsf	PORTA, RSCORE
	movlw	0x60
	call	delay
	bcf	PORTA, RSCORE
	movlw	0x30
	call	delay
	bsf	PORTA, RSCORE
	movlw	0x60
	call	delay
	bcf	PORTA, RSCORE
	movlw	0x30
	call	delay
	return

blink_left
	clrw
	movwf	PORTB
	bsf	PORTB, RB7
	movlw	0x18
	call	delay
	bcf	PORTB, RB7
	movlw	0x18
	call	delay
	bsf	PORTB, RB7
	movlw	0x18
	call	delay
	bcf	PORTB, RB7
	movlw	0x18
	call	delay
	bsf	PORTB, RB7
	movlw	0x18
	call	delay
	bcf	PORTB, RB7
	movlw	0x18
	call	delay
	return

blink_right
	clrw
	movwf	PORTB
	bsf	PORTB, RB0
	movlw	0x18
	call	delay
	bcf	PORTB, RB0
	movlw	0x18
	call	delay
	bsf	PORTB, RB0
	movlw	0x18
	call	delay
	bcf	PORTB, RB0
	movlw	0x18
	call	delay
	bsf	PORTB, RB0
	movlw	0x18
	call	delay
	bcf	PORTB, RB0
	movlw	0x18
	call	delay
	return

error_press
	; turn off all play LEDS
	clrw
	movwf	PORTB
	movwf	PORTA

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