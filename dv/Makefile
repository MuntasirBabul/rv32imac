# Makefile – run ALL RV32IMAC tests in <30 seconds

VPATH                      := ./make
VERILATOR                  := verilator
VFLAGS                     := -Wall --cc --exe --build -j 0 --trace --Mdir obj_dir 
VDEFINE                    := 

export RUN_DIRECTORY       := $(realpath .)
export RTL_DIR             := $(abspath $(RUN_DIRECTORY)/../hdl)
export INC_DIR             := $(abspath $(RUN_DIRECTORY)/../hdl/output)

TOP_MODULE                 := rv32imac_core
TESTBENCH                  := tb_top.sv
MEMORY_READ_FILE           := tb_top.cpp
VINCLUDE                   := -I$(INC_DIR)


all:
	@echo "Run: make run TEST=add"  (or any test name)

run:
	  @$(VERILATOR) $(VFLAGS) $(VDEFINE) $(TESTBENCH) $(VINCLUDE) --top-module $(TOP_MODULE) $(RTL_DIR)/$(TOP_MODULE).sv $(MEMORY_READ_FILE) && \
    ./obj_dir/Vtb_top +ELF=/home/nvzheit/riscv-arch-test/riscv-test-suite/rv32i_m/I/build/$(TEST)/$(TEST).hex

# Quick test of all I + M + A + C
test-all:
	@echo "Running RV32IMAC compliance..."
	@cd /home/nvzheit/riscv-arch-test/riscv-test-suite && \
	 for t in rv32i_m/I/src/*.S rv32i_m/M/src/*.S rv32i_m/privilege/src/*.S rv32i_m/C/src/*.S; do \
	   name=$$(basename $$t .S); \
	   echo -n "$$name ... "; \
	   make -s -C rv32i_m/I/build/$$name run > /dev/null 2>&1 && echo "PASS" || echo "FAIL"; \
	 done | tee results.txt
	@grep -c PASS results.txt

clean:
	rm -rf obj_dir *.vcd results.txt
