#include P16F84A.INC

__CONFIG(_RC_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF);

    org 0

; SFRs
status  equ 3
portb   equ 6
trisb   equ 6

; init
    bsf     status, 5       ; memory bank 1
    clrw
    movwf   trisb
    bcf     status, 5       ; memory bank 0

; main
    movlw   0xff
    movwf   portb
loop
    goto    loop

    end