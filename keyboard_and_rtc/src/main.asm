

DEF TARGET_MEGADUCK EQU 1

include "src/charmap.inc"
include "../inc/hardware.inc"
include "../inc/megaduck_laptop_io.inc"
include "../inc/megaduck_laptop_keycodes.inc"

LD_ADDR_TILEMAP0_X_Y: MACRO
; \1 = Register
; \2 = X coordinate
; \3 = Y coordinate
    ld   \1, (_TILEMAP0 + (_TILEMAP_WIDTH * \3) + \2)
ENDM


; ROM Header
SECTION "Duck Entry Point", ROM0[$0]
duck_entry_point:
    di
    ld   sp, $E000
    jp   entry_point



SECTION "GB Entry Point", ROM0[$100]
    jp   duck_entry_point



SECTION "Entry Point", ROM0[$150]

entry_point:

    ; Turn screen off if needed
    ld   a, [rLCDC]
    and  a, LCDCF_ON
    call nz, wait_vblank

    ; Turn off screen and everything
    ld   a, $0
    ldh  [rLCDC], a

    ; Clear Tilemap 0
    ld   hl, _TILEMAP0
    ld   bc, (_TILEMAP_WIDTH * _TILEMAP_HEIGHT)
    ld   a, " "
    call memset

    ; Load font tileset
    ld   de, FontTilesStart
    ld   hl, _TILEDATA9000
    ld   bc, FontTilesEnd - FontTilesStart
    call memcopy

    ; Turn on screen and set palette
    ld   a, LCDCF_ON | LCDCF_BGON | LCDCF_BG9800 | LCDCF_BG8800
    ldh  [rLCDC], a
    ld   a, (0 | 1 << 2 | 2 << 4 | 3 << 6)
    ldh  [rBGP], a

    ; enable interrupts (none activated)
    ld   a, $0
    ldh  [rIE], a
    ldh  [rIF], a
    ei


    ; Some intro text
    LD_ADDR_TILEMAP0_X_Y HL, 0, 0
    ld   bc, string_key_code
    call print_string

    LD_ADDR_TILEMAP0_X_Y HL, 0, 1
    ld   bc, string_init_start
    call print_string

    LD_ADDR_TILEMAP0_X_Y HL, 0, 2
    ld   bc, string_init_info
    call print_string


    ; Initialize the peripheral IO hardware
    call duck_io_laptop_init
    cp   a, DUCK_IO_OK
    jr   nz, .init_fail

    .init_ok
        LD_ADDR_TILEMAP0_X_Y HL, 0, 3
        ld   bc, string_init_ok
        call print_string
        jr .init_done

    .init_fail
        LD_ADDR_TILEMAP0_X_Y HL, 0, 3
        ld   bc, string_init_fail
        call print_string

    .init_done

main_loop:

    ; Wait 2 frames between polling
    call wait_next_frame_start
    call wait_next_frame_start

    call poll_keyboard

    jr main_loop



; Poll the MegaDuck Keyboard
;
; Regs: Does not preserve AF, BC, HL
poll_keyboard:
    call duck_io_keyboard_poll
    cp   a, DUCK_IO_OK
    jr   nz, .key_fail

    .key_ok
        LD_ADDR_TILEMAP0_X_Y HL, 0, 4
        ld   bc, string_poll_ok
        call print_string

        ld   a, [duck_key_scancode]
        or   a
        jr   z, .key_done

        ; Keyboard commands
        cp   a, DUCK_IO_KEY_1
        jr   z, .key_rtc_get

        cp   a, DUCK_IO_KEY_2
        jr   z, .key_rtc_set

        jr   .key_handle_done

        .key_rtc_get
            push af
            call read_rtc
            pop  af
            jr   .key_handle_done

        .key_rtc_set
            push af
            call write_rtc
            pop  af
            jr   .key_handle_done

        .key_handle_done
        LD_ADDR_TILEMAP0_X_Y HL, 9, 0
        call print_hex
        jr .key_done

    .key_fail
        LD_ADDR_TILEMAP0_X_Y HL, 0, 5
        ld   bc, string_poll_fail
        call print_string

    .key_done
    ret



; Read from the MegaDuck RTC
;
; Regs: Does not preserve AF, HL, BC
read_rtc:
    call duck_io_get_rtc
    cp   a, DUCK_IO_OK
    jr   nz, .rtc_fail

    .rtc_ok
        LD_ADDR_TILEMAP0_X_Y HL, 0, 10
        ld   bc, string_rtc_get_ok
        call print_string

        ; Print RTC data
        LD_ADDR_TILEMAP0_X_Y HL, 0, 11
        ld   a, [duck_rtc_year]
        call print_hex

        inc  hl
        ld   a, [duck_rtc_mon]
        call print_hex

        inc  hl
        ld   a, [duck_rtc_day]
        call print_hex

        inc  hl
        ld   a, [duck_rtc_weekday]
        call print_hex

        LD_ADDR_TILEMAP0_X_Y HL, 0, 12
        ld   a, [duck_rtc_ampm]
        call print_hex

        inc  hl
        ld   a, [duck_rtc_hour]
        call print_hex

        inc  hl
        ld   a, [duck_rtc_min]
        call print_hex

        inc  hl
        ld   a, [duck_rtc_sec]
        call print_hex

        jr .rtc_done

    .rtc_fail
        LD_ADDR_TILEMAP0_X_Y HL, 0, 10
        ld   bc, string_rtc_get_fail
        call print_string

    .rtc_done
    ret



; Write to the MegaDuck RTC
;
; Regs: Does not preserve AF
write_rtc:
    ; Data for RTC: Friday, Jan 2, 2015, 03:45pm 01 sec
    ld   a, (2015 - 1900) ; $73 = 115
    ld   [duck_rtc_year], a
    ld   a, $01 ; Jan=1
    ld   [duck_rtc_mon], a
    ld   a, $02 ; 2nd day of month
    ld   [duck_rtc_day], a
    ld   a, $05 ; 5 = Friday (days since Sunday 0-6)
    ld   [duck_rtc_weekday], a

    ld   a, 1 ; AM = 0, PM = 1
    ld   [duck_rtc_ampm], a
    ld   a, $03 ; Hour 0-11
    ld   [duck_rtc_hour], a
    ld   a, $45;  Min
    ld   [duck_rtc_min], a
    ld   a, $01;  Sec
    ld   [duck_rtc_sec], a

    call duck_io_set_rtc
    cp   a, DUCK_IO_OK
    jr   nz, .rtc_set_fail

    .rtc_set_ok
    LD_ADDR_TILEMAP0_X_Y HL, 0, 13
    ld   bc, string_rtc_set_ok
    call print_string
    ret

    .rtc_set_fail
        LD_ADDR_TILEMAP0_X_Y HL, 0, 13
        ld   bc, string_rtc_set_fail
        call print_string
        ret



; ==== Printing ====

; Calculate X,Y in screen tile map coordinates
;
; Param: string address: in BC
;      : vram address:   in HL
print_string:
    push af
    .string_print_loop
        ld   a, [bc]
        ; Check for string terminator
        cp   a, FONT_STRING_TERM
        jr   z, .done
        call wait_until_vram_accessible
        ld   [hl], a
        inc  hl
        inc  bc
        jr   .string_print_loop

    .done
    pop af
    ret


; Print hex value in a at HL
;
; Param: byte value to print: in A
;      : vram address:        in HL
;
; Returns: Address after printing in VRAM tile map (32 wide): HL
print_hex:
    push af
    ; High digit
    and  a, $F0
    swap a
    add  FONT_DIGIT_START  ; start of font digit 0
    call wait_until_vram_accessible
    ldi  [hl], a

    ; Low digit
    pop  af
    and  a, $0F
    add  FONT_DIGIT_START  ; start of font digit 0
    ldi  [hl], a
    ret


; ==== UTIL ====


wait_until_vram_accessible::
    push af
    .loop_while_hblank_or_vblank
    ld   a, [rSTAT]
    and  STATF_BUSY
    jr   nz, .loop_while_hblank_or_vblank
    pop  af
    ret


wait_vblank::
    push af
    .wait_loop
    ld   a, [rLY]
    cp   144
    jr   c, .wait_loop
    pop  af
    ret


wait_next_frame_start:
    push af
    call wait_vblank
    .wait_loop
        ld   a, [rLY]
        cp   1
        jr   nz, .wait_loop
    pop  af
    ret


; 16 bit memset
;
; Param: fill value  :  A
;        dest addr in:  HL
;        size        :  BC
memset:
    push de
    ld   d, a
    .memset_loop
        ld   a, d
        ldi  [hl], a
        dec  bc
        ld   a, b
        or   a, c
        jr   nz, .memset_loop
    pop de
    ret

; 16 bit memcopy
;
; Param: src  addr in:  DE
;        dest addr in:  HL
;        size        :  BC
memcopy:
    push af
    .memcopy_loop
        ld   a, [de]
        ldi  [hl], a
        inc  de

        dec  bc
        ld   a, b
        or   a, c
        jr   nz, .memcopy_loop
    pop  af
    ret

; ==== RESOURCE ====

SECTION "Font", ROM0
; Font tileset
FontTilesStart:
incbin "res/font.bin"
FontTilesEnd:



SECTION "Strings", ROM0

string_poll_fail:
db "Poll Fail", FONT_STRING_TERM
string_poll_ok:
db "Poll OK", FONT_STRING_TERM

string_key_code:
db "Key Code:", FONT_STRING_TERM
string_init_start:
db "Init Start", FONT_STRING_TERM
string_init_info:
db "1:RTC GET 2:RTC SET", FONT_STRING_TERM

string_init_fail:
db "Init Fail", FONT_STRING_TERM
string_init_ok:
db "Init OK", FONT_STRING_TERM

string_rtc_set_fail:
db "rtc set Fail", FONT_STRING_TERM
string_rtc_set_ok:
db "rtc set OK", FONT_STRING_TERM

string_rtc_get_fail:
db "rtc get Fail", FONT_STRING_TERM
string_rtc_get_ok:
db "rtc get OK", FONT_STRING_TERM

