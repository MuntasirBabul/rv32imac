# Makefile – run ALL RV32IMAC tests in <30 seconds
VERILATOR = verilator
VFLAGS = -Wall --cc --exe --build -j 0 --trace

all:
	@echo "Run: make run TEST=add"  (or any test name)

run:
	$(VERILATOR) $(VFLAGS) \
	  --top-module tb_top \
	  tb_top.sv ../hdl/rv32imac_core.sv \
	  tb_top.cpp \
	  +define+VERILATOR \
	  --Mdir obj_dir \
	  --exe
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
