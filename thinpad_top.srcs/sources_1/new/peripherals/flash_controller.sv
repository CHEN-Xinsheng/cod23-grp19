`include "../header.sv"


module flash_controller (
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
    
    output reg [FLASH_ADDR_WIDTH-1:0] flash_a_o,
    inout wire [15:0] flash_d,
    output reg flash_rp_o,
    output reg flash_ce_o,
    output reg flash_oe_o
);

    typedef enum logic [1:0] { 
        STATE_IDLE,
        STATE_READ
    } state_t;
    state_t state;

    logic [FLASH_ADDR_WIDTH-1:0] flash_addr;
    logic [FLASH_DATA_WIDTH-1:0] flash_data;
    logic [1:0] wb_adr_sel;
    logic [DATA_WIDTH-1:0] wb_dat_tmp;

    assign flash_d = 8'bz;   // 只读
    assign flash_addr = wb_adr_i[FLASH_ADDR_WIDTH-1:0];
    assign wb_adr_sel = wb_adr_i[1:0];
    assign flash_data = flash_d[FLASH_DATA_WIDTH-1:0];
    assign wb_dat_tmp = $signed(wb_dat_i) << (wb_adr_sel << 3);

    always_comb begin
        flash_rp_o = 1'b1;
        flash_ce_o = 1'b1;
        flash_oe_o = 1'b1;
        flash_a_o = 0;

        case (state)
            STATE_IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (!wb_we_i) begin
                        flash_ce_o = 1'b0;
                        flash_oe_o = 1'b0;
                        flash_a_o = flash_addr;
                    end
                end
            end
            STATE_READ: begin
                flash_ce_o = 1'b0;
                flash_oe_o = 1'b0;
                flash_a_o = flash_addr;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            wb_ack_o <= 1'b0;
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (wb_cyc_i && wb_stb_i) begin
                        if (!wb_we_i) begin
                            wb_dat_o <= wb_dat_tmp;
                            state <= STATE_READ;
                        end
                        wb_ack_o <= 1'b1;
                    end
                end
                STATE_READ: begin
                    wb_ack_o <= 1'b0;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule