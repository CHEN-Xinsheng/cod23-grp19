module pc_mux (
    input wire csr_branch_i,
    input wire exe_branch_comb_i,
    input wire [31:0] csr_pc_next_i,
    input wire [31:0] id_exe_pc_now,
    input wire [31:0] if2_id_pc_now,
    input wire [31:0] if1_if2_pc_vaddr,
    input wire [31:0] pc_vaddr,
    input wire [31:0] pc_next_comb,
    output reg branch_taken,
    output reg [31:0] pc_true
);

    always_comb begin
        if (csr_branch_i == 1) begin
            pc_true = csr_pc_next_i;
            branch_taken = 0;
        end else if (exe_branch_comb_i == 1) begin
            pc_true = pc_next_comb;
            if (pc_true == if2_id_pc_now
             || (pc_true == if1_if2_pc_vaddr && if2_id_pc_now == 32'h0)
             || (pc_true == pc_vaddr && if1_if2_pc_vaddr == 32'h0 && if2_id_pc_now == 32'h0)) begin
                branch_taken = 1;
            end else begin
                branch_taken = 0;
            end
        end else begin
            if (id_exe_pc_now  == 32'h0) begin
                branch_taken = 1;
                pc_true = 32'h0;
            end else begin
                pc_true = id_exe_pc_now + 4;
                if (pc_true == if2_id_pc_now
                || (pc_true == if1_if2_pc_vaddr && if2_id_pc_now == 32'h0)
                || (pc_true == pc_vaddr && if1_if2_pc_vaddr == 32'h0 && if2_id_pc_now == 32'h0)) begin
                    branch_taken = 1;
                end else begin
                    branch_taken = 0;
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