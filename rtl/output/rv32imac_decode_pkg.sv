//==============================================================================
// Auto-generated RV32IMAC decoder + control
//==============================================================================
`ifndef RV32IMAC_DECODE_SVH
`define RV32IMAC_DECODE_SVH

import rv32imac_pkg::*;

package rv32i_decode_pkg;
// Add your own typedefs here if needed
typedef struct packed {
  logic illegal;

  logic [4:0]  rd_addr;
  logic [4:0]  rs1_addr;
  logic [4:0]  rs2_addr;

  logic [2:0]  imm_type;  // 0=I,1=S,2=B,3=U,4=J
  alu_op_t     alu_op;

  mem_op_t     mem_op;
  mem_width_t  mem_width;
  logic        mem_unsigned;

  logic        wb_en;
  branch_t     branch;
  logic        link;

  logic        mul_valid;
  logic        div_valid;
} ctrl_t;

endpackage
`endif

