# SEC-V – The Secure RISC-V Processor

**SEC-V** is an open-source, modular, and extensible RISC-V processor that integrates research-driven security with practical embedded design. It targets efficient, multithreaded, and secure execution for modern embedded systems.

## Core Design Objectives

- **Security-first architecture**
- **Modular and extensible design**
- **Ease of testing and verification**
- **Developer-friendliness**
- **Interleaved multithreading (IMT) for RTOS**
- **64-bit RV64I instruction set**

---

## Security Classification

### Memory Safety
- **Memory Tagging** *(in development)*: Supports thread-safe, word-level memory management  
- **Shadow Stack** *(via Control Flow Integrity)*: Protects return addresses against stack manipulation  
- **Physical Memory Protection (PMP)**: Enforces memory region isolation  
- **SCADS (Separated Code and Data Stack)**: Isolates control and data paths to limit code injection  

### Side-Channel Security
- **Cache Address Permutation** *(probabilistic)*: Obfuscates memory access patterns to resist cache attacks  
- **Instruction / Code Permutation**: Randomizes execution layout to thwart analysis  
- **Structural Permutation**: Randomizes hardware layout to increase unpredictability  
- **Configurable Interleaved Multithreading (CIMT)**: Mitigates timing-based side channels by design  

### Cryptography
- **Hardware Offloaded Crypto/Hash Functions**: Enhances secure computation and key management  
- **Key-Hiding Techniques**: Prevents key exposure at hardware level  
- **PUF-Based Device Attestation** *(research)*: Uses physically unclonable functions for identity/authentication  
- **Anti-Trojan Detection via PUFs** *(research)*: Detects hardware tampering and embedded threats  

---

## Architecture & ISA Highlights

- 4-stage pipeline (Harvard architecture)  
- RV64I ISA (planned extensions: CSR, B, C, M, D)  
- Wishbone-compatible RAM and ROM units  
- Upcoming: UART and GPIO SoC peripherals  

---

## Verification / Testing

- Open-source testbenches using [SVUT](https://github.com/dpretet/svut) (for Icarus/Verilator)  
- Additional support via [SVUnit](https://github.com/svunit/svunit) for commercial simulators

## Overview
                          ┌──────────────────────┐
                          │      rom_wb          │
                          │  Instruction Memory  │
                          │     (Wishbone)       │
                          └─────────┬────────────┘
                                    │ instr
                                    ▼
┌──────────────────────────────────────────────────────────┐
│                         secv.sv                          │
│              Top-Level CPU + FSM-Steuerung               │
│                                                          │
│  ┌──────────────┐                                        │
│  │  Fetch / PC  │◄───────────────┐                       │
│  │  pc, pc_next │                │ pc_sel                │
│  └──────┬───────┘                │                       │
│         │ instr                  │                       │
│         ▼                        │                       │
│  ┌──────────────┐                │                       │
│  │   decoder    │                │                       │
│  │ opcode/funct │                │                       │
│  │ src/imm/mux  │                │                       │
│  └──────┬───────┘                │                       │
│         │ rs1/rs2/rd             │                       │
│         ▼                        │                       │
│  ┌──────────────┐                │                       │
│  │     gpr      │                │                       │
│  │  x0…x31 RF   │                │                       │
│  └──────┬───────┘                │                       │
│         │ rs1/rs2                │                       │
│         ▼                        │                       │
│  ┌───────────────────────────────────────────────┐       │
│  │          Operand / Immediate MUXes            │       │
│  │ src1_sel, src2_sel, imm_sel                   │       │
│  └──────────────┬────────────────────────────────┘       │
│                 │ funit_in (src1, src2, op)              │
│                 ▼                                        │
│      ┌───────────────────────────────────────────┐       │
│      │          Function Unit Bus                │       │
│      │         (selected by funit)               │       │
│      └───────┬───────────┬───────────┬───────────┘       │
│              │           │           │                   │
│              ▼           ▼           ▼                   │
│        ┌────────┐  ┌────────┐  ┌────────┐                │
│        │  ALU   │  │ Branch │  │  MEM   │                │
│        │        │  │ Compare│  │ Load/  │                │
│        │ alu.sv │  │branch  │  │ Store  │                │
│        └────┬───┘  └────┬───┘  └────┬───┘                │
│             │           │           │                    │
│   alu_core  │           │           │ Wishbone           │
│             │           │           ▼                    │
│             │           │     ┌──────────────┐           │
│             │           │     │   ram_wb     │           │
│             │           │     │ Data Memory  │           │
│             │           │     │  (Wishbone)  │           │
│             │           │     └──────────────┘           │
│             │           │                                │
│             └───────────┴──────────┐                     │
│                        funit_out   │                     │
│                        (res, rdy)  │                     │
│                                    ▼                     │
│                         ┌────────────────┐               │
│                         │ Writeback MUX  │               │
│                         │ rd_sel         │               │
│                         └──────┬─────────┘               │
│                                │ rd_dat                  │
│                                ▼                         │
│                              gpr                         │
│                                                          │
│  ┌───────────────────────────────────────────────────┐   │
│  │                 CSR Subsystem                     │   │
│  │ csr.sv + csr_regs.sv                              │   │
│  │ - CSR read/write                                  │   │
│  │ - Exception aggregation                           │   │
│  │ - PMP / Trap preparation (partially wired)        │   │
│  └───────────────────────────────────────────────────┘   │
│                                                          │
└──────────────────────────────────────────────────────────┘

