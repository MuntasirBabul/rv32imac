//==============================================================================
//  My Own RV32IMAC Single-Cycle Core – 100% mine, 100% output helpers
//  Uses ONLY the files you already output
//==============================================================================
`include "/home/nvzheit/projects/rv32imac/hdl/output/ctrl_struct.svh"
`include "/home/nvzheit/projects/rv32imac/hdl/output/rv32imac_decode.svh"
`include "/home/nvzheit/projects/rv32imac/hdl/output/rv32imac_imm.svh"
`include "/home/nvzheit/projects/rv32imac/hdl/output/rv32imac_c_decode.svh"
`include "/home/nvzheit/projects/rv32imac/hdl/output/rv32imac_muldiv.svh"
`include "/home/nvzheit/projects/rv32imac/hdl/output/rv32imac_ls.svh"
`include "/home/nvzheit/projects/rv32imac/hdl/output/rv32imac_csr.svh"
`include "/home/nvzheit/projects/rv32imac/hdl/output/csr_pkg.sv"

module rv32imac_core import rv32imac_pkg::*, csr_pkg::*; #(
  parameter BOOT_ADDR = 32'h8000_0000
) (
  input  logic        clk,
  input  logic        rst_n,

  // Simple instruction memory (32-bit wide, 16-bit aligned fetch)
  output logic [31:0] imem_addr,
  input  logic [31:0] imem_rdata,
  output logic        imem_req,

  // Simple data memory (32-bit AXI-like)
  output logic [31:0] dmem_addr,
  output logic [31:0] dmem_wdata,
  output logic [ 3:0] dmem_be,
  output logic        dmem_req,
  output logic        dmem_we,
  input  logic [31:0] dmem_rdata,
  input  logic        dmem_valid
);

  // ========================================================================
  //  Fetch
  // ========================================================================
  logic [31:0] pc, pc_next, pc_plus4;
  logic [31:0] instr_raw, instr_32;
  logic        compressed, illegal_c;

  assign pc_plus4 = pc + 32'd4;
  assign imem_addr = pc;
  assign imem_req  = 1'b1;
  assign instr_raw = imem_rdata;

  // Compressed expander
  `include "/home/nvzheit/projects/rv32imac/hdl/output/rv32imac_c_decode.svh"

  // ========================================================================
  //  Decode
  // ========================================================================
  ctrl_t ctrl;
  logic [31:0] imm;

  always_comb begin
    ctrl = '0;
    ctrl.illegal = 1'b1;
    if (illegal_c) ctrl.illegal = 1'b1;
    else `include "/home/nvzheit/projects/rv32imac/hdl/output/rv32imac_decode.svh"
  end

  // Immediate extractor
  `include "/home/nvzheit/projects/rv32imac/hdl/output/rv32imac_imm.svh"

  // ========================================================================
  //  Register File
  // ========================================================================
  logic [31:0] rf [32];
  logic [31:0] rs1_data;
  logic [31:0] rs2_data;

  always_ff @(posedge clk) begin
    if (ctrl.wb_en && ctrl.rd_addr != 5'd0)
      rf[ctrl.rd_addr] <= wb_data;
  end

  assign rs1_data = (ctrl.rs1_addr==0) ? 0 : rf[ctrl.rs1_addr];
  assign rs2_data = (ctrl.rs2_addr==0) ? 0 : rf[ctrl.rs2_addr];

  // ========================================================================
  //  ALU
  // ========================================================================
  logic [31:0] alu_a = ctrl.alu_src1_pc ? pc : rs1_data;
  logic [31:0] alu_b = ctrl.alu_src2_imm ? imm : rs2_data;
  logic [31:0] alu_out;

  always_comb begin
    case (ctrl.alu_op)
      ALU_ADD:  alu_out = alu_a + alu_b;
      ALU_SUB:  alu_out = alu_a - alu_b;
      ALU_AND:  alu_out = alu_a & alu_b;
      ALU_OR:   alu_out = alu_a | alu_b;
      ALU_XOR:  alu_out = alu_a ^ alu_b;
      ALU_SLL:  alu_out = alu_a << alu_b[4:0];
      ALU_SRL:  alu_out = alu_a >> alu_b[4:0];
      ALU_SRA:  alu_out = $signed(alu_a) >>> alu_b[4:0];
      ALU_SLT:  alu_out = $signed(alu_a) < $signed(alu_b);
      ALU_SLTU: alu_out = alu_a < alu_b;
      default:  alu_out = alu_b;  // COPY (for LUI, JALR, etc.)
    endcase
  end

  // ========================================================================
  //  Branch / Jump
  // ========================================================================
  logic branch_taken;
  always_comb begin
    branch_taken = 1'b0;
    if (ctrl.branch inside {BR_EQ,BR_NE,BR_LT,BR_GE,BR_LTU,BR_GEU}) begin
      case (ctrl.branch)
        BR_EQ:  branch_taken = (rs1_data == rs2_data);
        BR_NE:  branch_taken = (rs1_data != rs2_data);
        BR_LT:  branch_taken = $signed(rs1_data) < $signed(rs2_data);
        BR_GE:  branch_taken = $signed(rs1_data) >= $signed(rs2_data);
        BR_LTU: branch_taken = rs1_data < rs2_data;
        BR_GEU: branch_taken = rs1_data >= rs2_data;
        BR_ALWAYS: branch_taken = 1'b1;
        default: ;
      endcase
    end
  end

  logic [31:0] branch_target = pc + imm;
  logic [31:0] jalr_target   = (rs1_data + imm) & ~32'b1;

  assign pc_next = ctrl.link          ? pc_plus4 :
                   branch_taken       ? branch_target :
                   (ctrl.branch==BR_ALWAYS) ? jalr_target :
                   pc_plus4;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) pc <= BOOT_ADDR;
    else        pc <= pc_next;

  // ========================================================================
  //  Load/Store Unit
  // ========================================================================
  logic [31:0] addr = rs1_data + imm;
  logic [31:0] load_data_raw, load_data;

  `include "/home/nvzheit/projects/rv32imac/hdl/output/rv32imac_ls.svh"

  assign dmem_addr  = mem_addr;
  assign dmem_wdata = mem_wdata;
  assign dmem_be    = mem_be;
  assign dmem_req   = (mem_op inside {MEM_LOAD,MEM_STORE});
  assign dmem_we    = mem_write;

  always_ff @(posedge clk)
    if (dmem_valid) load_data_raw <= dmem_rdata;

  // ========================================================================
  //  CSR + M-extension result mux
  // ========================================================================
  logic [31:0] csr_rdata;
  logic        csr_illegal;
  logic        retired = dmem_valid || !dmem_req;  // simple single-cycle assumption

  csr_file u_csr (
    .clk, .rst_n, .ctrl, .rs1_data,
    .pc, .retired,
    .csr_rdata, .csr_illegal
  );

  logic [31:0] muldiv_result;
  `include "/home/nvzheit/projects/rv32imac/hdl/output/rv32imac_muldiv.svh"  // you can leave your mul/div unit empty for now

  // ========================================================================
  //  Writeback mux
  // ========================================================================
  logic [31:0] wb_data;
  always_comb begin
    wb_data = alu_out;
    if (ctrl.mem_op == MEM_LOAD) wb_data = load_data;
    if (ctrl.csr_read)           wb_data = csr_rdata;
    if (ctrl.mul_valid || ctrl.div_valid) wb_data = muldiv_result;
    if (ctrl.link)               wb_data = pc_plus4;
  end

  // ========================================================================
  //  Illegal / Exception (simple for single-cycle)
  // ========================================================================
  logic illegal = ctrl.illegal || illegal_c || csr_illegal || lsu_illegal;

endmodule
