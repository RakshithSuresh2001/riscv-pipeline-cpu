`default_nettype none

// Buggy hazard unit: missing ex_mem_read check in stall logic
// Bug: stalls on ANY EX-stage register match, not just load-use hazards
module hazard_bug (
    input wire [4:0]  id_rs1_addr,
    input wire [4:0]  id_rs2_addr,
    input wire [4:0]  ex_rd_addr,
    input wire        ex_mem_read,
    input wire [4:0]  ex_mem_rd_addr,
    input wire        ex_mem_reg_write,
    input wire [4:0]  mem_wb_rd_addr,
    input wire        mem_wb_reg_write,
    output wire       stall,
    output wire [1:0] fwd_sel_rs1,
    output wire [1:0] fwd_sel_rs2
);
    // BUG: ex_mem_read not checked — stalls on any EX hazard
    assign stall = (ex_rd_addr != 5'b0) &&
                   ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr));

    assign fwd_sel_rs1 = (ex_mem_reg_write && ex_mem_rd_addr != 5'b0 && ex_mem_rd_addr == id_rs1_addr) ? 2'b10 :
                         (mem_wb_reg_write && mem_wb_rd_addr != 5'b0 && mem_wb_rd_addr == id_rs1_addr) ? 2'b01 : 2'b00;
    assign fwd_sel_rs2 = (ex_mem_reg_write && ex_mem_rd_addr != 5'b0 && ex_mem_rd_addr == id_rs2_addr) ? 2'b10 :
                         (mem_wb_reg_write && mem_wb_rd_addr != 5'b0 && mem_wb_rd_addr == id_rs2_addr) ? 2'b01 : 2'b00;
endmodule

module hazard_bug_formal (
    input wire        clk,
    input wire [4:0]  id_rs1_addr,
    input wire [4:0]  id_rs2_addr,
    input wire [4:0]  ex_rd_addr,
    input wire        ex_mem_read,
    input wire [4:0]  ex_mem_rd_addr,
    input wire        ex_mem_reg_write,
    input wire [4:0]  mem_wb_rd_addr,
    input wire        mem_wb_reg_write
);
    wire       stall;
    wire [1:0] fwd_sel_rs1;
    wire [1:0] fwd_sel_rs2;

    hazard_bug dut (
        .id_rs1_addr     (id_rs1_addr),
        .id_rs2_addr     (id_rs2_addr),
        .ex_rd_addr      (ex_rd_addr),
        .ex_mem_read     (ex_mem_read),
        .ex_mem_rd_addr  (ex_mem_rd_addr),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd_addr  (mem_wb_rd_addr),
        .mem_wb_reg_write(mem_wb_reg_write),
        .stall           (stall),
        .fwd_sel_rs1     (fwd_sel_rs1),
        .fwd_sel_rs2     (fwd_sel_rs2)
    );

    // Property: stall must only fire on a load-use hazard
    // Formal will find a counterexample: rs1==ex_rd but ex_mem_read=0
    always @(*) begin
        a_stall_only_on_load_use: assert (stall ? ex_mem_read : 1'b1);
    end
endmodule
`default_nettype wire
