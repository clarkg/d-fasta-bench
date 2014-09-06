# Adapted from darkstalker's makefile: https://gist.github.com/darkstalker/2221824

COMPILER = dmd
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
 
debug:   DFLAGS += -g -debug
release: DFLAGS += -O -release -inline -boundscheck=off
profile: DFLAGS += -g -O -profile
 
debug release profile: $(OUT)
 
$(OUT): $(OBJ)
	$(COMPILER) $(DFLAGS) -of$@ $(OBJ) $(LIBS)
 
clean:
	rm -f *~ $(OBJ) $(OUT) trace.{def,log}

%.o: %.d
	$(COMPILER) $(DFLAGS) -c $<
%.obj: %.d
	$(COMPILER) $(DFLAGS) -c $<
