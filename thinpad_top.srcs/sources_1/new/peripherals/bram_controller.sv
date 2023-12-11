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
    
    input wire [BRAM_DATA_WIDTH-1:0] bram_data_i,
    output reg  [BRAM_DATA_WIDTH-1:0] bram_data_o,
    output reg  [BRAM_ADDR_WIDTH-1:0] bram_addr_a_o,
    output reg  [BRAM_ADDR_WIDTH-1:0] bram_addr_b_o,
    output reg  [BRAM_DATA_WIDTH/8-1:0] bram_wea_o
);

    typedef enum logic [1:0] { 
        STATE_IDLE,
        STATE_READ,
        STATE_WRITE
    } state_t;
    state_t state;

    logic [BRAM_ADDR_WIDTH-1:0] addr_a;
    logic [BRAM_ADDR_WIDTH-1:0] addr_b;
    logic [BRAM_DATA_WIDTH-1:0] w_data;
    logic [BRAM_DATA_WIDTH-1:0] r_data;
    logic [1:0] wb_adr_sel;
    logic [DATA_WIDTH-1:0] wb_dat_tmp;

    assign addr_a = wb_adr_i[BRAM_ADDR_WIDTH-1:0];
    assign addr_b = wb_adr_i[BRAM_ADDR_WIDTH-1:0];
    assign w_data = wb_dat_i[BRAM_DATA_WIDTH-1:0];
    assign wb_adr_sel = wb_adr_i[1:0];
    assign wb_dat_tmp = $signed(r_data) << (wb_adr_sel << 3);

    always_comb begin
        bram_addr_a_o = 0;
        bram_addr_b_o = 0;
        bram_wea_o = 0;
        r_data = bram_data_i;
        case (state)
            STATE_IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (wb_we_i) begin
                        bram_addr_a_o = addr_a;
                        bram_wea_o = 1'b1;
                    end else begin
                        bram_addr_b_o = addr_b;
                        bram_wea_o = 1'b0;
                    end
                end
            end
            STATE_READ: begin
                bram_addr_a_o = addr_a;
                bram_wea_o = 1'b0;
            end
            STATE_WRITE: begin
                bram_addr_b_o = addr_b;
                bram_wea_o = 1'b1;
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
                        if (wb_we_i) begin
                            bram_data_o <= w_data;
                            state <= STATE_WRITE;
                        end else begin
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
                STATE_WRITE: begin
                    wb_ack_o <= 1'b0;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule