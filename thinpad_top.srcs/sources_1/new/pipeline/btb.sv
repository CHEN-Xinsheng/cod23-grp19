`include "../header.sv"

module btb # (
    parameter BTB_SIZE = 16,
    parameter INDEX_WIDTH = 4,  // BTB_SIZE = 2^INDEX_WIDTH
    parameter OFFSET_WIDTH = 2,
    parameter TAG_WIDTH = ADDR_WIDTH - OFFSET_WIDTH - INDEX_WIDTH  // 26
) (
    input wire                  clk,
    input wire                  rst,

    input wire [ADDR_WIDTH-1:0] pc_i,
    output reg [ADDR_WIDTH-1:0] pred_pc_o,

    input wire [ADDR_WIDTH-1:0] branch_from_pc_i,
    input wire [ADDR_WIDTH-1:0] branch_to_pc_i,
    input wire                  branch_taken_i,
    input wire                  is_branch_i
);

    // BHT (2) + TAG + TARGET_ADDR
    logic [TAG_WIDTH + ADDR_WIDTH + 1:0] btb_table[BTB_SIZE];

    logic [TAG_WIDTH + ADDR_WIDTH + 1:0] pc_hit_line;
    logic [1:0] pc_hit_bht;
    logic [TAG_WIDTH - 1:0] pc_hit_tag;
    logic [ADDR_WIDTH - 1:0] pc_hit_data;
    logic pc_hit;
    logic [TAG_WIDTH - 1:0] pc_tag;
    logic [INDEX_WIDTH - 1:0] pc_index;

    logic [TAG_WIDTH + ADDR_WIDTH + 1:0] branch_from_hit_line;
    logic [1:0] branch_from_hit_bht;
    logic [TAG_WIDTH - 1:0] branch_from_hit_tag;
    logic branch_from_hit;
    logic [TAG_WIDTH - 1:0] branch_from_tag;
    logic [INDEX_WIDTH - 1:0] branch_from_index;

    assign pc_tag = pc_i[ADDR_WIDTH - 1:INDEX_WIDTH + OFFSET_WIDTH];
    assign pc_index = pc_i[INDEX_WIDTH + OFFSET_WIDTH - 1:OFFSET_WIDTH];
    assign branch_from_tag = branch_from_pc_i[ADDR_WIDTH - 1:INDEX_WIDTH + OFFSET_WIDTH];
    assign branch_from_index = branch_from_pc_i[INDEX_WIDTH + OFFSET_WIDTH - 1:OFFSET_WIDTH];

    assign pc_hit_line = btb_table[pc_index];
    assign pc_hit_bht = pc_hit_line[TAG_WIDTH + DATA_WIDTH + 1:TAG_WIDTH + DATA_WIDTH];
    assign pc_hit_tag = pc_hit_line[TAG_WIDTH + DATA_WIDTH - 1:DATA_WIDTH];
    assign pc_hit_data = pc_hit_line[DATA_WIDTH - 1:0];
    assign pc_hit = (pc_hit_bht[1]) && (pc_tag == pc_hit_tag);

    assign branch_from_hit_line = btb_table[branch_from_index];
    assign branch_from_hit_bht = branch_from_hit_line[TAG_WIDTH + DATA_WIDTH + 1:TAG_WIDTH + DATA_WIDTH];
    assign branch_from_hit_tag = branch_from_hit_line[TAG_WIDTH + DATA_WIDTH - 1:DATA_WIDTH];
    assign branch_from_hit = (branch_from_hit_bht[1]) && (branch_from_tag == branch_from_hit_tag);

    always_comb begin
        if (pc_hit) begin
            pred_pc_o = pc_hit_data;
        end else begin
            pred_pc_o = pc_i + 4;
        end
    end
    
    always_ff @ (posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < BTB_SIZE; i = i + 1) begin
                btb_table[i] <= {{TAG_WIDTH + DATA_WIDTH + 1}{1'b0}};
            end
        end else begin
            if (is_branch_i) begin
                if (branch_from_hit) begin
                    if (branch_taken_i) begin
                        if (branch_from_hit_bht != 2'b11) begin
                            btb_table[branch_from_index][TAG_WIDTH + DATA_WIDTH + 1:TAG_WIDTH + DATA_WIDTH] <= branch_from_hit_bht + 1;
                        end
                        btb_table[branch_from_index][DATA_WIDTH - 1:0] <= branch_to_pc_i;
                    end else begin
                        if (branch_from_hit_bht != 2'b00) begin
                            btb_table[branch_from_index][TAG_WIDTH + DATA_WIDTH + 1:TAG_WIDTH + DATA_WIDTH] <= branch_from_hit_bht - 1;
                        end
                    end
                end else begin
                    btb_table[branch_from_index] <= {1'b1, branch_taken_i, branch_from_tag, branch_to_pc_i};
                end
            end
        end
    end
endmodule