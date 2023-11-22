module IF #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire rst,

    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o,
    output reg [31:0] inst_o,
    output reg [31:0] pc_now_o,
    input wire branch_i,
    input wire [31:0] pc_next_i,
    input wire stall_i,
    input wire bubble_i
);
    
    reg [ADDR_WIDTH-1:0] pc;
    reg [ADDR_WIDTH-1:0] pc_cached;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 32'h80000000;
            pc_cached <= 32'h0;
            wb_stb_o <= 1'b0;
            inst_o <= 32'h0;
            pc_now_o <= 32'h0;
        end else begin
            if (stall_i) begin
                if (wb_ack_i) begin
                    wb_stb_o <= 1'b0;
                end
            end else if (bubble_i) begin
                inst_o <= 32'h0;
                pc_now_o <= 32'h0;
                wb_stb_o <= 1'b1;
                if (branch_i) begin
                    pc_cached <= pc_next_i;
                end
            end else begin
                wb_stb_o <= 1'b0;
                if (pc_cached != 0) begin
                    pc <= pc_cached;
                    pc_cached <= 32'h0;
                    inst_o <= 32'h0;
                    pc_now_o <= 32'h0;
                end else begin
                    inst_o <= wb_dat_i;
                    pc_now_o <= pc;
                    pc <= pc + 4;
                end
            end
        end
    end

    assign wb_cyc_o = wb_stb_o;
    assign wb_adr_o = pc;
    assign wb_dat_o = {DATA_WIDTH{1'b0}};
    assign wb_sel_o = {DATA_WIDTH/8{1'b1}};
    assign wb_we_o = 1'b0;

endmodule