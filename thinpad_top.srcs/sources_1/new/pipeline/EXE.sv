`include "../header.sv"


module EXE (
    input wire                          clk,
    input wire                          rst,

    input wire [REG_ADDR_WIDTH-1:0]     rf_raddr_a_i,
    input wire [REG_ADDR_WIDTH-1:0]     rf_raddr_b_i,
    input wire [DATA_WIDTH-1:0]         rf_rdata_a_i,
    input wire [DATA_WIDTH-1:0]         rf_rdata_b_i,
    input wire [DATA_WIDTH-1:0]         inst_i,
    output reg [DATA_WIDTH-1:0]         inst_o,
    input wire [`INSTR_TYPE_WIDTH-1:0]  imm_type_i,
    input wire                          use_rs2_i,

    output reg [DATA_WIDTH-1:0]         alu_a_o,
    output reg [DATA_WIDTH-1:0]         alu_b_o,
    input wire [DATA_WIDTH-1:0]         alu_y_i,
    output reg [DATA_WIDTH-1:0]         alu_result_o,

    input wire                          rf_wen_i,
    output reg                          rf_wen_o,
    input wire [REG_ADDR_WIDTH-1:0]     rf_waddr_i,
    output reg [REG_ADDR_WIDTH-1:0]     rf_waddr_o,
    input wire                          mem_re_i,
    output reg                          mem_re_o,
    input wire                          mem_we_i,
    output reg                          mem_we_o,
    input wire [DATA_WIDTH/8-1:0]       mem_sel_i,
    output reg [DATA_WIDTH/8-1:0]       mem_sel_o,
    output reg [DATA_WIDTH-1:0]         mem_wdata_o,
    input wire [ADDR_WIDTH-1:0]         pc_now_i,
    output reg [ADDR_WIDTH-1:0]         pc_next_o,
    input wire                          use_pc_i,
    input wire                          comp_op_i,
    input wire [2:0]                    csr_op_i,
    output reg [2:0]                    csr_op_o,
    output reg [DATA_WIDTH-1:0]         csr_data_o,
    input wire                          jump_i,
    output reg                          branch_comb_o,
    input wire                          instr_page_fault_i,
    input wire                          instr_access_fault_i,
    output reg                          instr_page_fault_o,
    output reg                          instr_access_fault_o,
    input wire                          ecall_i,
    output reg                          ecall_o,
    input wire                          ebreak_i,
    output reg                          ebreak_o,
    input wire                          mret_i,
    output reg                          mret_o,
    input wire                          sfence_i,
    output reg                          sfence_o,
    input wire                          stall_i,
    input wire                          bubble_i,

    // data forwarding
    input wire [REG_ADDR_WIDTH-1:0]     exe_mem1_rf_waddr_i,
    input wire [ADDR_WIDTH-1:0]         exe_mem1_alu_result_i,
    input wire [REG_ADDR_WIDTH-1:0]     mem1_mem2_rf_waddr_i,
    input wire [ADDR_WIDTH-1:0]         mem1_mem2_rf_wdata_i,

    // debug
    output reg [ADDR_WIDTH-1:0]         pc_now_o
);

    wire [DATA_WIDTH-1:0] rf_rdata_a_forwarded;
    wire [DATA_WIDTH-1:0] rf_rdata_b_forwarded;
    assign rf_rdata_a_forwarded = (exe_mem1_rf_waddr_i != 0  && (exe_mem1_rf_waddr_i  == rf_raddr_a_i)) ? exe_mem1_alu_result_i :
                                  (mem1_mem2_rf_waddr_i != 0 && (mem1_mem2_rf_waddr_i == rf_raddr_a_i)) ? mem1_mem2_rf_wdata_i :
                                   rf_rdata_a_i;
    assign rf_rdata_b_forwarded = (exe_mem1_rf_waddr_i != 0  && (exe_mem1_rf_waddr_i  == rf_raddr_b_i)) ? exe_mem1_alu_result_i :
                                  (mem1_mem2_rf_waddr_i != 0 && (mem1_mem2_rf_waddr_i == rf_raddr_b_i)) ? mem1_mem2_rf_wdata_i :
                                   rf_rdata_b_i;
    /* MEM1-EXE, MEM2-EXE 的指令都不是 load-use 关系，这�?点由 pipeline_controller 保证 */
    /* 对于 WB 正在写寄存器的情况，已经�? regfile 中实现了相应的旁�? */
    /* 目前的实现中，如果有 CSR 指令进入流水线，则暂�? IF，即 CSR 指令后不会再有其它任何指令，�?以不�?要�?�虑 CSR 读写指令修改�? rs1, rs2 的情�? */

    always_comb begin
        if (use_pc_i) begin
            alu_a_o = pc_now_i;
        end else begin
            alu_a_o = rf_rdata_a_forwarded;
        end
        if (use_rs2_i) begin
            alu_b_o = rf_rdata_b_forwarded;
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

    always_comb begin
        if (jump_i) begin
            pc_next_o = alu_y_i;
            branch_comb_o = 1;
        end else if (imm_type_i == `TYPE_B) begin
            if (comp_op_i) begin
                branch_comb_o = (rf_rdata_a_forwarded == rf_rdata_b_forwarded);
            end else begin
                branch_comb_o = (rf_rdata_a_forwarded != rf_rdata_b_forwarded);
            end
            if (branch_comb_o) begin
                pc_next_o = alu_y_i;
            end else begin
                pc_next_o = pc_now_i + 4;
            end
        end else begin
            branch_comb_o = 0;
            pc_next_o = 32'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            alu_result_o <= 32'b0;
            mem_re_o <= 0;
            rf_wen_o <= 0;
            rf_waddr_o <= 5'b0;
            mem_we_o <= 0;
            mem_sel_o <= 4'b0;
            mem_wdata_o <= 32'b0;
            pc_now_o <= pc_now_i;
            inst_o <= 32'b0;
            csr_op_o <= 3'b0;
            csr_data_o <= 32'b0;
            instr_access_fault_o <= 1'b0;
            instr_page_fault_o <= 1'b0;
            ecall_o <= 1'b0;
            ebreak_o <= 1'b0;
            mret_o <= 1'b0;
            sfence_o <= 1'b0;
        end else if (stall_i) begin
        end else if (bubble_i) begin
            alu_result_o <= 32'b0;
            mem_re_o <= 0;
            rf_wen_o <= 0;
            rf_waddr_o <= 5'b0;
            mem_we_o <= 0;
            mem_sel_o <= 4'b0;
            mem_wdata_o <= 32'b0;
            pc_now_o <= 32'b0;
            inst_o <= 32'b0;
            csr_op_o <= 3'b0;
            csr_data_o <= 32'b0;
            instr_access_fault_o <= 1'b0;
            instr_page_fault_o <= 1'b0;
            ecall_o <= 1'b0;
            ebreak_o <= 1'b0;
            mret_o <= 1'b0;
            sfence_o <= 1'b0;
        end else begin
            if (jump_i) begin
                alu_result_o <= pc_now_i+4;
            end else begin
                alu_result_o <= alu_y_i;
            end
            mem_re_o <= mem_re_i;
            rf_wen_o <= rf_wen_i;
            rf_waddr_o <= rf_waddr_i;
            mem_we_o <= mem_we_i;
            mem_sel_o <= mem_sel_i;
            mem_wdata_o <= rf_rdata_b_forwarded;
            pc_now_o <= pc_now_i;
            inst_o <= inst_i;
            csr_op_o <= csr_op_i;
            instr_access_fault_o <= instr_access_fault_i;
            instr_page_fault_o <= instr_page_fault_i;
            ecall_o <= ecall_i;
            ebreak_o <= ebreak_i;
            mret_o <= mret_i;
            sfence_o <= sfence_i;
            if (csr_op_i) begin
                if (csr_op_i[2] == 1'b0)
                    csr_data_o <= rf_rdata_a_forwarded;
                else
                    csr_data_o <= {27'b0, inst_i[19:15]};
            end else begin
                csr_data_o <= 32'b0;
            end
        end
    end

endmodule