
; WORKING NOW!

; CLEAN UP AND TEST AGAIN


DEF TARGET_MEGADUCK EQU 1

include "charmap.inc"
include "../inc/hardware.inc"
include "../inc/megaduck_laptop_io.inc"


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

    .fill_tilemap:
        xor  a
        ldi  [hl], a
        dec  bc
        ld   a, b
        or   a, c
        jr   nz, .fill_tilemap

    ; Load font tileset
    ld   de, FontTilesStart
    ld   hl, _TILEDATA9000
    ld   bc, FontTilesEnd - FontTilesStart

    .copy_font_tiles:
        ld   a, [de]
        ldi  [hl], a
        inc  de

        dec  bc
        ld   a, b
        or   a, c
        jr   nz, .copy_font_tiles

    ; Turn on screen and set palette
    ld   a, LCDCF_ON | LCDCF_BGON | LCDCF_BG9800 | LCDCF_BG8800
    ldh  [rLCDC], a
    ld   a, (0 | 1 << 2 | 2 << 4 | 3 << 6)
    ldh  [rBGP], a

    ; enable interrupts (non activated)
    ld   a, $0
    ldh  [rIE], a
    ei


    ld   hl, (_TILEMAP0 + 32)
    call wait_until_vram_accessible
    ld  [hl], "s"


    call duck_io_laptop_init
    cp   a, DUCK_IO_OK
    jr   nz, .init_fail

    .init_ok
        ld   hl, (_TILEMAP0 + (32 * 2))
        call wait_until_vram_accessible
        ld  [hl], "y"
        jr .init_done

    .init_fail
        ld   hl, (_TILEMAP0 + (32 * 2))
        call wait_until_vram_accessible
        ld  [hl], "n"

    .init_done

    ; call wait_next_frame_start
    ; call wait_next_frame_start
main_loop:

    ; jr .end

    ; Wait before
    call wait_next_frame_start
    call wait_next_frame_start

    call duck_io_keyboard_poll
    ; And wait after to ensure min polling time for keyboard
    cp   a, DUCK_IO_OK
    jr   nz, .key_fail

    .key_ok
        ld   hl, (_TILEMAP0 + (32 * 3))
        call wait_until_vram_accessible
        ld  [hl], "p"

        ld   a, [duck_key_scancode]
        or   a
        jr   z, .key_done

        ; If not MEGADUCK_KBD_CODE_NONE, then print
        call nz, print_hex
        jr .key_done

    .key_fail
        ld   hl, (_TILEMAP0 + (32 * 4))
        call wait_until_vram_accessible
        ld  [hl], "f"


    .key_done

.end
    ; jr .end
    jr main_loop


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

print_hex:
    push af
    push hl

    ld   hl, _TILEMAP0
    call wait_until_vram_accessible

    ; Clear print area
    ld   [hl], 0
    inc  hl
    ld   [hl], 0
    dec  hl

    push af
    ; High digit
    and  a, $F0
    swap a
    add  FONT_DIGIT_START  ; start of font digit 0
    ldi  [hl], a

    ; Low digit
    pop  af
    and  a, $0F
    add  FONT_DIGIT_START  ; start of font digit 0
    ldi  [hl], a

    pop  hl
    pop  af
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



; ==== RESOURCE ====

SECTION "Font", ROM0
; Font tileset
FontTilesStart:
incbin "font.bin"
FontTilesEnd:
