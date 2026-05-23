// RV32I Pipeline Testbench - Expanded
`timescale 1ns/1ps
`default_nettype none
module tb_cpu;
    reg clk, rst_n;
    reg [31:0] imem [0:255];
    reg [31:0] dmem [0:255];
    wire [31:0] imem_addr, dmem_addr, dmem_wdata;
    wire        dmem_wr_en;

    cpu_top dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .imem_addr (imem_addr),
        .imem_data (imem[imem_addr[9:2]]),
        .dmem_addr (dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_wr_en(dmem_wr_en),
        .dmem_rdata(dmem[dmem_addr[9:2]])
    );

    always_ff @(posedge clk) begin
        if (dmem_wr_en) dmem[dmem_addr[9:2]] <= dmem_wdata;
    end

    always #5 clk = ~clk;

    integer pass, fail;

    `define CHECK(label, got, exp) \
        if ((got) === (exp)) begin \
            $display("  PASS %s = %0d", label, got); pass = pass + 1; \
        end else begin \
            $display("  FAIL %s got=%0d exp=%0d", label, got, exp); fail = fail + 1; \
        end

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_cpu);
// Co-sim commit log
clk  = 0;
        pass = 0;
        fail = 0;

        // Group 1: Basic ALU
        imem[ 0] = 32'h00500093; // addi x1, x0, 5
        imem[ 1] = 32'h00300113; // addi x2, x0, 3
        imem[ 2] = 32'h002081b3; // add  x3, x1, x2  -> 8
        imem[ 3] = 32'h40208233; // sub  x4, x1, x2  -> 2
        imem[ 4] = 32'h0020f2b3; // and  x5, x1, x2  -> 1
        imem[ 5] = 32'h0020e333; // or   x6, x1, x2  -> 7
        imem[ 6] = 32'h0020c3b3; // xor  x7, x1, x2  -> 6
        // Group 2: RAW chain
        imem[ 7] = 32'h00100613; // addi x12, x0, 1
        imem[ 8] = 32'h00260613; // addi x12, x12, 2
        imem[ 9] = 32'h00360613; // addi x12, x12, 3
        imem[10] = 32'h00460613; // addi x12, x12, 4  -> 10
        // Group 3: Load-use
        imem[11] = 32'h00700693; // addi x13, x0, 7
        imem[12] = 32'h00d02023; // sw   x13, 0(x0)
        imem[13] = 32'h00002703; // lw   x14, 0(x0)  -> 7
        imem[14] = 32'h00170793; // addi x15, x14, 1 -> 8
        // Group 4: Shifts
        imem[15] = 32'h00100813; // addi x16, x0, 1
        imem[15] = 32'h00100813; // addi x16, x0, 1
        imem[16] = 32'h00281893; // slli x17, x16, 2 -> 4
        imem[17] = 32'h0018d913; // srli x18, x17, 1 -> 2
        imem[18] = 32'hff800993; // addi x19, x0, -8
        imem[19] = 32'h4019da13; // srai x20, x19, 1 -> -4
        // Group 5: SLT
        imem[20] = 32'h0020aab3; // slt  x21, x1, x2  -> 0
        imem[21] = 32'h00112b33; // slt  x22, x2, x1  -> 1
        // Group 6: Branch not-taken
        imem[22] = 32'h00500b93; // addi x23, x0, 5
        imem[23] = 32'h00500c13; // addi x24, x0, 5
        imem[24] = 32'h018b9463; // bne  x23, x24, +8 -> NOT taken
        imem[25] = 32'h00100c93; // addi x25, x0, 1   -> executes
        imem[26] = 32'h00000013; // nop
        imem[27] = 32'h00000013; // nop
        // Group 7: JAL
        imem[28] = 32'h00c00e6f; // jal x28, +12 -> jump to imem[31]
        imem[29] = 32'h06300d13; // addi x26, x0, 99  -> skipped
        imem[30] = 32'h06300d13; // addi x26, x0, 99  -> skipped
        imem[31] = 32'h02a00d93; // addi x27, x0, 42  -> executes
        imem[32] = 32'h00000013; // nop
        imem[33] = 32'h00000013; // nop
        imem[34] = 32'h00000013; // nop
        imem[35] = 32'h00000013; // nop
        imem[36] = 32'h00000013; // nop

        rst_n = 0;
        repeat(2)   @(posedge clk);
        rst_n = 1;
        repeat(120) @(posedge clk);

        $display("\n=== RV32I Pipeline Test Results ===");

        $display("\n-- Group 1: Basic ALU --");
        `CHECK("x1 (addi 5)",   dut.u_regfile.regs[1],  5)  // note: JAL may overwrite
        `CHECK("x2 (addi 3)",   dut.u_regfile.regs[2],  3)
        `CHECK("x3 (add)",      dut.u_regfile.regs[3],  8)
        `CHECK("x4 (sub)",      dut.u_regfile.regs[4],  2)
        `CHECK("x5 (and)",      dut.u_regfile.regs[5],  1)
        `CHECK("x6 (or)",       dut.u_regfile.regs[6],  7)
        `CHECK("x7 (xor)",      dut.u_regfile.regs[7],  6)

        $display("\n-- Group 2: RAW Hazard Chain --");
        `CHECK("x12 (1+2+3+4)", dut.u_regfile.regs[12], 10)

        $display("\n-- Group 3: Load-Use Hazard --");
        `CHECK("x13 (addi 7)",  dut.u_regfile.regs[13], 7)
        `CHECK("x14 (lw)",      dut.u_regfile.regs[14], 7)
        `CHECK("x15 (load-use)",dut.u_regfile.regs[15], 8)

        $display("\n-- Group 4: Shifts --");
        `CHECK("x16 (addi 1)",  dut.u_regfile.regs[16], 1)
        `CHECK("x17 (sll 1<<2)",dut.u_regfile.regs[17], 4)
        `CHECK("x18 (srl 4>>1)",dut.u_regfile.regs[18], 2)
        `CHECK("x19 (addi -8)", dut.u_regfile.regs[19], 32'hfffffff8)
        `CHECK("x20 (sra -8>>1)",dut.u_regfile.regs[20],32'hfffffffc)

        $display("\n-- Group 5: SLT --");
        `CHECK("x21 (5<3=0)",   dut.u_regfile.regs[21], 0)
        `CHECK("x22 (3<5=1)",   dut.u_regfile.regs[22], 1)

        $display("\n-- Group 6: Branch Not-Taken --");
        `CHECK("x25 (fall-thru)",dut.u_regfile.regs[25], 1)

        $display("\n-- Group 7: JAL --");
        `CHECK("x26 (skipped)", dut.u_regfile.regs[26], 0)
        `CHECK("x28 (jal ra)", dut.u_regfile.regs[28], 32'h74)
        `CHECK("x27 (post-jal)",dut.u_regfile.regs[27], 42)

        $display("\n=== Total: %0d PASS, %0d FAIL ===\n", pass, fail);
        $finish;
    end
    // Co-sim commit log
    initial begin
        forever @(posedge clk)
            if (dut.u_regfile.wr_en && dut.u_regfile.rd_addr != 0)
                $display("RTL rd=x%0d val=0x%08x",
                    dut.u_regfile.rd_addr,
                    dut.u_regfile.rd_data);
    end
endmodule
`default_nettype wire
