
OBJ_DIR = obj
BIN_DIR = build
SRC_DIR = src
RES_DIR = res

BIN_EXT  = duck
BIN_NAME = keybaord_rtc


all:
	mkdir -p $(OBJ_DIR)
	mkdir -p $(BIN_DIR)
	rgbgfx  $(RES_DIR)/font.png -o $(RES_DIR)/font.bin
	rgbasm  -w $(SRC_DIR)/main.asm -o $(OBJ_DIR)/main.o --halt-without-nop
	rgbasm  -w ../common/megaduck_laptop_io.asm -o $(OBJ_DIR)/megaduck_laptop_io.o --halt-without-nop
	rgbasm  -w ../common/megaduck_laptop_keyboard.asm -o $(OBJ_DIR)/megaduck_laptop_keyboard.o --halt-without-nop
	rgbasm  -w ../common/megaduck_laptop_rtc.asm -o $(OBJ_DIR)/megaduck_laptop_rtc.o --halt-without-nop
	rgblink $(OBJ_DIR)/main.o $(OBJ_DIR)/megaduck_laptop_io.o $(OBJ_DIR)/megaduck_laptop_keyboard.o $(OBJ_DIR)/megaduck_laptop_rtc.o -o $(BIN_DIR)/$(BIN_NAME).$(BIN_EXT) -n $(BIN_DIR)/$(BIN_NAME).sym -m $(BIN_DIR)/$(BIN_NAME).map


clean:
	rm -rf $(OBJ_DIR)/*.o $(BIN_DIR)/*.map $(BIN_DIR)/*.sym $(BIN_DIR)/*.duck

romusage:
	romusage -g -sRp -a $(BIN_DIR)/$(BIN_NAME).map


