module pc_mux (
    input wire branch_a_i,
    input wire branch_b_i,
    input wire [31:0] pc_next_a_i,
    input wire [31:0] pc_next_b_i,
    input wire [31:0] pc_now_i,
    output reg branch_o,
    output reg [31:0] pc_next_o
);

    always_comb begin
        branch_o = branch_a_i | branch_b_i;
        if (branch_a_i) begin
            pc_next_o = pc_next_a_i;
        end else if (branch_b_i) begin
            pc_next_o = pc_next_b_i;
        end else begin
            pc_next_o = pc_now_i + 4;
        end
    end

endmodule