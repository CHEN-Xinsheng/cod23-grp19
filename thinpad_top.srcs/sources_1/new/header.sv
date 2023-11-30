`ifndef __PARAM_H_
`define __PARAM_H_


`define TYPE_R 3'd1
`define TYPE_I 3'd2
`define TYPE_S 3'd3
`define TYPE_B 3'd4
`define TYPE_U 3'd5
`define TYPE_J 3'd6

`define ALU_ADD    4'd1
`define ALU_SUB    4'd2
`define ALU_AND    4'd3
`define ALU_OR     4'd4
`define ALU_XOR    4'd5
`define ALU_NEG    4'd6
`define ALU_SLL    4'd7
`define ALU_SRL    4'd8
`define ALU_SRA    4'd9
`define ALU_ROL    4'd10
`define ALU_MIN    4'd11
`define ALU_SBCLR  4'd12
`define ALU_CTZ    4'd13

localparam DATA_WIDTH = 32;
localparam ADDR_WIDTH = 32;


`endif
