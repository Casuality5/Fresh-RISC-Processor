Fresh-RISC-Processor
A 5-stage pipelined RV32I processor implementation with automated reference-model verification.

Architectural Implementation
The core implements a classic 5-stage decoupled pipeline (IF, ID, EX, MEM, WB) designed for the RISC-V RV32I ISA.

Instruction Support: Executes all Base Integer instructions.

Exclusions: Currently excludes Environment Calls (ECALL, EBREAK) and Control/Status Register (CSR) instructions.

Hardware Design: Developed in SystemVerilog with a focus on modular stage separation and registered boundaries to ensure timing closure.

Automated Verification Environment
A significant portion of this project focuses on a robust Verification IP (VIP) using a "Golden Reference" comparison strategy.

Reference Model Integration
Golden Reference: Utilizing SPIKE (the official RISC-V ISA simulator) to generate architectural golden traces.

DUT Trace: Extracting cycle-accurate retirement traces from the SystemVerilog implementation in Vivado.

Custom Python Verification Wrapper
To ensure high-confidence verification, a custom Python-based automation framework was developed to bridge the hardware and software domains:

Toolchain Automation: Leverages the riscv-gcc-toolchain to compile assembly/C source into ELF files.

Binary Processing: Extracts machine code from ELFs to dynamically generate the program.mem file for Vivado.

Simulation Control: Automates the Vivado simulator (xsim) to run the RTL against the generated binary.

Lockstep Comparison: Performs an automated post-simulation comparison between the SPIKE architectural state and the RTL retirement trace to verify functional correctness.
