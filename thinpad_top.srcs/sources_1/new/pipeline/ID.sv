`define TYPE_R 3'd1
`define TYPE_I 3'd2
`define TYPE_S 3'd3
`define TYPE_B 3'd4
`define TYPE_U 3'd5
`define TYPE_J 3'd6

module ID (
    input wire clk,
    input wire rst,
    input wire [31:0] inst_i,
    output reg [31:0] inst_o,
    output reg [4:0] rf_raddr_a_o,
    output reg [4:0] rf_raddr_b_o,
    output wire [4:0] rf_raddr_a_comb,
    output wire [4:0] rf_raddr_b_comb,
    output reg [2:0] imm_type_o,
    output reg [3:0] alu_op_o,
    output reg use_rs2_o,
    output reg mem_en_o,
    output reg rf_wen_o,
    output reg [4:0] rf_waddr_o,
    output reg mem_we_o,
    output reg [3:0] mem_sel_o,
    input wire [31:0] pc_now_i,
    output reg [31:0] pc_now_o,
    input wire stall_i,
    input wire bubble_i
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

    assign rf_raddr_a_comb = rs1;
    assign rf_raddr_b_comb = rs2;

    always_ff @(posedge clk) begin
        if (rst) begin 
            inst_o <= 32'h0;
            rf_raddr_a_o <= 5'd0;
            rf_raddr_b_o <= 5'd0;
            imm_type_o <= 3'd0;
            alu_op_o <= 4'd0;
            use_rs2_o <= 1'b0;
            mem_en_o <= 1'b0;
            rf_wen_o <= 1'b0;
            rf_waddr_o <= 5'b0;
            mem_we_o <= 1'b0;
            pc_now_o <= 32'h0;
            mem_sel_o <= 4'b0;
        end else if (stall_i) begin
        end else if (bubble_i) begin
            inst_o <= 32'h0;
            rf_raddr_a_o <= 5'd0;
            rf_raddr_b_o <= 5'd0;
            imm_type_o <= 3'd0;
            alu_op_o <= 4'd0;
            use_rs2_o <= 1'b0;
            mem_en_o <= 1'b0;
            rf_wen_o <= 1'b0;
            rf_waddr_o <= 5'b0;
            mem_we_o <= 1'b0;
            pc_now_o <= 32'h0;
        end else begin
            inst_o <= inst_i;
            case(opcode)
                7'b0010011: begin   // ADDI ANDI
                    rf_raddr_a_o <= rs1;
                    rf_raddr_b_o <= 5'b0;
                    imm_type_o <= `TYPE_I;
                    use_rs2_o <= 0;
                    mem_en_o <= 0;
                    rf_wen_o <= 1;
                    rf_waddr_o <= rd;
                    if (funct3 == 3'b000) begin
                        alu_op_o <= 4'd1;      // ADD
                    end else if (funct3 == 3'b111) begin
                        alu_op_o <= 4'd3;      // AND
                    end else begin
                    end
                end
                7'b0110011: begin   // ADD
                    rf_raddr_a_o <= rs1;
                    rf_raddr_b_o <= rs2;
                    imm_type_o <= `TYPE_R;
                    use_rs2_o <= 1;
                    mem_en_o <= 0;
                    rf_wen_o <= 1;
                    rf_waddr_o <= rd;
                    alu_op_o <= 4'd1;      // ADD
                end
                7'b0100011: begin   // SW SB
                    rf_raddr_a_o <= rs1;
                    rf_raddr_b_o <= rs2;
                    imm_type_o <= `TYPE_S;
                    use_rs2_o <= 0;
                    mem_en_o <= 1;
                    rf_wen_o <= 0;
                    rf_waddr_o <= 5'b0;
                    alu_op_o <= 4'd1;
                    mem_we_o <= 1;
                    if (funct3 == 3'b010) begin     // SW
                        mem_sel_o <= 4'b1111;
                    end
                    else if (funct3 == 3'b000) begin    // SB
                        mem_sel_o <= 4'b0001;
                    end else begin
                    end
                end
                7'b0000011: begin       // LB
                    rf_raddr_a_o <= rs1;
                    rf_raddr_b_o <= 5'b0;
                    imm_type_o <= `TYPE_I;
                    use_rs2_o <= 0;
                    mem_en_o <= 1;
                    rf_wen_o <= 1;
                    rf_waddr_o <= rd;
                    alu_op_o <= 4'd1;
                    mem_we_o <= 0;
                    mem_sel_o <= 4'b1111;
                end
                7'b0110111: begin       // LUI
                    rf_raddr_a_o <= 5'b0;
                    rf_raddr_b_o <= 5'b0;
                    imm_type_o <= `TYPE_U;
                    use_rs2_o <= 0;
                    mem_en_o <= 0;
                    rf_wen_o <= 1;
                    rf_waddr_o <= rd;
                    alu_op_o <= 4'd1; 
                end
                7'b1100011: begin   // BEQ
                    rf_raddr_a_o <= rs1;
                    rf_raddr_b_o <= rs2;
                    imm_type_o <= `TYPE_B;
                    pc_now_o <= pc_now_i;
                    mem_en_o <= 0;
                    rf_wen_o <= 0;
                    rf_waddr_o <= 5'b0;
                    alu_op_o <= 4'd1; 
                end
                default: begin
                    inst_o <= 32'h0;
                    rf_raddr_a_o <= 5'd0;
                    rf_raddr_b_o <= 5'd0;
                    imm_type_o <= 3'd0;
                    alu_op_o <= 4'd0;
                    use_rs2_o <= 1'b0;
                    mem_en_o <= 1'b0;
                    rf_wen_o <= 1'b0;
                    rf_waddr_o <= 5'b0;
                    mem_we_o <= 1'b0;
                    pc_now_o <= 32'h0;
                end
            endcase
        end
    end


endmodule
