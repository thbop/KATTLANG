; The BIOS will load the first 512 bytes (this file) from the disk
; This program will load our compiled program into memory and begin executing it

org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A


jmp short start                       ; Thbop File System stuff (nothing really tbh)
tfs_drive_number: db 0                ; Drive number
tfs_cylinders:    dw 0                ; For converting from and to CHS
tfs_heads:        db 0
tfs_sectors:      db 0

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
    mov [tfs_drive_number], dl        ; Store the drive number


    mov si, msg_hello
    call puts

    ; Get drive parameters
    push es                           ; Save es
    mov ah, 08h                       ; Get driver parameters
    int 13h                           ; Run BIOS function
    jc floppy_fail                    ; If the carry is set, something went wrong
    pop es                            ; Restore es

    ; Store parameters
    mov al, ch                        ; al = low 8 bits of cylinders
    mov ah, cl                        ; ah = CCSSSSSSb
    shr ah, 6                         ; ax = cylinders
    mov [tfs_cylinders], ax           ; tfs_cylinders = ax

    mov [tfs_heads], dh               ; tfs_heads = heads

    and cl, 00111111b                 ; cl = sectors
    mov [tfs_sectors], cl             ; tfs_sectors = cl


    
    jmp wait_key_and_reboot

    cli
    hlt


;
; Errors
;
floppy_fail:
    mov si, msg_floppy_fail
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                           ; Wait for a keypress
    jmp 0FFFFh:0                      ; Beginning of the BIOS, should reboot computer

.halt:
    cli                               ; Disable interrupts to prevent exiting the "halt" state
    jmp .halt

; Prints a string to the screen
; Args:
;     ds:si - points to a string
puts:
    ; Save current register states (so when we return they are popped back to their original value)
    push si
    push ax

.loop:
    lodsb                             ; Loads a byte from ds:si into al (8-bit ax) and increments si
    or al, al                         ; Sets zero processor flag if '\0' is found
    jz .done

    mov ah, 0x0E                      ; Print character in BIOS TTY mode
    mov bh, 0                         ; Set page number to 0
    int 0x10                          ; Video interrupt

    jmp .loop

.done:
    pop ax
    pop si
    ret


; Try to keep messages short
msg_hello:       db 'Loading', ENDL, 0
msg_floppy_fail: db 'Disk err', ENDL, 0

times 510-($-$$) db 0                 ; Pad the program so that the signature begins 511 bytes into the sector
dw 0xAA55

buffer: