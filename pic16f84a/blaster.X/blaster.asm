	include P16F84A.INC
	__CONFIG(_RC_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF);

; ram
delaycnt1	equ	0x10
delaycnt2	equ	0x11

	org	0

; setup B[0-7] for output
	bsf	STATUS, RP0
	clrw
	movwf	TRISB
; setup A[3-4] for input
	movlw	b'00011000'
	movwf	TRISA
	bcf	STATUS, RP0
; clear leds
	clrw
	movwf	PORTB
	movwf	PORTA

main
; wait for left button press
	btfss	PORTA, RA3
	call	blastfromleft
	goto	main

blastfromleft
	movlw	0x80
	movwf	PORTB
	call	delay

	movlw	0xc0
	movwf	PORTB
	call	delay

	movlw	0xe0
	movwf	PORTB
	call	delay

	movlw	0x70
	movwf	PORTB
	call	delay

	movlw	0x38
	movwf	PORTB
	call	delay

	movlw	0x1c
	movwf	PORTB
	call	delay

	movlw	0x0e
	movwf	PORTB
	call	delay

	movlw	0x07
	movwf	PORTB
	call	delay

	movlw	0x03
	movwf	PORTB
	call	delay

	movlw	0x01
	movwf	PORTB
	call	delay

	movlw	0
	movwf	PORTB
	call	delay

	return
delay
; delay a bit
	movlw	0x10
	movwf	delaycnt2
outer
	movlw	0xff
	movwf	delaycnt1
inner
	nop
	nop
	decfsz	delaycnt1, 1
	goto	inner
	decfsz	delaycnt2, 1
	goto	outer
	return

	end