; The BIOS will load the first 512 bytes (this file) from the disk
; This program will load our compiled program into memory and begin executing it

org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

start:                                ; Boilerplate code
    ; Setup data segments
    mov ax, 0
    mov ds, ax                        ; We cannot move immediate values into ds/es
    mov es, ax

    ; Setup stack
    mov ss, ax
    mov sp, 0x7C00                    ; Stack grows downward from 0x7C00 so it will not overwrite our program

    ; Some BIOSes start at 07C0:0000 instead of 0000:7C00
    ; This trick ensures we are in the right location
    push es
    push word .after
    retf
.after:
    mov si, msg_hello
    call puts

    cli
    hlt
.halt:
    jmp .halt


; Prints a string to the screen
; Args:
;     ds:si - points to a string
puts:
    ; Save current register states (so when we return they are popped back to their original value)
    push si
    push ax

.loop:
    lodsb              ; Loads a byte from ds:si into al (8-bit ax) and increments si
    or al, al          ; Sets zero processor flag if '\0' is found
    jz .done

    mov ah, 0x0E       ; Print character in BIOS TTY mode
    mov bh, 0          ; Set page number to 0
    int 0x10           ; Video interrupt

    jmp .loop

.done:
    pop ax
    pop si
    ret


msg_hello: db 'Hello World!', ENDL, 0

times 510-($-$$) db 0 ; Pad the program so that the signature begins 511 bytes into the sector
dw 0xAA55

buffer: