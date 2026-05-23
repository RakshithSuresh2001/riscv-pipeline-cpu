// EX Stage: ALU + Branch Resolution + Forwarding
`timescale 1ns/1ps
`default_nettype none

module execute (
    input  wire        clk,
    input  wire        rst_n,
    // From ID
    input  wire [31:0] pc_in,
    input  wire [31:0] rs1_in,
    input  wire [31:0] rs2_in,
    input  wire [31:0] imm_in,
    input  wire [4:0]  rs1_addr_in,
    input  wire [4:0]  rs2_addr_in,
    input  wire [4:0]  rd_addr_in,
    input  wire [3:0]  alu_op_in,
    input  wire        alu_src_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        reg_write_in,
    input  wire        branch_in,
    input  wire [2:0]  funct3_in,
    input  wire        jal_in,
    input  wire        predicted_taken_in,
    input  wire        mem_to_reg_in,
    // Forwarding inputs
    input  wire [31:0] fwd_ex_mem,   // EX/MEM forwarding
    input  wire [31:0] fwd_mem_wb,   // MEM/WB forwarding
    input  wire [1:0]  fwd_sel_rs1,
    input  wire [1:0]  fwd_sel_rs2,
    // Outputs
    output reg  [31:0] alu_result_out,
    output reg  [31:0] rs2_out,
    output reg  [4:0]  rd_addr_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         reg_write_out,
    output reg         mem_to_reg_out,
    output wire        branch_taken,
    output wire [31:0] branch_target,
    output wire [31:0] branch_fallthrough,
    output wire        mispredict
);

    // Forwarding mux
    wire [31:0] rs1_fwd = (fwd_sel_rs1 == 2'b10) ? fwd_ex_mem :
                          (fwd_sel_rs1 == 2'b01) ? fwd_mem_wb : rs1_in;
    wire [31:0] rs2_fwd = (fwd_sel_rs2 == 2'b10) ? fwd_ex_mem :
                          (fwd_sel_rs2 == 2'b01) ? fwd_mem_wb : rs2_in;

    wire [31:0] alu_b = alu_src_in ? imm_in : rs2_fwd;

    // ALU
    reg [31:0] alu_result;
    always_comb begin
        case (alu_op_in)
            4'd0:  alu_result = rs1_fwd + alu_b;                          // ADD
            4'd1:  alu_result = rs1_fwd - alu_b;                          // SUB
            4'd2:  alu_result = rs1_fwd & alu_b;                          // AND
            4'd3:  alu_result = rs1_fwd | alu_b;                          // OR
            4'd4:  alu_result = rs1_fwd ^ alu_b;                          // XOR
            4'd5:  alu_result = rs1_fwd << alu_b[4:0];                    // SLL
            4'd6:  alu_result = rs1_fwd >> alu_b[4:0];                    // SRL
            4'd7:  alu_result = $signed(rs1_fwd) >>> alu_b[4:0];          // SRA
            4'd8:  alu_result = ($signed(rs1_fwd) < $signed(alu_b)) ? 1 : 0; // SLT
            4'd9:  alu_result = (rs1_fwd < alu_b) ? 1 : 0;               // SLTU
            4'd10: alu_result = alu_b;                                     // LUI
            4'd11: alu_result = pc_in + alu_b;                            // AUIPC
            default: alu_result = 32'b0;
        endcase
    end

    // Branch resolution
    reg branch_cond;
    always_comb begin
        case (funct3_in)
            3'b000: branch_cond = (rs1_fwd == rs2_fwd);              // BEQ
            3'b001: branch_cond = (rs1_fwd != rs2_fwd);              // BNE
            3'b100: branch_cond = ($signed(rs1_fwd) < $signed(rs2_fwd)); // BLT
            3'b101: branch_cond = ($signed(rs1_fwd) >= $signed(rs2_fwd)); // BGE
            3'b110: branch_cond = (rs1_fwd < rs2_fwd);               // BLTU
            3'b111: branch_cond = (rs1_fwd >= rs2_fwd);              // BGEU
            default: branch_cond = 1'b0;
        endcase
    end
    assign branch_taken      = branch_in & (branch_cond | jal_in);
    assign branch_target     = pc_in + imm_in;
    assign branch_fallthrough = pc_in + 4;
    assign mispredict         = branch_in & ((branch_cond | jal_in) ^ predicted_taken_in);
    wire [31:0] alu_result_final = jal_in ? (pc_in + 4) : alu_result;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_out <= 32'b0;
            rs2_out        <= 32'b0;
            rd_addr_out    <= 5'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
        end else begin
            alu_result_out <= alu_result_final;
            rs2_out        <= rs2_fwd;
            rd_addr_out    <= rd_addr_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
        end
    end

endmodule
`default_nettype wire
