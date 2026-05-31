`default_nettype none

module hazard_formal (
    input wire        clk,
    input wire        rst,
    input wire [4:0]  id_rs1_addr,
    input wire [4:0]  id_rs2_addr,
    input wire [4:0]  ex_rd_addr,
    input wire        ex_mem_read,
    input wire [4:0]  ex_mem_rd_addr,
    input wire        ex_mem_reg_write,
    input wire [4:0]  mem_wb_rd_addr,
    input wire        mem_wb_reg_write
);

    wire        stall;
    wire [1:0]  fwd_sel_rs1;
    wire [1:0]  fwd_sel_rs2;

    hazard dut (
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

    always @(*) begin
        // Property 1: forwarding never selects from x0
        if (fwd_sel_rs1 != 2'b00) a_no_fwd_x0_rs1: assert (id_rs1_addr != 5'b0);
        if (fwd_sel_rs2 != 2'b00) a_no_fwd_x0_rs2: assert (id_rs2_addr != 5'b0);

        // Property 2: EX/MEM forward only fires when reg_write is set
        if (fwd_sel_rs1 == 2'b10) a_exmem_fwd_rs1_valid: assert (ex_mem_reg_write);
        if (fwd_sel_rs2 == 2'b10) a_exmem_fwd_rs2_valid: assert (ex_mem_reg_write);

        // Property 3: MEM/WB forward only fires when reg_write is set
        if (fwd_sel_rs1 == 2'b01) a_memwb_fwd_rs1_valid: assert (mem_wb_reg_write);
        if (fwd_sel_rs2 == 2'b01) a_memwb_fwd_rs2_valid: assert (mem_wb_reg_write);

        // Property 4: stall only fires on load-use hazard
        if (stall) a_stall_only_on_load_use: assert (ex_mem_read);

        // Property 5: no forwarding when rd is x0
        if (fwd_sel_rs1 == 2'b10) a_no_fwd_to_x0_exmem: assert (ex_mem_rd_addr != 5'b0);
        if (fwd_sel_rs1 == 2'b01) a_no_fwd_to_x0_memwb: assert (mem_wb_rd_addr != 5'b0);
    end

endmodule
`default_nettype wire
