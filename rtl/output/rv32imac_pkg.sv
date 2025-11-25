package rv32imac_pkg;
  typedef enum logic [4:0] {
    ALU_ADD,  ALU_SUB,  ALU_AND, ALU_OR,  ALU_XOR,
    ALU_SLL,  ALU_SRL,  ALU_SRA, ALU_SLT, ALU_SLTU,
    ALU_COPY                                   // just pass operand
  } alu_op_t;

  typedef enum logic [1:0] { MEM_NONE, MEM_LOAD, MEM_STORE, MEM_FENCE } mem_op_t;
  typedef enum logic [1:0] { BYTE=0, HALF=1, WORD=2 } mem_width_t;
  typedef enum logic [1:0] { BR_NO, BR_EQ, BR_NE, BR_LT, BR_GE, BR_LTU, BR_GEU, BR_ALWAYS } branch_t;
endpackage
