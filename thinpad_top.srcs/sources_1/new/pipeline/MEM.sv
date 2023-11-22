module MEM #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire rst,
    input wire mem_en_i,
    input wire [31:0] alu_result_i,
    input wire rf_wen_i,
    input wire [4:0] rf_waddr_i,
    output reg [31:0] rf_wdata_o,
    output reg rf_wen_o,
    output reg [4:0] rf_waddr_o,
    input wire mem_we_i,
    input wire [3:0] mem_sel_i,
    input wire [31:0] mem_dat_o_i,

    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o,
    input wire stall_i,
    input wire bubble_i
);

    always_ff @(posedge clk) begin
        if (rst) begin
            wb_stb_o <= 1'b0;
            rf_wdata_o <= 32'b0;
            rf_wen_o <= 1'b0;
            rf_waddr_o <= 5'b0;
        end else begin
            if (stall_i) begin
            end else if (bubble_i) begin
                rf_wdata_o <= 32'b0;
                rf_wen_o <= 0;
                rf_waddr_o <= 5'b0;
                if (mem_en_i) begin
                    wb_stb_o <= 1'b1;
                end else begin
                    wb_stb_o <= 1'b0;
                end
            end else begin
                if (mem_en_i) begin
                    wb_stb_o <= 1'b0;
                    if (mem_we_i == 0) begin
                        rf_wdata_o <= {{24{wb_dat_i[7]}}, wb_dat_i[7:0]};
                        rf_wen_o <= rf_wen_i;
                        rf_waddr_o <= rf_waddr_i;
                    end
                end else begin
                    wb_stb_o <= 1'b0;
                    rf_wdata_o <= alu_result_i;
                    rf_wen_o <= rf_wen_i;
                    rf_waddr_o <= rf_waddr_i;
                end
            end
        end
    end

    assign wb_cyc_o = wb_stb_o;
    assign wb_adr_o = alu_result_i;
    assign wb_dat_o = mem_dat_o_i;
    assign wb_sel_o = mem_sel_i;
    assign wb_we_o = mem_we_i;

endmodule