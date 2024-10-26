
DEF TARGET_MEGADUCK EQU 1
include "../inc/hardware.inc"

include "../inc/megaduck_laptop_io.inc"


SECTION "Duck Laptop Keyboard WRAM", WRAMX[$D200]
duck_key_scancode:: db
duck_key_flags:: db


SECTION "Duck Laptop Keyboard", ROM0

; Request Keyboard data and handle the response
;
; Returns: Status in:  A (DUCK_IO_OK or DUCK_IO_FAIL)
;
; Regs: Does not preserve F
duck_io_keyboard_poll::

    ld   a, DUCK_IO_CMD_GET_KEYS
    call duck_io_send_cmd_and_receive_buffer
    cp   a, DUCK_IO_OK
    jr   nz, .return_failure

    ld   a, [duck_io_rx_buf_len]
    cp   a, DUCK_IO_LEN_KBD_GET
    jr   nz, .return_failure

    ; Scan Code and Flags
    ld  a,  [duck_io_rx_buf + DUCK_IO_KBD_FLAGS]
    ld  [duck_key_flags], a
    ld  a,  [duck_io_rx_buf + DUCK_IO_KBD_KEYCODE]
    ld  [duck_key_scancode], a

    .return_success
        ld   a, DUCK_IO_OK
        ret

    .return_failure
        ld   a, DUCK_IO_FAIL
        ret
