
DEF DUCK_IO_OK   EQU 1  ; true
DEF DUCK_IO_FAIL EQU 0  ; false


; Commands sent via serial IO to the Duck laptop peripheral hardware
DEF DUCK_IO_CMD_INIT_START                     EQU $00   ; Command to request starting the hardware init counter sequence process 
DEF DUCK_IO_CMD_GET_KEYS                       EQU $00   ; Command to get hardware keyboard data by receiving a multi-byte packet
DEF DUCK_IO_CMD_DONE_OR_OK                     EQU $01
; DEF DUCK_IO_CMD_DONE_OR_OK_AND_SOMETHING       EQU $81
DEF DUCK_IO_CMD_ABORT_OR_FAIL                  EQU $04
DEF DUCK_IO_CMD_PLAY_SPEECH                    EQU $05
DEF DUCK_IO_CMD_RUN_CART_IN_SLOT               EQU $08
DEF DUCK_IO_CMD_INIT_UNKNOWN_0x09               EQU $09   ; May also be PrintScreen related 
DEF DUCK_IO_CMD_SET_RTC                        EQU $0B   ; Command to set hardware RTC by sending a multi-byte packet 
DEF DUCK_IO_CMD_GET_RTC                        EQU $0C   ; Command to get hardware RTC by receiving a a multi-byte packet 


; DEF FF60_REG_BEFORE_XFER            EQU $00
DEF DUCK_IO_REPLY_BOOT_UNSET           EQU $00
DEF DUCK_IO_REPLY_BOOT_FAIL            EQU $01
DEF DUCK_IO_REPLY_BUFFER_XFER_OK       EQU $01
DEF DUCK_IO_REPLY_SEND_BUFFER_OK       EQU $03
; DEF DUCK_IO_REPLY_READ_FAIL_MAYBE         EQU $00
DEF DUCK_IO_REPLY_BOOT_OK              EQU $01

DEF DUCK_IO_LEN_KBD_GET                EQU 2 ; Get Keyboard key payload size: 2 bytes Payload (excludes 1 length header byte, 1 byte Checksum) 
DEF DUCK_IO_LEN_RTC_GET                EQU 8 ; Get RTC          payload size: 8 bytes Payload (excludes 1 length header byte, 1 byte Checksum) 
DEF DUCK_IO_LEN_RTC_SET                EQU 8 ; Set RTC          payload size: 8 bytes Payload (excludes 1 length header byte, 1 byte Checksum) 
DEF DUCK_IO_LEN_PLAY_SPEECH            EQU 1 ; Play Speech      payload size: 1 byte  Payload (excludes 1 length header byte, 1 byte Checksum) 


; DEF MEGADUCK_KBD_BYTE_1_EXPECT        EQU $0E
; DEF MEGADUCK_SIO_BOOT_OK              EQU $01

DEF DUCK_IO_LEN_RX_MAX                 EQU 14 ; 13 data bytes + 1 checksum byte max reply length?
DEF DUCK_IO_LEN_TX_MAX                 EQU 14 ; 13 data bytes + 1 checksum byte max reply length?

DEF DUCK_IO_TIMEOUT_2_MSEC             EQU 2  ; Used for hardware init counter sequence
DEF DUCK_IO_TIMEOUT_100_MSEC           EQU 100
DEF DUCK_IO_TIMEOUT_200_MSEC           EQU 200


; Pre-recorded Speech Samples for playback
DEF DUCK_IO_SPEECH_CMD_MIN      EQU 1
DEF DUCK_IO_SPEECH_CMD_MAX      EQU 6


; RTC packet byte ordering (all in BCD format)
DEF DUCK_IO_RTC_YEAR         EQU 0
DEF DUCK_IO_RTC_MON          EQU 1
DEF DUCK_IO_RTC_DAY          EQU 2
DEF DUCK_IO_RTC_WEEKDAY      EQU 3
DEF DUCK_IO_RTC_AMPM         EQU 4
DEF DUCK_IO_RTC_HOUR         EQU 5
DEF DUCK_IO_RTC_MIN          EQU 6
DEF DUCK_IO_RTC_SEC          EQU 7


; Keyboard packet byte ordering (all in BCD format)
DEF DUCK_IO_KBD_FLAGS        EQU 0
DEF DUCK_IO_KBD_KEYCODE      EQU 1

