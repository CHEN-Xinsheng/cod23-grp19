module pipeline_controller (
    input wire if_ack_i,
    input wire mem_ack_i,
    input wire mem_en_i,
    input wire [4:0] rf_raddr_a_i,
    input wire [4:0] rf_raddr_b_i,
    input wire [4:0] id_exe_rf_waddr_i,
    input wire [4:0] exe_mem_rf_waddr_i,
    input wire [4:0] rf_waddr_i,
    input wire branch_i,
    output reg [3:0] stall_o,
    output reg [3:0] bubble_o
);

    always_comb begin
        if (mem_en_i == 1 && mem_ack_i == 0) begin
            stall_o = 4'b1110;
            bubble_o = 4'b0001;
        end else if (branch_i == 1) begin
            stall_o = 4'b0000;
            bubble_o = 4'b1100;
        end else if ((id_exe_rf_waddr_i != 0 && (rf_raddr_a_i == id_exe_rf_waddr_i || rf_raddr_b_i == id_exe_rf_waddr_i)) || (exe_mem_rf_waddr_i != 0 && (rf_raddr_a_i == exe_mem_rf_waddr_i || rf_raddr_b_i == exe_mem_rf_waddr_i)) || (rf_waddr_i != 0 && (rf_raddr_a_i == rf_waddr_i || rf_raddr_b_i == rf_waddr_i))) begin
            stall_o = 4'b1000;
            bubble_o = 4'b0100;
        end else if (if_ack_i == 0) begin
            stall_o = 4'b0000;
            bubble_o = 4'b1000;
        end else begin
            stall_o = 4'b0000;
            bubble_o = 4'b0000;
        end
    end
    
endmodule