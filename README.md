# RV32I 5-Stage Pipelined CPU

A fully functional RV32I 5-stage in-order pipelined processor implemented in SystemVerilog, featuring full forwarding, load-use hazard detection, branch resolution, and a 2-bit saturating counter branch predictor.

## Architecture

The pipeline has five stages:

```
IF → ID → EX → MEM → WB
```

| Stage | Module | Function |
|-------|--------|----------|
| Fetch (IF) | `fetch.sv` | PC sequencing, instruction fetch, branch prediction |
| Decode (ID) | `decode.sv` | Instruction decode, register file read, immediate generation |
| Execute (EX) | `execute.sv` | ALU, branch resolution, forwarding muxes |
| Memory (MEM) | `memory_stage.sv` | Data memory read/write |
| Writeback (WB) | `writeback.sv` | Register file write |

Supporting modules:

- `hazard.sv` — Load-use stall detection and EX/MEM + MEM/WB forwarding control
- `regfile.sv` — 32x32-bit register file with synchronous write, asynchronous read
- `bht.sv` — 2-bit saturating counter branch history table

## Hazard Handling

**Data hazards** are resolved through full forwarding. The hazard unit compares source register addresses in ID against destination addresses in EX and MEM, selecting the most recent result:

- EX/MEM forwarding (2-cycle RAW): priority over MEM/WB
- MEM/WB forwarding (3-cycle RAW): used when EX/MEM doesn't apply
- Load-use hazard: one-cycle stall inserted when a load is immediately followed by a dependent instruction

**Control hazards** are resolved in the EX stage. The branch predictor issues a prediction in IF; if the EX stage determines the prediction was wrong, the fetch and decode stages are flushed and the PC is redirected to the correct target.

## Supported Instructions

All RV32I base integer instructions are implemented:

| Category | Instructions |
|----------|-------------|
| Arithmetic | ADD, SUB, ADDI |
| Logical | AND, OR, XOR, ANDI, ORI, XORI |
| Shifts | SLL, SRL, SRA, SLLI, SRLI, SRAI |
| Compare | SLT, SLTU, SLTI, SLTIU |
| Upper immediate | LUI, AUIPC |
| Loads | LW, LH, LB, LHU, LBU |
| Stores | SW, SH, SB |
| Branches | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| Jumps | JAL, JALR |

## Test Results

27 directed tests covering all major instruction categories and hazard scenarios:

```
=== RV32I Pipeline Test Results ===

-- Group 1: Basic ALU --        7/7  PASS
-- Group 2: RAW Hazard Chain -- 1/1  PASS
-- Group 3: Load-Use Hazard --  3/3  PASS
-- Group 4: Shifts --           5/5  PASS
-- Group 5: SLT --              2/2  PASS
-- Group 6: Branch Not-Taken -- 1/1  PASS
-- Group 7: JAL --              3/3  PASS
-- Group 8: Branch Taken --     1/1  PASS
-- Group 9: LUI --              1/1  PASS
-- Group 10: SLTU --            2/2  PASS
-- Group 11: BLT Taken --       1/1  PASS

=== Total: 27 PASS, 0 FAIL ===
```

## Running the Simulation

Requires Verilator 5.020 or later.

```bash
make sim    # compile and run all tests
make clean  # remove build artifacts
```

## Tools

| Tool | Version |
|------|---------|
| Verilator | 5.020 |
| OS | Ubuntu 22.04 (WSL2) |
| HDL | SystemVerilog |
| ISA | RISC-V RV32I |

## Related Projects

- [PicoRISCV-SoC](https://github.com/RakshithSuresh2001/PicoRISCV-SoC): A PicoRV32 (RV32IM) SoC integrating an 8x8 systolic array accelerator, taped out on ASAP7 7nm using OpenROAD with 0 DRC violations
- [uvm-systolic](https://github.com/RakshithSuresh2001/uvm_systolic): A structured SystemVerilog testbench for the systolic array, 1,337 checks passing with full functional coverage

## Author

Rakshith Suresh, MS Electrical Engineering, USC Viterbi School of Engineering
[GitHub](https://github.com/RakshithSuresh2001) | [LinkedIn](https://linkedin.com/in/rakshith-suresh-890329258/)
