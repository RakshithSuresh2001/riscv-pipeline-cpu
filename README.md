# RV32I 5-Stage Pipelined CPU

A fully functional RV32I 5-stage in-order pipelined processor implemented in SystemVerilog, featuring full forwarding, load-use hazard detection, branch resolution, and a 2-bit saturating counter branch predictor. Validated against the Spike ISS with 27/27 directed tests passing and 11/11 instruction commits matching the golden reference.

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

**Data hazards** are resolved through full forwarding. The hazard unit compares source register addresses in ID against destination addresses in EX and MEM, selecting the most recent result via forwarding muxes in the EX stage. Load-use hazards insert a one-cycle stall bubble since the result is not available until after MEM.

**Control hazards** are handled by the 2-bit saturating branch history table (BHT). The BHT predicts taken/not-taken at fetch time. If the prediction is wrong, the pipeline flushes the incorrectly fetched instructions and redirects to the correct PC.

## Verification

### Directed Tests (Verilator)

27 directed tests covering all major hazard and instruction categories:

| Category | Tests | Status |
|----------|-------|--------|
| RAW forwarding chains | 6 | Pass |
| Load-use stalls | 4 | Pass |
| Branch taken/not-taken | 5 | Pass |
| JAL and JALR | 3 | Pass |
| SLT/SLTU/shifts | 4 | Pass |
| Mixed hazard sequences | 5 | Pass |

### Spike ISS Co-simulation

Integrated Spike RISC-V ISS co-simulation to compare instruction-by-instruction commit logs. The RTL and Spike golden reference produce identical commit sequences across all 11 targeted hazard sequences, confirming correct forwarding, stall, and branch behavior.

```bash
make spike    # run co-simulation
make sim      # run directed tests only
```
### Simulator Portability Verification (VCS)

Recompiled and reran the directed test suite under Synopsys VCS X-2025.06 on a remote Linux server (USC EE department cluster), independent of the Verilator flow used for development.

<img width="612" height="640" alt="Screenshot 2026-06-29 114313" src="https://github.com/user-attachments/assets/634f33c9-5d74-4b36-9f6b-9b04502972d2" />

Result: 26/27 PASS.

The one discrepancy (x26 (skipped)) is a simulator initialization difference, not a CPU bug. x26 is intentionally never written in this test program (the JAL test confirms the jump correctly skips over instructions targeting it), so the check expects it to remain at its reset value of 0. regfile.sv has no explicit reset or initial block clearing the register array, so an unwritten register's value at time zero is implementation-defined: Verilator defaults uninitialized registers to 0, while VCS defaults them to X (unknown), per standard simulator behavior for declared-but-unset 4-state variables.

All 26 other checks, covering ALU operations, RAW hazard forwarding, load-use stall detection, shifts, SLT/SLTU, branches (taken and not-taken), JAL, and LUI, passed identically across both simulators, confirming the pipeline's functional logic itself is simulator-independent. The single discrepancy is a register file reset gap exposed by cross-simulator testing, exactly the kind of issue that staying on one open-source simulator can hide indefinitely.

## Formal Verification

The hazard unit was formally verified using SymbiYosys with Z3 as the SMT solver backend. Two runs were performed: one proving correctness of the real implementation, and one finding a counterexample in a deliberately buggy variant to demonstrate bug-finding capability.

### Results

| Run | Target | Result | Depth |
|-----|--------|--------|-------|
| `hazard.sby` | Correct hazard unit | **PASS** | 20 steps |
| `hazard_bug.sby` | Buggy hazard unit | **FAIL** | 0 steps |

<img width="949" height="323" alt="Screenshot 2026-06-04 234809" src="https://github.com/user-attachments/assets/70b5257a-9318-4967-abac-be351041016f" />

### Properties Proven

Five assertions hold for all input combinations across 20 BMC steps:

1. Forwarding never selects a source register of x0
2. EX/MEM forwarding only fires when reg_write is set in the EX stage
3. MEM/WB forwarding only fires when reg_write is set in the MEM stage
4. The pipeline stall only asserts on a load-use hazard (ex_mem_read must be high)
5. Forwarding never reads from a destination register of x0

### Counterexample Found

A buggy variant of the hazard unit was created with the `ex_mem_read` check removed from the stall logic:

```systemverilog
// Bug: stalls on any EX register match, not just load-use hazards
assign stall = (ex_rd_addr != 5'b0) &&
               ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr));
```

<img width="890" height="180" alt="Screenshot 2026-06-04 234627" src="https://github.com/user-attachments/assets/1b28dc92-9ab1-4e0d-ae45-774600aed97b" />


Formal found a counterexample at step 0: `ex_rd_addr = x1`, `id_rs1_addr = x1`, `ex_mem_read = 0`. The buggy unit incorrectly asserts `stall = 1` with no memory read in flight. The correct unit correctly asserts `stall = 0`. Counterexample trace is at `formal/hazard_bug/engine_0/trace.vcd`.

### Running the Proofs

```bash
cd formal
sby -f hazard.sby      # proves 5 properties on correct implementation
sby -f hazard_bug.sby  # finds counterexample on buggy variant
```

Requires SymbiYosys and Z3:

```bash
pip install symbiyosys
apt install z3
```

## Repository Structure

```
rtl/          SystemVerilog source files
tb/           Testbench and directed test cases
tests/        Assembly test programs
formal/       SymbiYosys formal verification
  hazard.sby          proof config for correct unit
  hazard_formal.sv    formal wrapper with SVA properties
  hazard_bug.sby      proof config for buggy unit
  hazard_bug.sv       buggy variant + formal wrapper
spike/        Spike co-simulation scripts
```

## Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Verilator | 5.020 | RTL simulation |
| Spike | 1.1.1-dev | ISS golden reference |
| SymbiYosys | latest | Formal verification frontend |
| Yosys | latest | Synthesis and SMT2 generation |
| Z3 | latest | SMT solver backend |

## Related Projects

- [uvm_systolic](https://github.com/RakshithSuresh2001/uvm_systolic): SystemVerilog UVM-style testbench for an 8x8 systolic array, 1337/1337 checks
- [PicoRISCV-SoC](https://github.com/RakshithSuresh2001/PicoRISCV-SoC): PicoRV32 core integrated with the systolic array, taped out on ASAP7 at 500 MHz
- [Systolic-Array](https://github.com/RakshithSuresh2001/Systolic-Array): Standalone systolic array submitted to ChipFoundry CI2609 Sky130 shuttle

## Author

Rakshith Suresh, MS Electrical Engineering, USC Viterbi School of Engineering
[GitHub](https://github.com/RakshithSuresh2001) | [LinkedIn](https://linkedin.com/in/rakshith-suresh-890329258/)
