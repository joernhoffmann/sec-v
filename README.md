# SEC-V - The Secure RISC-V Processor

## 1. Description

The SEC-V processor is an open-source collaboration focused on creating an advanced RISC-V embedded processor. It merges research-driven methodologies with practical, commercial-grade features.

The project repository contains comprehensive resources, including the SystemVerilog processor description, testbenches, programs, utility scripts, and documentation.

### 1.1 Design Goals

The core design principles guiding the SEC-V processor project include:

1. Security: Prioritizing robust security measures
2. Modularity / Extensibility: Supporting easy expansion and customization
3. Testability: Ensuring straightforward verification and validation
4. Ease of Understanding: Striving for developer-friendliness
5. Efficiency: Optimizing performance
6. Multi-Threading: Enabling concurrent processing for real time operating systems (RTOS)

## 2. Features

The SEC-V processor currently boasts the following features:

### 2.1 Architecture

- A 4-stage processor cycle (with ongoing pipeline development)
- Harvard architecture
- Wishbone-compliant instruction and data memory interfaces
- A versatile, expandable function unit interface

### 2.2 ISA

- Implementation of the RV64I instruction set

Currently, the processor supports the RV64I (integer) instruction set. This choice of the 64-bit variant allows for advanced security features like memory tagging, accommodates large address spaces (beneficial for DMA controllers), and enhances performance in data-intensive tasks (beneficial for network controllers and cryptographic functions).

### 2.3 SoC Units

- Wishbone-compatible ROM and RAM units

### 2.4 Testing

- Robust test benches
- Well-crafted test programs

Test benches are implemented using [SVUT](https://github.com/dpretet/svut) (SystemVerilog Unit Tests), compatible with [iverilog](https://github.com/steveicarus/iverilog) and optionally [Verilator](https://www.veripool.org/verilator/). Additionally, there are testbenches in [SVUnit](https://github.com/svunit/svunit), designed to run on major commercial simulators and Verilator.

The SVUT test benches are favor for their simulation speed and open-source compatibility with iverilog.

## 3. Roadmap

The SEC-V project has a roadmap that outlines future developments:

### 3.1 Security Features

The project plans to introduce various security functions:

#### 3.1.1 Deterministic

1. Memory tagging (*research*):
   - Supporting threading with word granularity
2. Code-injected device attestation (*research*):
   - Implementing challenge-response methods with PUF-based techniques
3. Anti-trojan detection (*research*):
   - Utilizing Physically Unclonable Functions (PUF)
4. Physical memory protection (PMP)
   - PMP-Device that isolates memory regions
6. Separation of code and data stack (SCADS)
7. Support for control flow integrity (CFI)
   - Forward-edge and backward-edge (return) CFI
9. Implementation of cryptographic and hash functions
   - Offloading purpose
   - Key-hiding

#### 3.1.2 Probabilistic

1. Instruction / code permutation
2. Structural permutation
3. Cache address permutation

### 3.2 Architecture

Future architectural improvements include:

1. Control and status register support (CSR):
   - Efficiently managing interrupts, exceptions, and more
2. Configurable interleaved multi-threading (CIMT):
   - Extending interleaved multi-threading with configurable thread counts (1 to n) and a 4-stage pipeline
3. Cache controller
4. Power management controller

### 3.3 ISA Extensions

These ISA extensions will enhance versatility:

1. CSR   : Control and status register
2. B     : Bit manipulations (for enhanced efficiency)
3. C     : Compressed instructions (memory efficiency)
4. M     : Integer multiplication (for improved performance)
5. D     : Division (for better performance)

### 3.4 SoC Units

Expanding SoC units to meet diverse requirements:

1. UART (Universal Asynchronous Receiver-Transmitter)
2. GPIO Port (General-Purpose Input/Output Port)

The SEC-V project continues to evolve, aiming to deliver a secure and efficient RISC-V processor suitable for modern embedded systems.


### 4. Code impression

[mem_decoder.sv](hdl/mem_decoder.sv)
```verilog
`include "secv_pkg.svh"
import secv_pkg::*;

module branch #(
    parameter int XLEN = secv_pkg::XLEN
) (
    input   funct3_t        funct3_i,
    input   [XLEN-1 : 0]    rs1_i,
    input   [XLEN-1 : 0]    rs2_i,

    output  logic           take_o,
    output  logic           err_o
);

    logic take, err;
    always_comb begin
        take = 1'b0;
        err  = 1'b0;

        unique case (funct3_i)
            FUNCT3_BRANCH_BEQ   : take = (rs1_i          ==  rs2_i);
            FUNCT3_BRANCH_BNE   : take = (rs1_i          !=  rs2_i);
            FUNCT3_BRANCH_BLT   : take = ($signed(rs1_i) <   $signed(rs2_i));
            FUNCT3_BRANCH_BGE   : take = ($signed(rs1_i) >=  $signed(rs2_i));
            FUNCT3_BRANCH_BLTU  : take = (rs1_i          <   rs2_i);
            FUNCT3_BRANCH_BGEU  : take = (rs1_i          >=  rs2_i);
            default:
                err = 1'b1;
        endcase
    end

    // Outputs
    assign take_o = take & !err;
    assign err_o  = err;
endmodule
