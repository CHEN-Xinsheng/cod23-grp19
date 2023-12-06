`include "../header.sv"


module MEM (
    input wire                          clk,
    input wire                          rst,

    input wire                          mem_en_i,
    input wire [ADDR_WIDTH-1:0]         mem_addr_i,
    input wire                          rf_wen_i,
    input wire [REG_ADDR_WIDTH-1:0]     rf_waddr_i,
    output reg [DATA_WIDTH-1:0]         rf_wdata_o,
    output reg                          rf_wen_o,
    output reg [REG_ADDR_WIDTH-1:0]     rf_waddr_o,
    input wire                          mem_we_i,
    input wire [DATA_WIDTH/8-1:0]       mem_sel_i,
    input wire [ADDR_WIDTH-1:0]         mem_wdata_i,

    output reg                          wb_cyc_o,
    output reg                          wb_stb_o,
    input wire                          wb_ack_i,
    output reg [ADDR_WIDTH-1:0]         wb_adr_o,
    output reg [DATA_WIDTH-1:0]         wb_dat_o,
    input wire [DATA_WIDTH-1:0]         wb_dat_i,
    output reg [DATA_WIDTH/8-1:0]       wb_sel_o,
    output reg                          wb_we_o,
    input wire                          stall_i,
    input wire                          bubble_i,

    // debug
    input wire [ADDR_WIDTH-1: 0] pc_now_i,
    output reg [ADDR_WIDTH-1: 0] pc_now_o
);

    reg [31:0] lb_data;
    assign lb_data = wb_dat_i >> ((mem_addr_i << 3) & 32'h1f);

    always_ff @(posedge clk) begin
        if (rst) begin
            wb_stb_o <= 1'b0;
            rf_wdata_o <= 32'b0;
            rf_wen_o <= 1'b0;
            rf_waddr_o <= 5'b0;
            pc_now_o <= {ADDR_WIDTH{1'b0}};
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
                pc_now_o <= {ADDR_WIDTH{1'b0}};
            end else begin
                if (mem_en_i) begin
                    wb_stb_o <= 1'b0;
                    if (mem_we_i == 0) begin
                        if (wb_sel_o == 4'b1111) begin
                            rf_wdata_o <= wb_dat_i;
                        end else begin
                            rf_wdata_o <= {{24{lb_data[7]}}, lb_data[7:0]};
                        end
                        rf_wen_o <= rf_wen_i;
                        rf_waddr_o <= rf_waddr_i;
                    end
                end else begin
                    wb_stb_o <= 1'b0;
                    rf_wdata_o <= mem_addr_i;
                    rf_wen_o <= rf_wen_i;
                    rf_waddr_o <= rf_waddr_i;
                end
                pc_now_o <= pc_now_i;
            end
        end
    end

    assign wb_cyc_o = wb_stb_o;
    assign wb_adr_o = mem_addr_i;
    assign wb_dat_o = mem_sel_i == 4'b1111 ? mem_wdata_i : (mem_wdata_i << ((mem_addr_i << 3) & 32'h1f));
    assign wb_sel_o = mem_sel_i == 4'b1111 ? 4'b1111 : (mem_sel_i << mem_addr_i[1:0]);
    assign wb_we_o = mem_we_i;

endmodule