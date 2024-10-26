

DEF TARGET_MEGADUCK EQU 1
include "../inc/hardware.inc"

include "../inc/megaduck_laptop_io.inc"

SECTION "Duck Laptop IO WRAM", WRAMX[$D100]
duck_io_rx_byte_done:: db
duck_io_rx_byte:: db

duck_io_rx_buf_len:: db
duck_io_rx_buf:: ds DUCK_IO_LEN_RX_MAX
duck_io_tx_buf_len:: db
duck_io_tx_buf:: ds DUCK_IO_LEN_TX_MAX


SECTION "Duck Laptop SIO ISR", ROM0[$0058]

; DUCK: TODO: Should be placed at 0x58 SIO interrupt handler, but there is something there, maybe just poll instead?
; ISR_VECTOR(VECTOR_SERIAL, duck_io_sio_isr)
; Serial link handler for receiving data send by the MegaDuck laptop peripheral
duck_io_sio_isr::
    push af
    ; Save received data and update status flag
    ld   a, [rSB]
    ld   [duck_io_rx_byte], a
    ld   a, DUCK_IO_OK
    ld   [duck_io_rx_byte_done], a

    ; Turn Serial ISR back off
    ; set_interrupts(IE_REG & ~SIO_IFLAG);
    ld   a, [rIE]
    res  IEF_B_SERIAL, a
    ldh  [rIE], a

    pop af
    reti

SECTION "Duck Laptop IO", ROM0

; ===== Low level helper IO functions =====


; Delay is set similar to System ROM delay, which is 1.015 msec (4256 T-States).
; Probably so there is enough time to transmit one byte along with a bit of overhead.
;
; This is 4252 T-States (1.0137 msec) and seems to work. Values somewhat lower did not work reliably.
;
; Calc: (1000 msec / 59.7275 GB FPS) * (4252 T-States delay / 70224 T-States per frame) = 1.0137 msec
;
; Serial clock speed used is: 8192 Hz  1 KB/s = 1 msec per 1 byte
duck_delay_1_ish_msec::
    push af
    ld a, 211  ; value determined by calc/measurement
    .delay_loop
        nop
        dec  a
        jr   nz, .delay_loop
    pop  af
    ret



; Send a byte over serial to the MegaDuck laptop peripheral
;
; Param: Byte to send: A
duck_io_send_byte::
    push af
    ; Load param serial byte to send in A
    ldh  [rSB], a
    ; Enable transfer (using internal clock)
    ld   a, SERIAL_XFER_ENABLE | SERIAL_CLOCK_INT
    ldh  [rSC], a

    ; TODO: the delay here seems inefficient, but need to find out actual timing on the wire first
    call duck_delay_1_ish_msec

    ; Clear pending interrupts
    xor  a
    ldh  [rIF], a ; DUCK: TODO: Is clearing IF ok for other running workboy code?

    ; Return serial to ready to receive byte
    ld   a, SERIAL_XFER_ENABLE | SERIAL_CLOCK_EXT
    ldh  [rSC], a

    pop af
    ret



; Prepares to receive serial data from the MegaDuck laptop peripheral
;
; -  Sets serial IO to external clock and enables ready state.
; -  Turns on Serial interrupt, clears any pending interrupts and
;    then turns interrupts on (state of @ref IE_REG should be
;    preserved before calling this and then restored at the end of
;    the serial communication being performed).
duck_io_enable_read_byte::
    push af

    ; Set serial as ready to receive byte
    ld   a, SERIAL_XFER_ENABLE | SERIAL_CLOCK_EXT
    ldh  [rSC], a

    ; Turn on serial interrupt
    ld   a, [rIE]
    set  IEF_B_SERIAL, a
    ldh  [rIE], a

    ; clear pending interrupts and then enable them
    xor  a
    ldh  [rIF], a ; DUCK: TODO: Is clearing IF ok for other running workboy code?
    ei

    pop af
    ret



 ; Reads a byte over serial from the MegaDuck laptop peripheral with NO timeout
 ; If there is no reply then it will hang forever
 ;
 ; Returns: received byte in: A
 ;
 ; Regs: Does not preserve: F
duck_io_read_byte_no_timeout::
    di
    ld   a, DUCK_IO_FAIL
    ld   [duck_io_rx_byte_done], a
    ei

    call duck_io_enable_read_byte
    ; Wait (forever) for a reply byte
    .wait_io_rx
        ld   a, [duck_io_rx_byte_done]
        cp   a, DUCK_IO_OK
        jr   nz, .wait_io_rx

    ; Return received value in A
    ld   a, [duck_io_rx_byte]
    ret



; Waits to receive a byte over serial from the MegaDuck laptop peripheral with a timeout
;
; Param: timeout_len_ms in : A  (Unit size is in ~1.19 msec + some overhead)
;
; Returns: Status in A
; - DUCK_IO_OK:   Success, received byte will be in [duck_io_rx_byte] global
; - DUCK_IO_FAIL: Read timed out with no reply
duck_io_read_byte_with_msecs_timeout::

    push bc
    ld   c, a  ; timeout length in msecs in C

    ; Critical section around var that may be modified by ISR
    DI
    ld   a, DUCK_IO_FAIL
    ld   [duck_io_rx_byte_done], a
    EI

    call duck_io_enable_read_byte

    .wait_timeout_len_msecs
        ; Each run of the inner loop is 89 is ~ 1.19msec (88 is ~1.08 msec)
        ; Delay is slightly over 1msec as time to transmit one byte along with a bit of overhead.
        ld   b, 89
        .wait_io_rx_1_msec
            ld   a, [duck_io_rx_byte_done]
            cp   a, DUCK_IO_OK
            jr   z, .io_rx_success

            dec  b
            jr   nz, .wait_io_rx_1_msec

        ; Decrement number of msecs elapsed
        dec  c
        jr   nz, .wait_timeout_len_msecs

    .io_rx_fail
    ; A should have DUCK_IO_FAIL here

    .io_rx_success
    ; A should have DUCK_IO_OK here

    ; Return status in A, received value in [duck_io_rx_byte] if success
    pop  bc
    ret



; ===== Higher level IO functions =====

; Sends a byte over over serial to the MegaDuck laptop peripheral
; and waits for a reply with a timeout
;
; Params: tx_byte in:        A  (Byte to send)
;         timeout_len_ms in: B  (Unit size is in msec (100 is about ~ 103 msec or 6.14 frames)
;         expected_reply in: C  (The expected value of the reply byte)
;
; Returns: Status in:  A
; - DUCK_IO_OK:   Success
; - DUCK_IO_FAIL: Timed out or reply byte didn't match expected value
duck_io_send_byte_and_check_ack_msecs_timeout::

    call duck_io_send_byte  ; Send param byte in A

    ; Reply byte should be incoming, fail if no reply
    ; Timeout duration param in B
    ld   a, b
    call duck_io_read_byte_with_msecs_timeout
    cp   a, DUCK_IO_OK
    jr   nz, .return_failure  ; Fail if read timed out

    ; Then check reply byte vs expected reply param in C
    ld   a, [duck_io_rx_byte]
    cp   a, c
    jr   nz, .return_failure

    ; Success
    .return_success
    ld   a, DUCK_IO_OK
    ret

    .return_failure
        ld   a, DUCK_IO_FAIL
        ret



; Sends a command and a multi-byte buffer over serial to the MegaDuck laptop peripheral
;
; Param: io_cmd in:  A (Command byte to send)
;
; The data should be pre-loaded into these globals:
; - duck_io_tx_buf:     Buffer with data to send
; - duck_io_tx_buf_len: Number of bytes to send
;
; Returns: Status in:  A
; - DUCK_IO_OK:   Success
; - DUCK_IO_FAIL: Timed out or reply byte didn't match expected value
;
; Regs: Does not preserve F
duck_io_send_cmd_and_buffer::
    push bc
    push de
    push hl

    ld   b, a ; Temp save param io_cmd from A

    ; Save interrupt enables and then set only Serial to ON
    ld   a, [rIE]
    push af

    ld   a, IEF_SERIAL
    ldh  [rIE], a

    ; Send command to initiate buffer transfer, then check for reply
    ld   a, b   ; Restore param io_cmd to A
    ld   b, DUCK_IO_TIMEOUT_200_MSEC
    ld   c, DUCK_IO_REPLY_SEND_BUFFER_OK
    call duck_io_send_byte_and_check_ack_msecs_timeout
    cp   a, DUCK_IO_OK
    jr   nz, .return_failure

    ; Send Packet Length and Init Checksum
    call duck_delay_1_ish_msec
    ld   a, [duck_io_tx_buf_len]  ; Packet Length = buffer length + 2 (for length header and checksum bytes)
    add  a, 2
    ld   e, a  ; Init Checksum with Packet Length, save in E
               ; BC params Timeout and Expected Reply are same as above and expected to be preserved
    call duck_io_send_byte_and_check_ack_msecs_timeout
    cp   a, DUCK_IO_OK
    jr   nz, .return_failure

    ; Send the buffer contents
    ld   a, [duck_io_tx_buf_len]  ; Note: buffer loop length is NOT +2 as Packet Length is
    ld   d, a                     ; Loop counter in D
    ld   hl, duck_io_tx_buf       ; Load pointer to tx buffer base and send the bytes
    .send_buffer_loop
        ; Update checksum with next byte
        ld    a, e  ; Checksum Calc in E
        add   a, [hl]
        ld    e, a

        ; Send a byte
        ldi  a, [hl]  ; Load TX buffer payload byte N
                      ; BC params Timeout and Expected Reply are same as above and expected to be preserved
        call duck_io_send_byte_and_check_ack_msecs_timeout
        cp   a, DUCK_IO_OK
        jr   nz, .return_failure

        dec   d
        jr    nz, .send_buffer_loop

    ; Done sending buffer bytes, last byte to send is checksum
    ; Tx Checksum Byte should == (((sum of all bytes except checksum) XOR 0xFF) + 1) [two's complement]
    ; checksum_calc = ~checksum_calc + 1u (2's complement)
    ld   a, e
    cpl
    inc  a     ; Final Checksum value
               ; B param Timeout assumed to be preserved from above, same value used
               ; Note different expected reply value versus previous reply checks (C)
    ld   c, DUCK_IO_REPLY_BUFFER_XFER_OK
    call duck_io_send_byte_and_check_ack_msecs_timeout
    cp   a, DUCK_IO_OK
    jr   nz, .return_failure

    ; Success
    ld   b, DUCK_IO_OK  ; Return Success (A should contain DUCK_IO_OK here..)

    .status_in_B__restore_ie_and_return
        pop  af
        ldh  [rIE], a
        ld   a, b  ; B has return status
        pop  hl
        pop  de
        pop  bc
        ret

    .return_failure
        ld   b, DUCK_IO_FAIL
        jr   .status_in_B__restore_ie_and_return



; Sends a command and then receives a multi-byte buffer over serial
; from the MegaDuck laptop peripheral
;
; Param: io_cmd in:  A (Command byte to send)
;
; If successful, the received data and length will be in these globals:
; - duck_io_rx_buf:     Buffer with received data
; - duck_io_rx_buf_len: Number of bytes received
;
; Returns: Status in:  A
; - DUCK_IO_OK:   Success
; - DUCK_IO_FAIL: Failed (could be no reply, failed checksum, etc)
;
; Regs: Does not preserve F
duck_io_send_cmd_and_receive_buffer::

    push de
    push hl

    ld   d, a  ; Save io_cmd param

    ; Save interrupt enables and then set only Serial to ON
    ld   a, [rIE]
    push af

    ld   a, IEF_SERIAL
    ldh  [rIE], a

    ; Another mystery, ignore it for now. Hasn't seemed needed so far.
    ; Maybe waiting for any potentially command in progress to finish on peripheral side??
    ;  delay_1_msec()
    ld   a, d  ; Restore and send param io_cmd
    call duck_io_send_byte

    ; Fail if first rx byte timed out
    ld   a, DUCK_IO_TIMEOUT_100_MSEC
    call duck_io_read_byte_with_msecs_timeout
    cp   a, DUCK_IO_OK
    jr   nz, .return_failure

        ; First rx byte will be length of all incoming bytes (enforce max length)
        ld   a, [duck_io_rx_byte]
        cp   a, (DUCK_IO_LEN_RX_MAX + 1)
        jr   nc, .return_failure

        ; Save rx byte as length header byte and use to initialize checksum
        ld   e, a  ; Init Checksum Calc in E

        dec  a     ; Reduce length by 1 since length includes this received byte itself
        ld   d, a  ; Use that as packet rx loop counter in D

        dec  a     ; Reduce by -1 again (will strip checksum byte) and save that as rx buffer size
        ld   [duck_io_rx_buf_len], a

        ; Load pointer to rx buffer base and store bytes into it as they arrive
        ld   hl, duck_io_rx_buf
        .receive_buffer_loop
            ; Wait for next rx byte
            ld   a, DUCK_IO_TIMEOUT_100_MSEC
            call duck_io_read_byte_with_msecs_timeout
            cp   a, DUCK_IO_OK
            jr   nz, .return_failure

            ; Save rx byte to buffer and add to checksum
            ld   a, [duck_io_rx_byte]
            ldi  [hl], a  ; Save reply byte to RX Buffer
            add  a, e     ; Update Checksum in E
            ld   e, a

            dec  d
            jr   nz, .receive_buffer_loop

    ; Done receiving buffer bytes, last rx byte should be checksum
    ; Rx Checksum Byte should == (((sum of all bytes except checksum) XOR 0xFF) + 1) [two's complement]
    ; so ((sum of received bytes including checksum byte) with unsigned 8 bit overflow means it should == 0x00
    ld   a, e
    or   a
    jr   nz, .return_failure

    ; Success
    ld   a, DUCK_IO_CMD_DONE_OR_OK ; Command reply status
    ld   d, DUCK_IO_OK             ; Return Success

    .reply_cmd_in_A__status_in_D__restore_ie_and_return
        ; Send command reply status in A
        call duck_io_send_byte
        ; Restore interrupt settings
        pop  af
        ldh  [rIE], a
        ; D has Return Status
        ld   a, d
        pop hl
        pop de
        ret

    .return_failure
        ; Reset rx buffer length to zero, no bytes received
        xor  a
        ld   [duck_io_rx_buf_len], a
        ; Something went wrong, error out
        ld   a, DUCK_IO_CMD_ABORT_OR_FAIL
        ld   d, DUCK_IO_FAIL
        jr   .reply_cmd_in_A__status_in_D__restore_ie_and_return



; Performs init sequence over serial with the MegaDuck laptop peripheral
;
; Needs to be done *just once* any time system is powered
; on or a cartridge is booted.
;
; Sends count up sequence + some commands, then waits for
; a matching count down sequence in reverse.
;
; Returns: Status in:  A (DUCK_IO_OK or DUCK_IO_FAIL)
;
; Regs: Does not preserve F
duck_io_controller_init::

    push bc

    ; IE_REG = SIO_IFLAG;
    ld   a, IEF_SERIAL
    ldh  [rIE], a

    ; Send a count up sequence through the serial IO (0,1,2,3...255)
    ; Exit on 8 bit unsigned wraparound to 0x00
    xor   a
    .send_count_up_loop
        call duck_io_send_byte
        inc  a
        jr   nz, .send_count_up_loop

    ; Then wait for a response
    ; Fail if reply back timed out or was not expected response
    ld   a, DUCK_IO_TIMEOUT_2_MSEC
    call duck_io_read_byte_with_msecs_timeout
    cp   a, DUCK_IO_OK
    jr   nz, .return_failure_1

    ld   a, [duck_io_rx_byte]
    cp   a, DUCK_IO_REPLY_BOOT_OK
    jr   nz, .return_failure_2

    ; Send a command that seems to request a reciprocal countdown sequence from the external controller
    ld   a, DUCK_IO_CMD_INIT_START
    call duck_io_send_byte

    ; Expects a reply sequence through serial IO of (255,254,253...0)
    ld   b, 255

        .receive_count_down_loop
            ; Fail if reply back timed out or did not match expected counter
            ; TODO: OEM approach doesn't break out once a failure occurs,
            ;       but maybe that's possible + sending the abort command early? (we'll find out!)
            ld   a, DUCK_IO_TIMEOUT_2_MSEC
            call duck_io_read_byte_with_msecs_timeout
            cp   a, DUCK_IO_OK
            jr   nz, .return_failure_3

            ; Check to ensure reply byte matches counter. Mismatch is failure
            ld   a, [duck_io_rx_byte]
            cp   a, b
            jr   nz, .return_failure_4

            ; decrement loop/expected reply byte counter
            ; Exit on 8 bit unsigned wraparound to 0xFFu
            dec  b
            ld   a, b
            cp   a, 255
            jr   nz, .receive_count_down_loop

    ; Return Success
    ld   a, DUCK_IO_CMD_DONE_OR_OK  ; Command reply status
    ld   b, DUCK_IO_OK              ; Return Success

    .reply_cmd_in_A__status_in_B__return
        ; Send command reply status in A
        call duck_io_send_byte
        ; B has return status
        ld   a, b
        pop  bc
        ret

    .return_failure
            ; ====== DEBUG
            ld   hl, (_TILEMAP0 + (32 * 8))
            call wait_until_vram_accessible
            ld   [hl], ("8" - "0") + 1
            inc   hl
            ld   [hl], ("f" - "a") + 11
            inc   hl
            add  a, 1
            ld   [hl], a

        ld   a, DUCK_IO_CMD_ABORT_OR_FAIL
        ld   b, DUCK_IO_FAIL
        jr   .reply_cmd_in_A__status_in_B__return

    .return_failure_1
        ld   a, 1
        jr .return_failure

    .return_failure_2
        ld   a, 2
        jr .return_failure

    .return_failure_3
        ld   a, 3
        jr .return_failure

    .return_failure_4
        ld   a, 4
        jr .return_failure


; Performs MegaDuck laptop IO init
;
; Returns: Status in:  A (DUCK_IO_OK or DUCK_IO_FAIL)
;
; Regs: Does not preserve F
duck_io_laptop_init::

    push bc

    ; Save interrupt enables state
    di
    ld   a, [rIE]
    ld   b, a

    ; Clear Serial IO registers
    xor  a
    ldh  [rSC], a
    ldh  [rSB], a

    ; Initialize Serially attached peripheral
    call duck_io_controller_init
    cp   a, DUCK_IO_OK
    jr   nz, .return_failure

        ; ====== DEBUG
        ld   hl, (_TILEMAP0 + (32 * 9))
        call wait_until_vram_accessible
        ld   [hl], ("9" - "0") + 1
        inc   hl
        ld   [hl], ("y" - "a") + 11

    ; Save response from some unknown command
    ld   a, DUCK_IO_CMD_INIT_UNKNOWN_0x09
    call duck_io_send_byte
    ; TODO: This wait with no timeout is how the System ROM does it,
    ;       but it can probably be changed to a long delay and
    ;       attempt to fail somewhat gracefully.
    call duck_io_read_byte_no_timeout
    ; Discard the reply data (from DUCK_IO_CMD_INIT_UNKNOWN_0x09)
    ; since at present it doesn't get used and the purpose isn't known
    ;; ld   a, [duck_io_rx_byte]

    ; Ignore the RTC init check for now

        ; ====== DEBUG
        ld   hl, (_TILEMAP0 + (32 * 10))
        call wait_until_vram_accessible
        ld   [hl], ("0" - "0") + 1
        inc   hl
        ld   [hl], ("y" - "a") + 11


    ; Return Success
    ld   c, DUCK_IO_OK

    ; Restore saved interrupt enables and turn them on
    .status_in_C__return
        ld   a, b
        ldh  [rIE], a
        ; C has Return Status
        ld   a, c
        pop  bc
        ei
        ret

    .return_failure
        ld   c, DUCK_IO_FAIL
        jr   .status_in_C__return


