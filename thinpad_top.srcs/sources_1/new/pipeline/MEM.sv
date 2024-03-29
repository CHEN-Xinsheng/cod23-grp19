`include "../header.sv"


module MEM (
    input wire                          clk,
    input wire                          rst,

    input wire [DATA_WIDTH-1:0]         rf_wdata_i,
    input wire                          rf_wen_i,
    input wire [REG_ADDR_WIDTH-1:0]     rf_waddr_i,
    output reg [DATA_WIDTH-1:0]         rf_wdata_o,
    output reg                          rf_wen_o,
    output reg [REG_ADDR_WIDTH-1:0]     rf_waddr_o,
    input wire                          mem_re_i,
    input wire                          mem_we_i,
    input wire [ADDR_WIDTH-1:0]         mem_addr_i,
    input wire [DATA_WIDTH/8-1:0]       mem_sel_i,
    input wire [ADDR_WIDTH-1:0]         mem_wdata_i,
    input wire                          load_type_i,
    input wire [DATA_WIDTH-1:0]         inst_i,

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

    input wire  [2:0]                   csr_op_i,
    input wire  [DATA_WIDTH-1:0]        csr_data_i,
    output reg  [CSR_ADDR_WIDTH-1:0]    csr_raddr_o,
    input wire  [DATA_WIDTH-1:0]        csr_rdata_i,
    output reg  [CSR_ADDR_WIDTH-1:0]    csr_waddr_o,
    output reg  [DATA_WIDTH-1:0]        csr_wdata_o,
    output reg                          csr_we_o

    // // debug
    // input wire [ADDR_WIDTH-1: 0] pc_now_i,
    // output reg [ADDR_WIDTH-1: 0] pc_now_o
);

    always_comb begin
        csr_raddr_o = inst_i[31:20];
        csr_waddr_o = inst_i[31:20];
        // if (inst_i[19:15] == 5'b0) begin
        //     csr_wdata_o = csr_rdata_i;
        //     csr_we_o = 1'b0;
        // end else begin
            if (csr_op_i[1:0] == 2'b01) begin   // CSRRW (001), CSRRWI (101)
                csr_wdata_o = csr_data_i;
            //    if (alu_y_i != 0) begin
                csr_we_o = 1'b1;
            //    end else begin
            //        csr_we_o = 1'b0;
            //    end
            end else if (csr_op_i[1:0] == 2'b10) begin   // CSRRS (010), CSRRSI (110)
                csr_wdata_o = csr_rdata_i | csr_data_i;
                csr_we_o = 1'b1;
            end else if (csr_op_i[1:0] == 2'b11) begin   // CSRRC (011), CSRRCI (111), 
                csr_wdata_o = csr_rdata_i & ~csr_data_i;
                csr_we_o = 1'b1;
            end else begin
                csr_wdata_o = csr_rdata_i;
                csr_we_o = 1'b0;
            end
        // end
    end

    reg [31:0] lb_data;
    assign lb_data = wb_dat_i >> ((mem_addr_i << 3) & 32'h1f);

    always_ff @(posedge clk) begin
        if (rst) begin
            wb_stb_o <= 1'b0;
        end else begin
            if (stall_i) begin
            end else if (bubble_i) begin
                if (mem_re_i || mem_we_i) begin
                    wb_stb_o <= 1'b1;
                end else begin
                    wb_stb_o <= 1'b0;
                end
            end else begin
                wb_stb_o <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            rf_wdata_o <= 32'b0;
            rf_wen_o <= 1'b0;
            rf_waddr_o <= 5'b0;
            // pc_now_o <= {ADDR_WIDTH{1'b0}};  // [debug]
        end else begin
            if (stall_i) begin
            end else if (bubble_i) begin
                rf_wdata_o <= 32'b0;
                rf_wen_o <= 0;
                rf_waddr_o <= 5'b0;
                // pc_now_o <= {ADDR_WIDTH{1'b0}};  // [debug]
            end else begin
                if (mem_re_i) begin
                    if (mem_sel_i == 4'b1111) begin
                        rf_wdata_o <= wb_dat_i;
                    end else if (mem_sel_i == 4'b0001) begin
                        if (load_type_i) begin
                            rf_wdata_o <= {{24{lb_data[7]}}, lb_data[7:0]};
                        end else begin
                            rf_wdata_o <= {24'b0, lb_data[7:0]};
                        end
                    end else if (mem_sel_i == 4'b0011) begin
                        if (load_type_i) begin
                            rf_wdata_o <= {{16{lb_data[15]}}, lb_data[15:0]};
                        end else begin
                            rf_wdata_o <= {16'b0, lb_data[15:0]};
                        end
                    end
                end else if (csr_op_i) begin
                    rf_wdata_o <= csr_rdata_i;
                end else begin
                    rf_wdata_o <= rf_wdata_i;
                end
                rf_wen_o <= rf_wen_i;
                rf_waddr_o <= rf_waddr_i;
                // pc_now_o <= pc_now_i;;  // [debug]
            end
        end
    end

    assign wb_cyc_o = wb_stb_o;
    assign wb_adr_o = mem_addr_i;
    assign wb_we_o = mem_we_i;

    always_comb begin
        if (mem_sel_i == 4'b1111) begin
            wb_sel_o = 4'b1111;
            wb_dat_o = mem_wdata_i;
        end else if (mem_sel_i == 4'b0011) begin
            wb_sel_o = (mem_sel_i << mem_addr_i[1:0]);
            wb_dat_o = (mem_wdata_i << ((mem_addr_i << 3) & 32'b000011000));
        end else if (mem_sel_i == 4'b0001) begin
            wb_sel_o = (mem_sel_i << mem_addr_i[1:0]);
            wb_dat_o = (mem_wdata_i << ((mem_addr_i << 3) & 32'b000011000));
        end else begin
            wb_sel_o = 4'b0000;
            wb_dat_o = 32'b0;
        end

    end

endmodule