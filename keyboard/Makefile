
OBJ_DIR = obj
BIN_DIR = build

all:
	mkdir -p $(OBJ_DIR)
	mkdir -p $(BIN_DIR)
	rgbgfx  font.png -o font.bin
	rgbasm  -w duck_test.asm -o $(OBJ_DIR)/duck_test.o --halt-without-nop
	rgbasm  -w ../common/megaduck_laptop_io.asm -o $(OBJ_DIR)/megaduck_laptop_io.o --halt-without-nop
	rgbasm  -w ../common/megaduck_laptop_keyboard.asm -o $(OBJ_DIR)/megaduck_laptop_keyboard.o --halt-without-nop
	rgblink $(OBJ_DIR)/duck_test.o $(OBJ_DIR)/megaduck_laptop_io.o $(OBJ_DIR)/megaduck_laptop_keyboard.o -o $(BIN_DIR)/duck_test.duck -n $(BIN_DIR)/duck_test.sym -m $(BIN_DIR)/duck_test.map


clean:
	rm -rf $(OBJ_DIR)/*.o $(BIN_DIR)/*.map $(BIN_DIR)/*.sym $(BIN_DIR)*.duck


