package csr_pkg;
  typedef enum logic [11:0] {
    CSR_FFLAGS          = 12'h001 ,
    CSR_FRM             = 12'h002 ,
    CSR_FCSR            = 12'h003 ,
    CSR_CYCLE           = 12'hC00 ,
    CSR_TIME            = 12'hC01 ,
    CSR_INSTRET         = 12'hC02 ,
    CSR_CYCLEH          = 12'hC80 ,
    CSR_TIMEH           = 12'hC81 ,
    CSR_INSTRETH        = 12'hC82 ,
    CSR_MVENDORID       = 12'hF11 ,
    CSR_MARCHID         = 12'hF12 ,
    CSR_MIMPID          = 12'hF13 ,
    CSR_MHARTID         = 12'hF14 ,
    CSR_MSTATUS         = 12'h300 ,
    CSR_MISA            = 12'h301 ,
    CSR_MEDELEG         = 12'h302 ,
    CSR_MIDELEG         = 12'h303 ,
    CSR_MIE             = 12'h304 ,
    CSR_MTVEC           = 12'h305 ,
    CSR_MCOUNTEREN      = 12'h306 ,
    CSR_MSCRATCH        = 12'h340 ,
    CSR_MEPC            = 12'h341 ,
    CSR_MCAUSE          = 12'h342 ,
    CSR_MTVAL           = 12'h343 ,
    CSR_MIP             = 12'h344 ,
    CSR_MCYCLE          = 12'hB00 ,
    CSR_MINSTRET        = 12'hB02 ,
    CSR_NONE = 12'hFFF
  } csr_addr_t;
endpackage

