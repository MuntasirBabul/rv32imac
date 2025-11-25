// tb/tb_top.sv – Verilator testbench for your RV32IMAC core
`timescale 1ns/1ps
`include "../hdl/output/ctrl_struct.svh"

module tb_top;
  logic clk = 0;
  logic rst_n = 0;

  always #5 clk = ~clk;  // 100 MHz

  // Simple memory model (4 GB flat)
  logic [31:0] imem [0:2**30-1];
  logic [31:0] dmem [0:2**30-1];

  logic [31:0] imem_addr, dmem_addr, dmem_wdata;
  logic [3:0]  dmem_be;
  logic        dmem_req, dmem_we, dmem_valid;
  logic [31:0] dmem_rdata, imem_rdata;

  // DUT
  rv32imac_core dut (
    .clk, .rst_n,
    .imem_addr, .imem_rdata,
    .imem_req  (1'b1),
    .dmem_addr, .dmem_wdata, .dmem_be,
    .dmem_req, .dmem_we,
    .dmem_rdata, .dmem_valid
  );

  // Instruction memory (read-only)
  assign imem_rdata = imem[imem_addr[31:2]];

  // Data memory (synchronous, 1-cycle latency)
  always_ff @(posedge clk) begin
    dmem_valid <= 1'b0;
    if (dmem_req) begin
      dmem_valid <= 1'b1;
      if (dmem_we) begin
        if (dmem_be[0]) dmem[dmem_addr[31:2]][7:0]   <= dmem_wdata[7:0];
        if (dmem_be[1]) dmem[dmem_addr[31:2]][15:8]  <= dmem_wdata[15:8];
        if (dmem_be[2]) dmem[dmem_addr[31:2]][23:16] <= dmem_wdata[23:16];
        if (dmem_be[3]) dmem[dmem_addr[31:2]][31:24] <= dmem_wdata[31:24];
      end
      dmem_rdata <= dmem[dmem_addr[31:2]];
    end
  end

  // Load test program (ELF → memory)
  initial begin
    string elf_file;
    if (!$value$plusargs("ELF=%s", elf_file)) begin
      $display("ERROR: +ELF=<path> not provided!");
      $finish;
    end

    $display("Loading %s ...", elf_file);
    $readmemh(elf_file, imem);  // works with .hex from riscv-tests
    // or use $elfload if you prefer (Verilator supports it)

    #40 rst_n = 1;
    #1000000;
    $display("TIMEOUT – did you forget to ebreak?");
    $finish;
  end

  // Auto-detect success (signature at 0x8000_1000)
  always_ff @(posedge clk) begin
    if (dmem_req && dmem_we && dmem_addr == 32'h80001000 && dmem_wdata == 32'h1)
      begin $display("PASS!"); $finish; end
    if (dmem_req && dmem_we && dmem_addr == 32'h80001000 && dmem_wdata != 32'h0)
      begin $display("FAIL! code=%0d", dmem_wdata); $finish; end
  end

endmodule
