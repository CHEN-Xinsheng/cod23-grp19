`include "../header.sv"

module IF (
    input wire                  clk,
    input wire                  rst,

    output reg [DATA_WIDTH-1:0] pc_o,
    input wire                  branch_taken_i,
    input wire [DATA_WIDTH-1:0] pc_pred_i,
    input wire [DATA_WIDTH-1:0] pc_true_i,
    input wire                  stall_i,
    input wire                  bubble_i
);
    
    reg [ADDR_WIDTH-1:0] pc;

    assign pc_o = pc;

    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 32'h80000000;
        end else begin
            if (stall_i) begin
            end else if (~branch_taken_i) begin
                pc <= pc_true_i;
            end else begin
                pc <= pc_pred_i;
            end
        end
    end

    // always_ff @(posedge clk) begin
    //     if (rst) begin
    //         pc <= 32'h80000000;
    //         pc_cached <= 32'h0;
    //     end else begin
    //         if (stall_i) begin
    //         end else if (~branch_taken_i) begin
    //             if (icache_ack_i) begin 
    //                 pc <= pc_true_i;
    //             end else begin 
    //                 pc_cached <= pc_true_i;
    //             end
    //         end else begin
    //             if (icache_ack_i) begin 
    //                 if (pc_cached != 0) begin
    //                     pc <= pc_cached;
    //                     pc_cached <= 32'h0;
    //                 end else begin
    //                     pc <= pc_pred_i;
    //                 end
    //             end
    //         end
    //     end
    // end
    
endmodule