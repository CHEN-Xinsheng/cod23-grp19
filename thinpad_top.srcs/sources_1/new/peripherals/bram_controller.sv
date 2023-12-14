`include "../header.sv"


module bram_controller (
    input wire clk,
    input wire rst,

    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    // read BRAM
    output reg [BRAM_ADDR_WIDTH-1:0]   bram_addr_b_o,
    input wire [BRAM_DATA_WIDTH-1:0]   bram_rdata_b_i,
    // write BRAM
    output reg [BRAM_ADDR_WIDTH-1:0]   bram_addr_a_o,
    output reg [BRAM_DATA_WIDTH-1:0]   bram_wdata_a_o,
    output reg [BRAM_DATA_WIDTH/8-1:0] bram_we_a_o
);

    typedef enum logic [1:0] { 
        STATE_IDLE,
        STATE_READ,
        STATE_WRITE
    } state_t;
    state_t state;


    // wishbone output
    wire [1:0] wb_adr_sel = wb_adr_i[1:0];
    assign wb_dat_o       = bram_rdata_b_i << (wb_adr_sel << 3);

    // BRAM write
    assign bram_addr_a_o  = wb_adr_i[BRAM_ADDR_WIDTH-1:0];
    assign bram_wdata_a_o = wb_dat_i[BRAM_DATA_WIDTH-1:0];
    // BRAM read
    assign bram_addr_b_o  = wb_adr_i[BRAM_ADDR_WIDTH-1:0];

    always_comb begin
        // default
        bram_we_a_o = 0;
        wb_ack_o = 1'b0;
        // cases
        case (state)
            STATE_IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (wb_we_i) begin
                        bram_we_a_o = 1'b1;
                    end else begin
                        bram_we_a_o = 1'b0;
                    end
                end
            end
            STATE_READ: begin
                wb_ack_o = 1'b1;
            end
            STATE_WRITE: begin
                wb_ack_o = 1'b1;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (wb_cyc_i && wb_stb_i) begin
                        if (wb_we_i) begin
                            state <= STATE_WRITE;
                        end else begin
                            state <= STATE_READ;
                        end
                    end
                end
                STATE_READ: begin
                    state <= STATE_IDLE;
                end
                STATE_WRITE: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule