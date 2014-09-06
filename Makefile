# Adapted from darkstalker's makefile: https://gist.github.com/darkstalker/2221824

COMPILER = gdc
# Maybe it's because I'm running this in VirtualBox emulating 64-bit Linux on
# my Intel Windows host, but adding a -m64 or -m32 flag screws everything up
# and slows it down.
DFLAGS = -w
LIBS =
SRC = $(wildcard *.d)
UNAME = $(shell uname)
ifeq ($(UNAME), Linux) 
	OBJ = $(SRC:.d=.o)
else ifeq ($(UNAME), CYGWIN_NT-6.3)
	OBJ = $(SRC:.d=.obj)
else
	$(error Not tested on $(UNAME))
endif

OUT = $(shell basename `pwd`)
 
.PHONY: all debug release profile clean
 
all: debug
 
debug:   DFLAGS += -g -fdebug
release: DFLAGS += -O3 -frelease -finline-functions -fno-bounds-check
profile: DFLAGS += -g -O3
 
debug release profile: $(OUT)
 
$(OUT): $(OBJ)
	$(COMPILER) $(DFLAGS) -o$@ $(OBJ) $(LIBS)
 
clean:
	rm -f *~ $(OBJ) $(OUT) trace.{def,log}

%.o: %.d
	$(COMPILER) $(DFLAGS) -c $<
%.obj: %.d
	$(COMPILER) $(DFLAGS) -c $<
