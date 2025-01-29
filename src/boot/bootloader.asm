; The BIOS will load the first 512 bytes (this file) from the disk
; This program will load our compiled program into memory and begin executing it

org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

LOAD_SEG:    equ 0x2000
LOAD_OFFSET: equ 0

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

.load:
    mov ax, 1                         ; Start loading the next sector
    mov cl, 10                        ; Load an arbitrary 10 sectors - TODO: replace with a proper file system
    mov dl, [tfs_drive_number]        ; dl = tfs_drive_number
    mov bx, LOAD_SEG
    mov es, bx
    mov bx, LOAD_OFFSET               ; Output data at buffer label
    call disk_read

    jmp LOAD_SEG:LOAD_OFFSET

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

;
; Helper functions
;

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

;
; Converts LBA address to CHS address
; Args:
;     ax - LBA address
; Returns:
;     sector   -> cx (bits 0-5 from the right)
;     cylinder -> cx (bits 6-15)
;     head     -> dh
lba_to_chs:                           ; Logical Block Addressing -> Cylinder Head Sector
    push ax
    push dx

    xor dx, dx                        ; dx = 0
    div word [tfs_sectors]            ; ax = LBA / SectorsPerTrack
                                      ; dx = LBA % SectorsPerTrack
    inc dx                            ; dx = (LBA % SectorsPerTrack + 1) = sector
    mov cx, dx                        ; cx = sector

    xor dx, dx                        ; dx = 0
    div word [tfs_heads]              ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                                      ; dx = (LBA / SectorsPerTrack) % Heads = head
    mov dh, dl                        ; dh = head (dh = 8 high bits of dx, dl = low 8 bits of dx; high=left, low=right)
    mov ch, al                        ; ch = lower 8 bits of cylinder
    shl ah, 6                         ; shift into place
    or  cl, ah                        ; place upper two bits of cylinder into the top of cl
                                      ; CX =       ---CH--- ---CL---
                                      ; cylinder : 76543210 98
                                      ; sector   :            543210
    pop ax                            ; ax = dl (from stack)
    mov dl, al                        ; dl = ax
    pop ax                            ; ax = ax (from stack)
    ret

;
; Read sectors from a disk
; Args
;     ax    - LBA address
;     cl    - number of sectors to read (up to 128)
;     dl    - drive number
;     es:bx - memory location to store read data (destination)
disk_read:

    push ax                           ; Save original values of registers we'll modify
    push bx
    push cx
    push dx
    push di

    push cx                           ; Save original value of cx (since it will be overwritten)
    call lba_to_chs                   ; Takes in ax as the LBA address and returns CHS (cx, dh)
    pop ax                            ; AL = number of sectors to read (originally cl)

    mov ah, 02h                       ; Required for BIOS function/interrupt
    mov di, 3                         ; Retry read 3 times (for real hardware)

.retry:
    pusha                             ; This BIOS interrupt may mess with our registers, save them for later
    stc                               ; Set carry flag... to check for a successful read, the carry flag will be cleared
    int 13h                           ; Calls the BIOS read function given the args we previously supplied
    jnc .done                         ; Jump if carry clear, success!

    ; If read failed
    popa
    call disk_reset

    dec di                            ; di--
    test di, di                       ; Check if di == 0 (I think it performs a bitwise AND and sets the zero flag if the result is 0)
    jnz .retry                        ; If di != 0, loop

.fail:
    jmp floppy_fail                   ; Display error message on fail

.done:
    popa
    pop di                            ; Restore registers
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;
; Reset disk controller
; Args
;     dl - drive number
disk_reset:
    pusha
    mov ah, 0                         ; Causes the disk controller to reset
    stc
    int 13h
    jc floppy_fail                    ; Carry should be clear if reset was successful, otherwise jump to floppy_fail
    popa
    ret
    


; Try to keep messages short
msg_hello:       db 'Loading', ENDL, 0
msg_floppy_fail: db 'Disk err', ENDL, 0

times 510-($-$$) db 0                 ; Pad the program so that the signature begins 511 bytes into the sector
dw 0xAA55
