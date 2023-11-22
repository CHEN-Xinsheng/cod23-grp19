`define TYPE_R 3'd1
`define TYPE_I 3'd2
`define TYPE_S 3'd3
`define TYPE_B 3'd4
`define TYPE_U 3'd5
`define TYPE_J 3'd6

module EXE (
    input wire clk,
    input wire rst,
    input wire [31:0] rf_rdata_a_i,
    input wire [31:0] rf_rdata_b_i,
    input wire [31:0] inst_i,
    input wire [2:0] imm_type_i,
    input wire use_rs2_i,

    output reg [31:0] alu_a_o,
    output reg [31:0] alu_b_o,
    input wire [31:0] alu_y_i,
    output reg [31:0] alu_result_o,

    input wire mem_en_i,
    output reg mem_en_o,
    input wire rf_wen_i,
    output reg rf_wen_o,
    input wire [4:0] rf_waddr_i,
    output reg [4:0] rf_waddr_o,
    input wire mem_we_i,
    output reg mem_we_o,
    input wire [3:0] mem_sel_i,
    output reg [3:0] mem_sel_o,
    output reg [31:0] mem_dat_o_o,
    input wire [31:0] pc_now_i,
    output reg [31:0] pc_next_o,
    output reg branch_comb,
    input wire stall_i,
    input wire bubble_i
);

    always_comb begin
        if (imm_type_i == `TYPE_B) begin
            alu_a_o = pc_now_i;
            alu_b_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
        end
        else begin
            alu_a_o = rf_rdata_a_i;
            if (use_rs2_i) begin
                alu_b_o = rf_rdata_b_i;
            end else begin
                case(imm_type_i) 
                    `TYPE_I:alu_b_o = {{20{inst_i[31]}}, inst_i[31:20]};
                    `TYPE_S:alu_b_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                    `TYPE_U:alu_b_o = {inst_i[31:12], 12'b0};
                    default: alu_b_o = 32'b0;
                endcase
            end
        end
    end

    always_comb begin
        if (imm_type_i == `TYPE_B && rf_rdata_a_i == rf_rdata_b_i) begin
            branch_comb = 1;
            pc_next_o = alu_y_i;
        end else begin
            branch_comb = 0;
            pc_next_o = 32'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            alu_result_o <= 32'b0;
            mem_en_o <= 0;
            rf_wen_o <= 0;
            rf_waddr_o <= 5'b0;
            mem_we_o <= 0;
            mem_sel_o <= 4'b0;
            mem_dat_o_o <= 32'b0;
        end else if (stall_i) begin
        end else if (bubble_i) begin
            alu_result_o <= 32'b0;
            mem_en_o <= 0;
            rf_wen_o <= 0;
            rf_waddr_o <= 5'b0;
            mem_we_o <= 0;
            mem_sel_o <= 4'b0;
            mem_dat_o_o <= 32'b0;
        end else begin
            if (imm_type_i == `TYPE_B && rf_rdata_a_i == rf_rdata_b_i) begin
                mem_en_o <= 0;
                rf_wen_o <= 0;
            end else begin
                alu_result_o <= alu_y_i;
                mem_en_o <= mem_en_i;
                rf_wen_o <= rf_wen_i;
                rf_waddr_o <= rf_waddr_i;
                mem_we_o <= mem_we_i;
                mem_sel_o <= mem_sel_i;
                mem_dat_o_o <= rf_rdata_b_i;
            end
        end
    end

endmodule