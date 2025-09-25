CC              = gcc
CFLAGS          = -Wall -O3 -fPIC
INCLUDES        = -I ../testbench/tiny_sha3
TESTNAME        = sha3_test_lib.random_test_parameterized!(32, 10)

DEBUG = NONE

DFLAGS = -relocation-model=pic -w -O3 -release -boundscheck=off

SEED            = 1
DUMPFST         = 1
VEROPTS         = -O3 --euvm --no-timing --x-assign fast --x-initial fast --threads 1 -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-CASEINCOMPLETE 

ifeq ($(DUMPFST),1)
        VEROPTS += --trace-fst
endif

ifeq ($(DUMPFST),1)
        DFLAGS += --d-version=DUMPFST
endif

LDC2BINDIR = $(dir $(shell which ldc2))
VLBINDIR = $(dir $(shell which verilator))
VERBOSITY = NONE

TBSRC = ../testbench/*.d \
	../testbench/apb/*.d

DUTLIB = obj_dir/DVsha3_apb.a

.PHONY: all clean

all: sha3_apb

clean:
	rm -rf sha3_apb* libsha3.a sha3.o euvm_dir obj_dir link_verilator

link_verilator: ../src/rtl/*.v
	verilator $(VEROPTS) $^
	(cd obj_dir; make -f DVsha3_apb.mk DVsha3_apb.a)
	touch link_verilator

run: sha3_apb
	./sha3_apb '+UVM_TESTNAME=$(TESTNAME)' +UVM_VERBOSITY=$(VERBOSITY) +random_seed=$(SEED) # +UVM_OBJECTION_TRACE # +UVM_VERBOSITY=DEBUG

sha3_apb: link_verilator $(DUTLIB) $(TBSRC) libsha3.a
	ldc2 $(DFLAGS) -Ieuvm_dir $(DUTLIB) -of$@ -L-luvm-ldc-shared -L-lesdl-ldc-shared \
		-L-lphobos2-ldc-shared -L-ldruntime-ldc-shared -L-ldl $(TBSRC) libsha3.a obj_dir/Vsha3_apb__ALL.a -L-lstdc++


libsha3.a: sha3.o
	ar r $@ $^

sha3.o: ../testbench/tiny_sha3/sha3.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
