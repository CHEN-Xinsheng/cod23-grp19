module pc_mux (
    input wire                  csr_branch_i,
    input wire [ADDR_WIDTH-1:0] csr_pc_next_i,
    input wire                  exe_branch_comb_i,
    input wire [ADDR_WIDTH-1:0] exe_pc_next_comb_i,

    input wire [ADDR_WIDTH-1:0] id_exe_pc_now,
    input wire [ADDR_WIDTH-1:0] if2_id_pc_now,
    input wire [ADDR_WIDTH-1:0] if1_if2_pc_vaddr,
    input wire [ADDR_WIDTH-1:0] if1_pc_vaddr,

    output reg                  branch_taken_o,   // previous prediction is correct(1)/wrong(0)
    output reg [ADDR_WIDTH-1:0] pc_true_o
);

    always_comb begin
        if (csr_branch_i == 1) begin
            pc_true_o = csr_pc_next_i;
            branch_taken_o = 0;
        end else if (exe_branch_comb_i == 1) begin
            pc_true_o = exe_pc_next_comb_i;
            if ( 
                (pc_true_o == if2_id_pc_now)
             || (pc_true_o == if1_if2_pc_vaddr && if2_id_pc_now == {ADDR_WIDTH{1'b0}})
             || (pc_true_o == if1_pc_vaddr && if1_if2_pc_vaddr == {ADDR_WIDTH{1'b0}} && if2_id_pc_now == {ADDR_WIDTH{1'b0}})
            ) begin
                branch_taken_o = 1;
            end else begin
                branch_taken_o = 0;
            end
        end else begin
            if (id_exe_pc_now  == {ADDR_WIDTH{1'b0}}) begin
                branch_taken_o = 1;
                pc_true_o = {ADDR_WIDTH{1'b0}};  // unused, beacuse branch_taken_o == 1.
            end else begin
                pc_true_o = id_exe_pc_now + 4;
                if ( 
                    (pc_true_o == if2_id_pc_now)
                 || (pc_true_o == if1_if2_pc_vaddr && if2_id_pc_now == {ADDR_WIDTH{1'b0}})
                 || (pc_true_o == if1_pc_vaddr && if1_if2_pc_vaddr == {ADDR_WIDTH{1'b0}} && if2_id_pc_now == {ADDR_WIDTH{1'b0}})
                ) begin
                    branch_taken_o = 1;
                end else begin
                    branch_taken_o = 0;
                end
            end
        end
    end

    // always_comb begin
    //     branch_o = branch_a_i | branch_b_i;
    //     if (branch_a_i) begin
    //         pc_next_o = pc_next_a_i;
    //     end else if (branch_b_i) begin
    //         pc_next_o = pc_next_b_i;
    //     end else begin
    //         pc_next_o = pc_now_i + 4;
    //     end
    // end

endmodule