`include "../header.sv"


module gpio_controller (
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
    
    input wire [31:0] dip_sw_i,
    input wire [3:0] touch_btn_i,
    input wire push_btn_i
);

    typedef enum logic [1:0] { 
        STATE_IDLE,
        STATE_READ
    } state_t;
    state_t state;

    logic [DATA_WIDTH-1:0] gpio_data;
    logic [DATA_WIDTH-1:0] btn;
    logic [DATA_WIDTH-1:0] wb_dat_tmp;
    
    assign gpio_data = dip_sw_i;
    assign btn = {27'b0, touch_btn_i, push_btn_i};

    always_comb begin
        if (wb_adr_i[7:0] == 8'h00) begin
            wb_dat_tmp = gpio_data;
        end else if (wb_adr_i[7:0] == 8'h04) begin
            wb_dat_tmp = btn;
        end else begin
            wb_dat_tmp = 32'h0000_1111;
        end
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