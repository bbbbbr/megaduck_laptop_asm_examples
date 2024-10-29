
; - Left /right shift are shared
;
; Keyboard serial reply scan codes have different ordering than System ROM character codes
; - They go diagonal down from upper left for the first *4* rows
; - The bottom 4 rows (including piano keys) are more varied

; Modifier Keys / Flags
;
; See input_key_modifier_flags__RAM_D027_
DEF DUCK_IO_KEY_FLAG_KEY_REPEAT           EQU $01
DEF DUCK_IO_KEY_FLAG_KEY_REPEAT_BIT       EQU $0
DEF DUCK_IO_KEY_FLAG_CAPSLOCK             EQU $02
DEF DUCK_IO_KEY_FLAG_CAPSLOCK_BIT         EQU $1
DEF DUCK_IO_KEY_FLAG_SHIFT                EQU $04
DEF DUCK_IO_KEY_FLAG_SHIFT_BIT            EQU $2
; Right Print Screen has actual scancode vs Left being in a flag
DEF DUCK_IO_KEY_FLAG_PRINTSCREEN_LEFT     EQU $08
DEF DUCK_IO_KEY_FLAG_PRINTSCREEN_LEFT_BIT EQU $3

; Keyboard scancodes
; All valid keys seem to have bit 7 set ($80+)
DEF DUCK_IO_KEY_BASE_BIT                  EQU $7
DEF DUCK_IO_KEY_BASE                      EQU $80


; First 4 rows (top of keyboard)  ~ $80 - $B7
;
; - For each row, most chars are +4 vs char to immediate left
;   due to the diagonal down-right scancode ordering
;
; Starting values
; - Row 1: $80
; - Row 2: $81
; - Row 3: $82
; - Row 4: $83

; Row 1
DEF DUCK_IO_KEY_F1                  EQU $80
DEF DUCK_IO_KEY_F2                  EQU $84
DEF DUCK_IO_KEY_F3                  EQU $88
DEF DUCK_IO_KEY_F4                  EQU $8C
DEF DUCK_IO_KEY_F5                  EQU $90
DEF DUCK_IO_KEY_F6                  EQU $94
DEF DUCK_IO_KEY_F7                  EQU $98
DEF DUCK_IO_KEY_F8                  EQU $9C
DEF DUCK_IO_KEY_F9                  EQU $A0
DEF DUCK_IO_KEY_F10                 EQU $A4
DEF DUCK_IO_KEY_F11                 EQU $A8
DEF DUCK_IO_KEY_F12                 EQU $AC
; GAP at $B0 maybe Blank spot where F13 would be
; GAP at $B4 maybe ON Key?

; Row 2
DEF DUCK_IO_KEY_ESCAPE              EQU $81  ; Spanish label: Salida | German label: Esc
DEF DUCK_IO_KEY_1                   EQU $85  ; Shift alt: !
DEF DUCK_IO_KEY_2                   EQU $89  ; Shift alt: "
DEF DUCK_IO_KEY_3                   EQU $8D  ; Shift alt: · (Spanish, mid-dot) | § (German, legal section)
DEF DUCK_IO_KEY_4                   EQU $91  ; Shift alt: $
DEF DUCK_IO_KEY_5                   EQU $95  ; Shift alt: %
DEF DUCK_IO_KEY_6                   EQU $99  ; Shift alt: &
DEF DUCK_IO_KEY_7                   EQU $9D  ; Shift alt: /
DEF DUCK_IO_KEY_8                   EQU $A1  ; Shift alt: (
DEF DUCK_IO_KEY_9                   EQU $A5  ; Shift alt: )
DEF DUCK_IO_KEY_0                   EQU $A9  ; Shift alt: "\"
DEF DUCK_IO_KEY_SINGLE_QUOTE        EQU $AD  ; Shift alt: ?  | German version: ß (eszett)
DEF DUCK_IO_KEY_EXCLAMATION_FLIPPED EQU $B1  ; Shift alt: ¿ (Spanish) | ` (German)  ; German version: ' (single quote?)
DEF DUCK_IO_KEY_BACKSPACE           EQU $B5  ; German label: Lösch
; See Continued Row 2 below

; Row 3
DEF DUCK_IO_KEY_HELP                EQU $82  ; Spanish label: Ayuda | German label: Hilfe
DEF DUCK_IO_KEY_Q                   EQU $86
DEF DUCK_IO_KEY_W                   EQU $8A
DEF DUCK_IO_KEY_E                   EQU $8E
DEF DUCK_IO_KEY_R                   EQU $92
DEF DUCK_IO_KEY_T                   EQU $96
DEF DUCK_IO_KEY_Y                   EQU $9A  ; German version: z
DEF DUCK_IO_KEY_U                   EQU $9E
DEF DUCK_IO_KEY_I                   EQU $A2
DEF DUCK_IO_KEY_O                   EQU $A6
DEF DUCK_IO_KEY_P                   EQU $AA
DEF DUCK_IO_KEY_BACKTICK            EQU $AE  ; Shift alt: [ (Spanish, only shift mode works) | German version: Ü
DEF DUCK_IO_KEY_RIGHT_SQ_BRACKET    EQU $B2  ; Shift alt: * | German version: · (mid-dot)
DEF DUCK_IO_KEY_ENTER               EQU $B6  ; Spanish label: Entra | German label: Ein-gabe
; See Continued Row 3 below

; Row 4
; GAP at $83 maybe CAPS LOCK  (Spanish label: Mayuscula, German label: Groß)
DEF DUCK_IO_KEY_A                   EQU $87
DEF DUCK_IO_KEY_S                   EQU $8B
DEF DUCK_IO_KEY_D                   EQU $8F
DEF DUCK_IO_KEY_F                   EQU $93
DEF DUCK_IO_KEY_G                   EQU $97
DEF DUCK_IO_KEY_H                   EQU $9B
DEF DUCK_IO_KEY_J                   EQU $9F
DEF DUCK_IO_KEY_K                   EQU $A3
DEF DUCK_IO_KEY_L                   EQU $A7
DEF DUCK_IO_KEY_N_TILDE             EQU $AB  ; German version: ö
DEF DUCK_IO_KEY_U_UMLAUT            EQU $AF  ; German version: ä
DEF DUCK_IO_KEY_O_OVER_LINE         EQU $B3  ; Shift alt: [A over line] (Spanish) | ^ (German) | German version: #
; ? GAP at $87 ?


; Second 4 rows (bottom of keyboard) ~ $80 - $B7
;
; - For each row, most chars are +4 vs char to immediate left
;
; Starting values
; - Row 5: $B8
; - Row 6: $B9
; - Row 7: $BA
; - Row 8: $BB

; Row 5
DEF DUCK_IO_KEY_Z                   EQU $B8  ; German version: y
DEF DUCK_IO_KEY_X                   EQU $BC
DEF DUCK_IO_KEY_C                   EQU $C0
DEF DUCK_IO_KEY_V                   EQU $C4
DEF DUCK_IO_KEY_B                   EQU $C8
DEF DUCK_IO_KEY_N                   EQU $CC
DEF DUCK_IO_KEY_M                   EQU $D0
DEF DUCK_IO_KEY_COMMA               EQU $D4
DEF DUCK_IO_KEY_PERIOD              EQU $D8
DEF DUCK_IO_KEY_DASH                EQU $DC  ; Shift alt: _ | German version: @
; See Continued Row 5 below
; Row 6 Continued (from below)
DEF DUCK_IO_KEY_DELETE              EQU $E0  ; *  Spanish label: Borrar | German label: Entf.



; Encoding is less orderly below

; Row 6
DEF DUCK_IO_KEY_SPACE               EQU $B9  ; Spanish label: Espacio | German label (blank)
; Continued Row 5
DEF DUCK_IO_KEY_LESS_THAN           EQU $BD  ; Shift alt: >
; Continued Row 6
DEF DUCK_IO_KEY_PAGE_UP             EQU $C1  ; Spanish label: Pg Arriba | German label: Zu-rück
DEF DUCK_IO_KEY_PAGE_DOWN           EQU $C5  ; Spanish label: Pg Abajo | German label: Wei-ter
DEF DUCK_IO_KEY_MEMORY_MINUS        EQU $C9
; Continued Row 5
DEF DUCK_IO_KEY_MEMORY_PLUS         EQU $CD
DEF DUCK_IO_KEY_MEMORY_RECALL       EQU $D1
DEF DUCK_IO_KEY_SQUAREROOT          EQU $D5
; ** 3x3 Arrow and Math Key area **
; Continued Row 6
DEF DUCK_IO_KEY_MULTIPLY            EQU $D9
DEF DUCK_IO_KEY_ARROW_DOWN          EQU $DD
DEF DUCK_IO_KEY_MINUS               EQU $E1
; Continued Row 3
DEF DUCK_IO_KEY_ARROW_LEFT          EQU $E5
DEF DUCK_IO_KEY_EQUALS              EQU $E9
DEF DUCK_IO_KEY_ARROW_RIGHT         EQU $ED
; Continued Row 2
DEF DUCK_IO_KEY_DIVIDE              EQU $E4  ; German version: :
DEF DUCK_IO_KEY_ARROW_UP            EQU $E8
DEF DUCK_IO_KEY_PLUS                EQU $EC

; Row 7
; Piano Sharp Keys
DEF DUCK_IO_KEY_PIANO_DO_SHARP      EQU $BA
DEF DUCK_IO_KEY_PIANO_RE_SHARP      EQU $BE
; GAP at $C2 where there is no key
DEF DUCK_IO_KEY_PIANO_FA_SHARP      EQU $C6
DEF DUCK_IO_KEY_PIANO_SOL_SHARP     EQU $CA
DEF DUCK_IO_KEY_PIANO_LA_SHARP      EQU $CE
; GAP at $D2 where there is no key
;
; Octave 2 maybe
DEF DUCK_IO_KEY_PIANO_DO_2_SHARP    EQU $D6
DEF DUCK_IO_KEY_PIANO_RE_2_SHARP    EQU $DA
; Row 6 Continued
DEF DUCK_IO_KEY_PRINTSCREEN_RIGHT   EQU $DE  ; German label: Druck (* Mixed in with piano keys)
; Row 7 Continued
DEF DUCK_IO_KEY_PIANO_FA_2_SHARP    EQU $E2
DEF DUCK_IO_KEY_PIANO_SOL_2_SHARP   EQU $E6
DEF DUCK_IO_KEY_PIANO_LA_2_SHARP    EQU $EA

; Row 8
; Piano Primary Keys
DEF DUCK_IO_KEY_PIANO_DO            EQU $BB
DEF DUCK_IO_KEY_PIANO_RE            EQU $BF
DEF DUCK_IO_KEY_PIANO_MI            EQU $C3
DEF DUCK_IO_KEY_PIANO_FA            EQU $C7
DEF DUCK_IO_KEY_PIANO_SOL           EQU $CB
DEF DUCK_IO_KEY_PIANO_LA            EQU $CF
DEF DUCK_IO_KEY_PIANO_SI            EQU $D3
DEF DUCK_IO_KEY_PIANO_DO_2          EQU $D7
DEF DUCK_IO_KEY_PIANO_RE_2          EQU $DB
DEF DUCK_IO_KEY_PIANO_MI_2          EQU $DF
DEF DUCK_IO_KEY_PIANO_FA_2          EQU $E3
DEF DUCK_IO_KEY_PIANO_SOL_2         EQU $E7
DEF DUCK_IO_KEY_PIANO_LA_2          EQU $EB
DEF DUCK_IO_KEY_PIANO_SI_2          EQU $EF

DEF DUCK_IO_KEY_LAST_KEY            EQU DUCK_IO_KEY_PIANO_SI_2

; Special System Codes? $F0+
DEF DUCK_IO_KEY_MAYBE_SYST_CODES_START EQU $F0
DEF DUCK_IO_KEY_MAYBE_RX_NOT_A_KEY     EQU $F6
