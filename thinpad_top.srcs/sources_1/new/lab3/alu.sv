module alu (
    input wire  [15:0] a,
    input wire  [15:0] b,
    input wire  [ 3:0] op,
    input reg  [15:0] y
);
    always_comb begin
        case(op)
            4'd1 : y = a + b;
            4'd2 : y = a - b;
            4'd3 : y = a & b;
            4'd4 : y = a | b;
            4'd5 : y = a ^ b;
            4'd6 : y = ~a;
            4'd7 : y = a << (b % 16);
            4'd8 : y = a >> (b % 16);
            4'd9 : y = signed'(a) >>> (b % 16);
            4'd10: y = (a << (b % 16)) | (a >> (16 - (b % 16)));
            default: y = 16'b0;
        endcase
    end
endmodule