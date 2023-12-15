`include "header.sv"
module alu_32 (
    input wire  [31:0] a,
    input wire  [31:0] b,
    input wire  [`ALU_OP_WIDTH-1:0] op,
    output reg  [31:0] y
);

    wire [15:0] cras16_h = a[31:16] + b[15:0];
    wire [15:0] cras16_l = a[15:0]  - b[31:16];

    always_comb begin
        case(op)
            `ALU_ADD   : y = a + b;
            `ALU_SUB   : y = a - b;
            `ALU_AND   : y = a & b;
            `ALU_OR    : y = a | b;
            `ALU_XOR   : y = a ^ b;
            `ALU_NEG   : y = ~a;
            `ALU_SLL   : y = a << b[4:0];
            `ALU_SRL   : y = a >> b[4:0];
            `ALU_SRA   : y = signed'(a) >>> b[4:0];
            `ALU_ROL   : y = (a << b[4:0]) | (a >> (32 - b[4:0]));
            `ALU_MIN   : y = $signed(a) < $signed(b) ? a : b;
            `ALU_SBCLR : y = a & ~({31'b0, 1'b1} << (b[4:0]));
            `ALU_SLT   : y = $signed(a) < $signed(b) ? 32'h1 : 32'h0;
            `ALU_SLTU  : y = a < b ? 32'h1 : 32'h0;
            `ALU_CTZ   : begin
                casez (a)
                    32'b????_????_????_????_????_????_????_???1: y = 32'd0;
                    32'b????_????_????_????_????_????_????_??10: y = 32'd1;
                    32'b????_????_????_????_????_????_????_?100: y = 32'd2;
                    32'b????_????_????_????_????_????_????_1000: y = 32'd3;
                    32'b????_????_????_????_????_????_???1_0000: y = 32'd4;
                    32'b????_????_????_????_????_????_??10_0000: y = 32'd5;
                    32'b????_????_????_????_????_????_?100_0000: y = 32'd6;
                    32'b????_????_????_????_????_????_1000_0000: y = 32'd7;
                    32'b????_????_????_????_????_???1_0000_0000: y = 32'd8;
                    32'b????_????_????_????_????_??10_0000_0000: y = 32'd9;
                    32'b????_????_????_????_????_?100_0000_0000: y = 32'd10;
                    32'b????_????_????_????_????_1000_0000_0000: y = 32'd11;
                    32'b????_????_????_????_???1_0000_0000_0000: y = 32'd12;
                    32'b????_????_????_????_??10_0000_0000_0000: y = 32'd13;
                    32'b????_????_????_????_?100_0000_0000_0000: y = 32'd14;
                    32'b????_????_????_????_1000_0000_0000_0000: y = 32'd15;
                    32'b????_????_????_???1_0000_0000_0000_0000: y = 32'd16;
                    32'b????_????_????_??10_0000_0000_0000_0000: y = 32'd17;
                    32'b????_????_????_?100_0000_0000_0000_0000: y = 32'd18;
                    32'b????_????_????_1000_0000_0000_0000_0000: y = 32'd19;
                    32'b????_????_???1_0000_0000_0000_0000_0000: y = 32'd20;
                    32'b????_????_??10_0000_0000_0000_0000_0000: y = 32'd21;
                    32'b????_????_?100_0000_0000_0000_0000_0000: y = 32'd22;
                    32'b????_????_1000_0000_0000_0000_0000_0000: y = 32'd23;
                    32'b????_???1_0000_0000_0000_0000_0000_0000: y = 32'd24;
                    32'b????_??10_0000_0000_0000_0000_0000_0000: y = 32'd25;
                    32'b????_?100_0000_0000_0000_0000_0000_0000: y = 32'd26;
                    32'b????_1000_0000_0000_0000_0000_0000_0000: y = 32'd27;
                    32'b???1_0000_0000_0000_0000_0000_0000_0000: y = 32'd28;
                    32'b??10_0000_0000_0000_0000_0000_0000_0000: y = 32'd29;
                    32'b?100_0000_0000_0000_0000_0000_0000_0000: y = 32'd30;
                    32'b1000_0000_0000_0000_0000_0000_0000_0000: y = 32'd31;
                    default: y = 32'd32;
                endcase
            end
            `ALU_CRAS16: begin
                y = {
                    cras16_h,
                    cras16_l                    
                };
            end
            default: y = 32'b0;
        endcase
    end
endmodule