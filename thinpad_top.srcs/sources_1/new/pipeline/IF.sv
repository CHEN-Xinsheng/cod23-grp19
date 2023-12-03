`include "../header.sv"


module IF (
    input wire clk,
    input wire rst,
    // input wire fence_i,

    // output reg wb_cyc_o,
    // output reg wb_stb_o,
    // input wire wb_ack_i,
    // output reg [ADDR_WIDTH-1:0] wb_adr_o,
    // output reg [DATA_WIDTH-1:0] wb_dat_o,
    // input wire [DATA_WIDTH-1:0] wb_dat_i,
    // output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    // output reg wb_we_o,

    output reg [31:0] inst_o,
    output reg [31:0] pc_now_o,
    input wire branch_i,
    input wire [31:0] pc_next_i,
    input wire icache_ack_i,
    input wire [31:0] inst_i,
    output reg [31:0] pc_o,
    input wire branch_taken_i,
    input wire [31:0] pc_pred_i,
    input wire [31:0] pc_true_i,
    // output reg [31:0] pc_cached_o,
    input wire stall_i,
    input wire bubble_i
);
    
    reg [ADDR_WIDTH-1:0] pc;
    reg [ADDR_WIDTH-1:0] pc_cached;

    assign pc_o = pc;
//    assign pc_cached_o = pc_cached;

    // logic icache_ack;
    // logic [31:0] inst;

     always_ff @(posedge clk) begin
        if (rst) begin
            inst_o <= 32'h0;
            pc_now_o <= 32'h0;
        end else begin
            if (stall_i) begin
            end else if (bubble_i) begin
                inst_o <= 32'h0;
                pc_now_o <= 32'h0;
            end else if (icache_ack_i) begin
                if (pc_cached != 0) begin
                    inst_o <= 32'h0;
                    pc_now_o <= 32'h0;
                end else begin
                    inst_o <= inst_i;
                    pc_now_o <= pc;
                end
            end else begin
                inst_o <= 32'h0;
                pc_now_o <= 32'h0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 32'h80000000;
            pc_cached <= 32'h0;
        end else begin
            if (stall_i) begin
            end else if (~branch_taken_i) begin
                if (icache_ack_i) begin 
                    pc <= pc_true_i;
                end else begin 
                    pc_cached <= pc_true_i;
                end
            end else begin
                if (icache_ack_i) begin 
                    if (pc_cached != 0) begin
                        pc <= pc_cached;
                        pc_cached <= 32'h0;
                    end else begin
                        pc <= pc_pred_i;
                    end
                end
            end
        end
    end

    // icache icache (
    //     .clk(clk),
    //     .rst(rst),
    //     .fence_i(fence_i),
    //     .pc_i(pc),
    //     .enable_i(1'b1),
    //     .wb_cyc_o(wb_cyc_o),
    //     .wb_stb_o(wb_stb_o),
    //     .wb_ack_i(wb_ack_i),
    //     .wb_adr_o(wb_adr_o),
    //     .wb_dat_o(wb_dat_o),
    //     .wb_dat_i(wb_dat_i),
    //     .wb_sel_o(wb_sel_o),
    //     .wb_we_o(wb_we_o),
    //     .inst_o(inst),
    //     .icache_ack_o(icache_ack)
    // );

endmodule