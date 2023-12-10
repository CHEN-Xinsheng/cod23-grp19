`include "../header.sv"


module ID (
    input wire                          clk,
    input wire                          rst,

    input wire  [DATA_WIDTH-1:0]        inst_i,
    output reg  [DATA_WIDTH-1:0]        inst_o,
    output reg  [REG_ADDR_WIDTH-1:0]    rf_raddr_a_o,
    output reg  [REG_ADDR_WIDTH-1:0]    rf_raddr_b_o,
    output wire [REG_ADDR_WIDTH-1:0]    id_rf_raddr_a_comb,
    output wire [REG_ADDR_WIDTH-1:0]    id_rf_raddr_b_comb,
    output reg  [`INSTR_TYPE_WIDTH-1:0] imm_type_o,
    output reg  [`ALU_OP_WIDTH-1:0]     alu_op_o,
    output reg                          use_rs2_o,
    output reg                          rf_wen_o,
    output reg [REG_ADDR_WIDTH-1:0]     rf_waddr_o,
    output reg                          mem_re_o,
    output reg                          mem_we_o,
    output reg [DATA_WIDTH/8-1:0]       mem_sel_o,
    input wire [ADDR_WIDTH-1:0]         pc_now_i,
    output reg [ADDR_WIDTH-1:0]         pc_now_o,
    output reg                          use_pc_o,
    output reg [`CSR_OP_WIDTH-1:0]      comp_op_o,
    output reg                          load_type_o,
    output reg                          jump_o,
    output reg [`CSR_OP_WIDTH-1:0]      csr_op_o,
    output reg                          ecall_o,
    output reg                          ebreak_o,
    output reg                          mret_o,
    output reg                          sret_o,
    output reg                          fencei_o,
    input wire                          instr_page_fault_i,
    input wire                          instr_access_fault_i,
    output reg                          instr_page_fault_o,
    output reg                          instr_access_fault_o,
    input wire                          instr_misaligned_i,
    output reg                          instr_misaligned_o,
    output reg                          illegal_instr_o,
    output reg [`CSR_OP_WIDTH-1:0]      csr_op_comb,
    output reg                          sfence_vma_o,
    input wire                          stall_i,
    input wire                          bubble_i
);
    
    reg [4:0] rd;
    reg [4:0] rs1;
    reg [4:0] rs2;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7; 
    
    assign rd = inst_i[11:7];
    assign rs1 = inst_i[19:15];
    assign rs2 = inst_i[24:20];
    assign opcode[6:0] = inst_i[6:0];
    assign funct3[2:0] = inst_i[14:12];
    assign funct7[6:0] = inst_i[31:25];

    assign id_rf_raddr_a_comb = rs1;
    assign id_rf_raddr_b_comb = rs2;

    always_ff @(posedge clk) begin
        if (rst) begin 
            inst_o <= 32'h0;
            rf_raddr_a_o <= 5'd0;
            rf_raddr_b_o <= 5'd0;
            imm_type_o <= `INSTR_TYPE_WIDTH'd0;
            alu_op_o <= 4'd0;
            use_rs2_o <= 1'b0;
            mem_re_o <= 1'b0;
            mem_we_o <= 1'b0;
            rf_wen_o <= 1'b0;
            rf_waddr_o <= 5'b0;
            pc_now_o <= 32'h0;
            mem_sel_o <= 4'b0;
            use_pc_o <= 1'b0;
            comp_op_o <= 3'b0;
            load_type_o <= 1'b0;
            jump_o <= 1'b0;
            csr_op_o <= 3'b0;
            ecall_o <= 1'b0;
            ebreak_o <= 1'b0;
            mret_o <= 1'b0;
            sret_o <= 1'b0;
            instr_access_fault_o <= 1'b0;
            instr_page_fault_o <= 1'b0;
            instr_misaligned_o <= 1'b0;
            illegal_instr_o <= 1'b0;
            sfence_vma_o <= 1'b0;
        end else if (stall_i) begin
        end else if (bubble_i) begin
            inst_o <= 32'h0;
            rf_raddr_a_o <= 5'd0;
            rf_raddr_b_o <= 5'd0;
            imm_type_o <= `INSTR_TYPE_WIDTH'd0;
            alu_op_o <= 4'd0;
            use_rs2_o <= 1'b0;
            mem_re_o <= 1'b0;
            mem_we_o <= 1'b0;
            rf_wen_o <= 1'b0;
            rf_waddr_o <= 5'b0;
            pc_now_o <= 32'h0;
            comp_op_o <= 3'b0;
            load_type_o <= 1'b0;
            use_pc_o <= 1'b0;
            jump_o <= 1'b0;
            csr_op_o <= 3'b0;
            ecall_o <= 1'b0;
            ebreak_o <= 1'b0;
            mret_o <= 1'b0;
            sret_o <= 1'b0;
            instr_access_fault_o <= 1'b0;
            instr_page_fault_o <= 1'b0;
            instr_misaligned_o <= 1'b0;
            illegal_instr_o <= 1'b0;
            sfence_vma_o <= 1'b0;
        end else begin
            inst_o <= inst_i;
            ecall_o <= 1'b0;
            ebreak_o <= 1'b0;
            mret_o <= 1'b0;
            sret_o <= 1'b0;
            comp_op_o <= 3'b0;
            pc_now_o <= pc_now_i;
            instr_access_fault_o <= instr_access_fault_i;
            instr_page_fault_o <= instr_page_fault_i;
            instr_misaligned_o <= instr_misaligned_i;
            illegal_instr_o <= 1'b0;
            sfence_vma_o <= 1'b0;
            case(opcode)
                7'b0010011: begin   // TYPE_I
                    rf_raddr_a_o <= rs1;
                    rf_raddr_b_o <= 5'b0;
                    imm_type_o <= `TYPE_I;
                    use_rs2_o <= 0;
                    use_pc_o <= 0;
                    jump_o <= 1'b0;
                    mem_re_o <= 1'b0;
                    mem_we_o <= 1'b0;
                    rf_wen_o <= 1;
                    rf_waddr_o <= rd;
                    csr_op_o <= 3'b0;
                    if (funct3 == 3'b000) begin
                        alu_op_o <= `ALU_ADD;    
                    end else if (funct3 == 3'b111) begin
                        alu_op_o <= `ALU_AND;  
                    end else if (funct3 == 3'b110) begin
                        alu_op_o <= `ALU_OR;     
                    end else if (funct3 == 3'b001) begin
                        if (funct7 == 7'b0000000) begin
                            alu_op_o <= `ALU_SLL;    
                        end else if (funct7 == 7'b0110000) begin
                            alu_op_o <= `ALU_CTZ;
                        end else begin
                            alu_op_o <= `ALU_ADD;
                        end
                    end else if (funct3 == 3'b101) begin
                        if (funct7 == 7'b0000000) begin
                            alu_op_o <= `ALU_SRL;    
                        end else if (funct7 == 7'b0100000) begin
                            alu_op_o <= `ALU_SRA;    
                        end else begin
                            alu_op_o <= `ALU_ADD;
                            illegal_instr_o <= 1'b1;
                        end
                    end else if (funct3 == 3'b100) begin
                        alu_op_o <= `ALU_XOR;
                    end else if (funct3 == 3'b010) begin
                        alu_op_o <= `ALU_SLT;
                    end else if (funct3 == 3'b011) begin
                        alu_op_o <= `ALU_SLTU;
                    end else begin
                        alu_op_o <= `ALU_ADD;
                        illegal_instr_o <= 1'b1;
                    end
                end
                7'b0110011: begin   // TYPE_R
                    rf_raddr_a_o <= rs1;
                    rf_raddr_b_o <= rs2;
                    imm_type_o <= `TYPE_R;
                    use_rs2_o <= 1;
                    use_pc_o <= 0;
                    mem_re_o <= 1'b0;
                    mem_we_o <= 1'b0;
                    rf_wen_o <= 1;
                    jump_o <= 1'b0;
                    rf_waddr_o <= rd;
                    csr_op_o <= 3'b0;
                    if (funct3 == 3'b000) begin
                        if (funct7 == 7'b0000000) begin
                            alu_op_o <= `ALU_ADD; 
                        end else if (funct7 == 7'b0100000) begin
                            alu_op_o <= `ALU_SUB; 
                        end else begin
                            alu_op_o <= `ALU_ADD;
                        end
                    end else if (funct3 == 3'b111) begin
                        alu_op_o <= `ALU_AND;  
                    end else if (funct3 == 3'b110) begin
                        alu_op_o <= `ALU_OR; 
                    end else if (funct3 == 3'b101) begin
                        if (funct7 == 7'b0000000) begin
                            alu_op_o <= `ALU_SRL; 
                        end else if (funct7 == 7'b0100000) begin
                            alu_op_o <= `ALU_SRA; 
                        end else begin
                            alu_op_o <= `ALU_ADD;
                            illegal_instr_o <= 1'b1;
                        end
                    end else if (funct3 == 3'b100) begin
                        if (funct7 == 7'b0000000) begin
                            alu_op_o <= `ALU_XOR; 
                        end else if (funct7 == 7'b0000101) begin
                            alu_op_o <= `ALU_MIN;
                        end else begin
                            alu_op_o <= `ALU_AND;
                        end
                    end else if (funct3 == 3'b001) begin
                        if (funct7 == 7'b0000000) begin
                            alu_op_o <= `ALU_SLL; 
                        end else if (funct7 == 7'b0100100) begin
                            alu_op_o <= `ALU_SBCLR; 
                        end else begin
                            alu_op_o <= `ALU_ADD;
                            illegal_instr_o <= 1'b1;
                        end
                    end else if (funct3 == 3'b010) begin
                        alu_op_o <= `ALU_SLT;
                    end else if (funct3 == 3'b011) begin
                        alu_op_o <= `ALU_SLTU;
                    end else begin
                        alu_op_o <= `ALU_ADD;
                        illegal_instr_o <= 1'b1;
                    end
                end
                7'b0100011: begin   // Store
                    rf_raddr_a_o <= rs1;
                    rf_raddr_b_o <= rs2;
                    imm_type_o <= `TYPE_S;
                    use_rs2_o <= 0;
                    use_pc_o <= 0;
                    mem_re_o <= 1'b0;
                    mem_we_o <= 1'b1;
                    rf_wen_o <= 0;
                    rf_waddr_o <= 5'b0;
                    alu_op_o <= `ALU_ADD;
                    jump_o <= 1'b0;
                    csr_op_o <= 3'b0;
                    if (funct3 == 3'b010) begin     // SW
                        mem_sel_o <= 4'b1111;
                    end else if (funct3 == 3'b000) begin    // SB
                        mem_sel_o <= 4'b0001;
                    end else if (funct3 == 3'b001) begin    // SH
                        mem_sel_o <= 4'b0011;
                    end else begin
                        illegal_instr_o <= 1'b1;
                    end
                end
                7'b0000011: begin       // Load
                    rf_raddr_a_o <= rs1;
                    rf_raddr_b_o <= 5'b0;
                    imm_type_o <= `TYPE_I;
                    use_rs2_o <= 0;
                    use_pc_o <= 0;
                    mem_re_o <= 1'b1;
                    mem_we_o <= 1'b0;
                    rf_wen_o <= 1;
                    rf_waddr_o <= rd;
                    alu_op_o <= `ALU_ADD;
                    jump_o <= 1'b0;
                    csr_op_o <= 3'b0;
                    if (funct3 == 3'b000) begin     // LB
                        mem_sel_o <= 4'b0001;
                        load_type_o <= 1'b1;
                    end else if (funct3 == 3'b010) begin    // LW
                        mem_sel_o <= 4'b1111;
                        load_type_o <= 1'b1;
                    end else if (funct3 == 3'b001) begin    // LH
                        mem_sel_o <= 4'b0011;
                        load_type_o <= 1'b1;
                    end else if (funct3 == 3'b100) begin    // LBU
                        mem_sel_o <= 4'b0001;
                        load_type_o <= 1'b0;
                    end else if (funct3 == 3'b101) begin    // LHU
                        mem_sel_o <= 4'b0011;
                        load_type_o <= 1'b0;
                    end else begin
                        illegal_instr_o <= 1'b1;
                    end
                end
                7'b0110111: begin       // LUI
                    rf_raddr_a_o <= 5'b0;
                    rf_raddr_b_o <= 5'b0;
                    imm_type_o <= `TYPE_U;
                    use_rs2_o <= 0;
                    use_pc_o <= 0;
                    mem_re_o <= 1'b0;
                    mem_we_o <= 1'b0;
                    rf_wen_o <= 1;
                    rf_waddr_o <= rd;
                    alu_op_o <= `ALU_ADD; 
                    jump_o <= 1'b0;
                    csr_op_o <= 3'b0;
                end
                7'b1100011: begin   // BEQ BNE
                    rf_raddr_a_o <= rs1;
                    rf_raddr_b_o <= rs2;
                    imm_type_o <= `TYPE_B;
                    use_rs2_o <= 0;
                    use_pc_o <= 1;
                    mem_re_o <= 1'b0;
                    mem_we_o <= 1'b0;
                    rf_wen_o <= 0;
                    jump_o <= 1'b0;
                    rf_waddr_o <= 5'b0;
                    alu_op_o <= `ALU_ADD; 
                    csr_op_o <= 3'b0;
                    if (funct3 != 3'b010 && funct3 != 3'b011) begin
                        comp_op_o <= funct3;
                    end else begin
                        illegal_instr_o <= 1'b1;
                    end
                end
                7'b0010111: begin    // AUIPC
                    rf_raddr_a_o <= 5'b0;
                    rf_raddr_b_o <= 5'b0;
                    imm_type_o <= `TYPE_U;
                    use_rs2_o <= 0;
                    use_pc_o <= 1;
                    // pc_now_o <= pc_now_i;
                    mem_re_o <= 1'b0;
                    mem_we_o <= 1'b0;
                    jump_o <= 1'b0;
                    rf_wen_o <= 1;
                    rf_waddr_o <= rd;
                    alu_op_o <= `ALU_ADD; 
                    csr_op_o <= 3'b0;
                end
                7'b1101111: begin    // JAL
                    rf_raddr_a_o <= 5'b0;
                    rf_raddr_b_o <= 5'b0;
                    imm_type_o <= `TYPE_J;
                    use_rs2_o <= 0;
                    use_pc_o <= 1;
                    // pc_now_o <= pc_now_i;
                    jump_o <= 1'b1;
                    mem_re_o <= 1'b0;
                    mem_we_o <= 1'b0;
                    rf_wen_o <= 1;
                    rf_waddr_o <= rd;
                    alu_op_o <= `ALU_ADD; 
                    csr_op_o <= 3'b0;
                end
                7'b1100111: begin    // JALR
                    rf_raddr_a_o <= rs1;
                    rf_raddr_b_o <= 5'b0;
                    imm_type_o <= `TYPE_I;
                    use_rs2_o <= 0;
                    use_pc_o <= 0;
                    // pc_now_o <= pc_now_i;
                    mem_re_o <= 1'b0;
                    mem_we_o <= 1'b0;
                    rf_wen_o <= 1;
                    jump_o <= 1'b1;
                    rf_waddr_o <= rd;
                    alu_op_o <= `ALU_ADD; 
                    csr_op_o <= 3'b0;
                end
                7'b0001111: begin       // FENCE.I
                    if (funct3 == 3'b001) begin
                        // inst_o <= 32'h0;
                        rf_raddr_a_o <= 5'd0;
                        rf_raddr_b_o <= 5'd0;
                        imm_type_o <= `INSTR_TYPE_WIDTH'd0;
                        alu_op_o <= 4'd0;
                        use_rs2_o <= 1'b0;
                        jump_o <= 1'b0;
                        use_pc_o <= 1'b0;
                        comp_op_o <= 3'b0;
                        mem_re_o <= 1'b0;
                        mem_we_o <= 1'b0;
                        rf_wen_o <= 1'b0;
                        rf_waddr_o <= 5'b0;
                        csr_op_o <= 3'b0;
                    end else begin
                        illegal_instr_o <= 1'b1;
                        // fencei_o <= 1'b0;
                    end
                end
                7'b1110011: begin
                    if (funct3[1:0] != 2'b0) begin      // CSRW
                        rf_raddr_a_o <= rs1;
                        rf_raddr_b_o <= 5'b0;
                        imm_type_o <= `INSTR_TYPE_WIDTH'd0;
                        use_rs2_o <= 1;
                        use_pc_o <= 0;
                        jump_o <= 1'b0;
                        mem_re_o <= 1'b0;
                        mem_we_o <= 1'b0;
                        rf_wen_o <= 1;
                        rf_waddr_o <= rd;
                        alu_op_o <= `ALU_ADD;
                        csr_op_o <= funct3;
                    end else if (funct3 == 3'b0) begin
                        // inst_o <= 32'h0;
                        rf_raddr_a_o <= 5'd0;
                        rf_raddr_b_o <= 5'd0;
                        imm_type_o <= `INSTR_TYPE_WIDTH'd0;
                        alu_op_o <= 4'd0;
                        use_rs2_o <= 1'b0;
                        jump_o <= 1'b0;
                        use_pc_o <= 1'b0;
                        comp_op_o <= 3'b0;
                        mem_re_o <= 1'b0;
                        mem_we_o <= 1'b0;
                        rf_wen_o <= 1'b0;
                        rf_waddr_o <= 5'b0;
                        csr_op_o <= 3'b0;
                        if (inst_i[31:7] == 25'b0000000000000000000000000) begin     // ECALL
                            ecall_o <= 1'b1;
                        end else if (inst_i[31:7] == 25'b0000000000010000000000000) begin    // EBREAK
                            ebreak_o <= 1'b1;
                        end else if (inst_i[31:7] == 25'b0011000000100000000000000) begin    // MRET
                            mret_o <= 1'b1;
                        end else if (inst_i[31:7] == 25'b0001000000100000000000000) begin    // MRET
                            sret_o <= 1'b1;
                        end else if (funct7 == 7'b0001001 && rd == 5'b0) begin    // SFENCE.VMA
                            sfence_vma_o <= 1'b1;
                        end else begin
                            illegal_instr_o <= 1'b1;
                        end
                    end else begin
                        illegal_instr_o <= 1'b1;
                    end
                end
                default: begin
                    // inst_o <= 32'h0;
                    rf_raddr_a_o <= 5'd0;
                    rf_raddr_b_o <= 5'd0;
                    imm_type_o <= `INSTR_TYPE_WIDTH'd0;
                    alu_op_o <= 4'd0;
                    use_rs2_o <= 1'b0;
                    jump_o <= 1'b0;
                    use_pc_o <= 1'b0;
                    comp_op_o <= 3'b0;
                    mem_re_o <= 1'b0;
                    mem_we_o <= 1'b0;
                    rf_wen_o <= 1'b0;
                    rf_waddr_o <= 5'b0;
                    csr_op_o <= 3'b0;
                    if (inst_i == 32'h0) begin
                        illegal_instr_o <= 1'b0;
                    end else begin
                        illegal_instr_o <= 1'b1;
                    end
                end
            endcase
        end
    end

    always_comb begin
        if (funct7 == 7'b1110011)
            csr_op_comb = funct3;
        else
            csr_op_comb = 3'b0;
    end

    assign fencei_o = opcode == 7'b0001111 && funct3 == 3'b001;

endmodule
