# RV32IMAC Core

A clean, readable, and synthesizable RV32IMAC RISC-V core written in SystemVerilog.

**Supported ISA**: `RV32IMAC` (RISC-V 32-bit base integer + Multiply/Div + Atomic + Compressed extensions)  
Fully compliant with the RISC-V Unprivileged and Privileged specifications (20191213 + RATIFIED extensions).

## Features

- RV32IMAC instruction set (I + M + A + C)
- Machine mode + optional User/Supervisor modes
- Sv32 virtual memory support (optional, configurable)
- Physical Memory Protection (PMP) – up to 16 regions
- Standard RISC-V CLINT / PLIC interrupt interface
- Optional instruction and data caches (or tightly-integrated memories)
- Simple 3–5 stage in-order pipeline (configurable)
- Full 16-bit compressed instruction support (C extension)
- Multi-cycle multiplier and early-out divider (M extension)
- Load-reserved / Store-conditional + AMO support (A extension)
- AXI4-Lite / AHB-Lite / TileLink-UncachedLite bus interface (selectable)
- RISC-V External Debug Support (v0.13.2) with JTAG DTM
- Written in clean, well-commented SystemVerilog (no vendor macros)

## Module Hierarchy

## Module Hierarchy

```text
Top-Level Core (e.g., Core, Processor, CPU)
├── Frontend (Instruction Fetch + Decode stages)
│   ├── IFU (Instruction Fetch Unit)
│   │   ├── PC Generation (PC + 4, branch/jump target, exception redirect)
│   │   ├── Branch Predictor (for C extension: especially important because of c.j, c.jal, c.beqz, c.bnez)
│   │   ├── Instruction Cache (I$ ) or ITIM (Instruction Tightly Integrated Memory)
│   │   └── Instruction TLB (ITLB)
│   ├── IBD (Instruction Buffer / Decoupled Buffer)
│   └── Decode Stage
│       ├── Full 32-bit decoder
│       ├── Compressed (16-bit) decoder (detects and expands C-extension instructions)
│       └── Illegal instruction detection
│
├── Backend (Execution stages)
│   ├── Issue / Dispatch Queue (in-order cores may skip this)
│   ├── Register File (31 x 32-bit GPRs + PC, CSR file is usually separate)
│   ├── Execution Lanes / ALUs (usually multiple parallel lanes)
│   │   ├── Integer ALU (RV32I + M extension mul/div)
│   │   │   ├── Fast adder
│   │   │   ├── Multi-cycle multiplier (usually 1–4 cycles for RV32M)
│   │   │   └── Divider (often iterative, 32-cycle or early-out)
│   │   ├── Load/Store Unit (LSU)
│   │   │   ├── Address Generation Unit (AGU)
│   │   │   ├── Data TLB (DTLB)
│   │   │   ├── Data Cache (D$) or DTIM
│   │   │   └── Atomic Reservation logic + AMO ALU (for A extension: lr.w, sc.w, amo*.w)
│   │   └── Branch Execution Unit (comparisons, actual target calculation)
│   │
│   ├── CSR File (Control and Status Registers)
│   │   ├── Standard CSRs (mstatus, mie, mtvec, mcause, etc.)
│   │   ├── Machine-level, Supervisor-level (if Sv32 supported), User-level
│   │   └── PMP (Physical Memory Protection) registers (common in embedded RV32)
│   │
│   └── Writeback Stage (writes results back to register file)
│
├── Memory System Interface
│   ├── Bus Interface Unit (BIU) – AXI4-Lite / AHB-Lite / TileLink / custom
│   ├── Uncached / Peripheral region handling
│   └── Debug / Trigger module interface
│
├── Interrupt & Exception Handling
│   ├── Interrupt controller interface (PLIC / CLINT / CLIC)
│   └── Exception priority and redirect logic
│
└── Optional Debug Module (RISC-V External Debug Support)
    └── Debug Transport Module (DTM) – usually JTAG or USB
```
