include P16F84A.INC
__CONFIG(_RC_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF);

; ram
delaycnt1	equ	0x10
delaycnt2	equ	0x11

	org	0

; setup ports A and B for output
	clrw
	bsf	STATUS, RP0
	movwf	TRISA
	movwf	TRISB
	bcf	STATUS, RP0

main
; turn LED on
	movlw	0x55
	movwf	PORTB
	call	delay
; turn LED off
	movlw	0xaa
	movwf	PORTB
	call delay

	goto main

delay
; delay a bit
	movlw	0x40
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