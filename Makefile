# FBEditor Linux - Makefile
# FreeBASIC + Window9 GUI IDE

FBC = fbc
W9DIR = /home/ronen/freebasic/window9_linux
W9INC = $(W9DIR)/include
W9LIB = $(W9DIR)

# Compiler flags
FBFLAGS = -s gui -i $(W9INC) -i include -p $(W9LIB) -exx -g -Wl "-rpath,$(W9LIB)"
FBFLAGS_RELEASE = -s gui -i $(W9INC) -i include -p $(W9LIB) -O 2 -Wl "-rpath,$(W9LIB)"

# Source files
MAIN = src/main.bas

# Output
TARGET = fbeditor

.PHONY: all clean debug release run

all: debug

debug: $(MAIN)
	$(FBC) $(FBFLAGS) $(MAIN) -x $(TARGET)

release: $(MAIN)
	$(FBC) $(FBFLAGS_RELEASE) $(MAIN) -x $(TARGET)

run: debug
	./$(TARGET)

clean:
	rm -f $(TARGET)
