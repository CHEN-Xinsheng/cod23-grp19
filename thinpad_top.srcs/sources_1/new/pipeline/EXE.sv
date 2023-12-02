`include "../header.sv"
module EXE (
    input wire clk,
    input wire rst,
    input wire [31:0] rf_raddr_a_i,
    input wire [31:0] rf_raddr_b_i,
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
    input wire use_pc_i,
    input wire comp_op_i,
    input wire [2:0] csr_op_i,
    input wire jump_i,
    output reg branch_comb_o,
    input wire stall_i,
    input wire bubble_i,

    output reg  [11:0] csr_raddr_o,
    input wire  [31:0] csr_rdata_i,
    output reg  [11:0] csr_waddr_o,
    output reg  [31:0] csr_wdata_o,
    output reg  csr_we_o,

    // data forwarding
    input wire [4:0] exe_mem_rf_waddr_i,
    input wire [31:0] exe_mem_alu_result_i
);

    always_comb begin
        csr_raddr_o = inst_i[31:20];
        csr_waddr_o = inst_i[31:20];
        if (csr_op_i == 3'b001) begin   // CSRRW
            csr_wdata_o = rf_rdata_a_i;
            if (alu_y_i != 0) begin
                csr_we_o = 1'b1;
            end else begin
                csr_we_o = 1'b0;
            end
        end else if (csr_op_i == 3'b010) begin   // CSRRS
            csr_wdata_o = csr_rdata_i | rf_rdata_a_i;
            csr_we_o = 1'b1;
        end else if (csr_op_i == 3'b011) begin   // CSRRC
            csr_wdata_o = csr_rdata_i & ~rf_rdata_a_i;
            csr_we_o = 1'b1;
        end else begin
            csr_wdata_o = csr_rdata_i;
            csr_we_o = 1'b0;
        end
    end

    always_comb begin
        if (use_pc_i) begin
            alu_a_o = pc_now_i;
        end else begin
            alu_a_o = (exe_mem_rf_waddr_i != 0 && (exe_mem_rf_waddr_i == rf_raddr_a_i)) 
                        ? exe_mem_alu_result_i  // 这种情况下 MEM-EXE 的指令不是 load-use 关系，这一点由 pipeline_controller 保证
                        : rf_rdata_a_i;         // 对于 WB 正在写寄存器的情况，已经在 regfile 中实现了相应的旁路
        end
        if (use_rs2_i) begin
            alu_b_o = (exe_mem_rf_waddr_i != 0 && (exe_mem_rf_waddr_i == rf_raddr_b_i)) 
                        ? exe_mem_alu_result_i  // 这种情况下 MEM-EXE 的指令不是 load-use 关系，这一点由 pipeline_controller 保证
                        : rf_rdata_b_i;         // 对于 WB 正在写寄存器的情况，已经在 regfile 中实现了相应的旁路
        end else begin
            case (imm_type_i) 
                `TYPE_I: alu_b_o = {{20{inst_i[31]}}, inst_i[31:20]};
                `TYPE_S: alu_b_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                `TYPE_B: alu_b_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                `TYPE_U: alu_b_o = {inst_i[31:12], 12'b0};
                `TYPE_J: alu_b_o = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
                default: alu_b_o = 32'b0;
            endcase
        end
    end

    logic [31:0] comp_a;
    logic [31:0] comp_b;

    always_comb begin
        comp_a = (exe_mem_rf_waddr_i != 0 && (exe_mem_rf_waddr_i == rf_raddr_a_i)) 
                    ? exe_mem_alu_result_i  // 这种情况下 MEM-EXE 的指令不是 load-use 关系，这一点由 pipeline_controller 保证
                    : rf_rdata_a_i;         // 对于 WB 正在写寄存器的情况，已经在 regfile 中实现了相应的旁路
        comp_b = (exe_mem_rf_waddr_i != 0 && (exe_mem_rf_waddr_i == rf_raddr_b_i)) 
                    ? exe_mem_alu_result_i  // 这种情况下 MEM-EXE 的指令不是 load-use 关系，这一点由 pipeline_controller 保证
                    : rf_rdata_b_i;         // 对于 WB 正在写寄存器的情况，已经在 regfile 中实现了相应的旁路
    end

    always_comb begin
        if (jump_i) begin
            pc_next_o = alu_y_i;
            branch_comb_o = 1;
        end else if (imm_type_i == `TYPE_B) begin
            pc_next_o = alu_y_i;
            if (comp_op_i) begin
                branch_comb_o = (comp_a == comp_b);
            end else begin
                branch_comb_o = (comp_a != comp_b);
            end
        end else begin
            branch_comb_o = 0;
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
            if (jump_i) begin
                alu_result_o <= pc_now_i+4;
            end else if (csr_op_i != 0) begin
                alu_result_o <= csr_rdata_i;
            end else begin
                alu_result_o <= alu_y_i;
            end
            mem_en_o <= mem_en_i;
            rf_wen_o <= rf_wen_i;
            rf_waddr_o <= rf_waddr_i;
            mem_we_o <= mem_we_i;
            mem_sel_o <= mem_sel_i;
            mem_dat_o_o <= rf_rdata_b_i;
        end
    end

endmodule