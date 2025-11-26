package rv32_pkg;
  typedef enum logic [6:0] {
    ADD, 
    SUB, 
    SLL,
    SLT,
    SLTU,
    XOR,
    SRL,
    SRA,
    OR,
    AND,
    ADDI,
    SLTI,
    SLTU_I,
    XORI,
    ORI,
    ANDI,
    SLLI,
    SRLI_SRAI,
    LUI,
    AUIPC,
    JAL,
    JALR,
    BEQ,
    BNE,
    BLT,
    BGE,
    BLTU,
    BGEU,
    LB,
    LH,
    LW,
    LBU,
    LHU,
    SB,
    SH,
    SW,
    MUL,
    MULH,
    MULHSU,
    MULHU,
    DIV,
    DIVU,
    REM,
    REMU,
    LR_W,
    SC_W,
    AMOSWAP_W,
    /* ... other AMOs */
    CSRRW,
    CSRRS,
    CSRRC,
    ECALL_EBREAK,
    FENCE,
    FENCE_I,
  } op_t;

  typedef struct packed {
    logic       valid;
    logic [31:0] pc;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] imm;
    op_t        op;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic       use_muldiv;
    // ... add more as needed
  } decoded_t;

  localparam logic [6:0] OPCODE_LOAD     = 7'b00_000_11;
  localparam logic [6:0] OPCODE_STORE    = 7'b01_000_11;
  localparam logic [6:0] OPCODE_OP_IMM   = 7'b00_100_11;
  localparam logic [6:0] OPCODE_OP       = 7'b01_100_11;
  localparam logic [6:0] OPCODE_LUI      = 7'b01_101_11;
  localparam logic [6:0] OPCODE_AUIPC    = 7'b00_101_11;
  localparam logic [6:0] OPCODE_JAL      = 7'b11_011_11;
  localparam logic [6:0] OPCODE_JALR     = 7'b11_001_11;
  localparam logic [6:0] OPCODE_BRANCH   = 7'b11_000_11;
  localparam logic [6:0] OPCODE_SYSTEM   = 7'b11_100_11;
  localparam logic [6:0] OPCODE_AMO      = 7'b10_111_11;
endpackage
