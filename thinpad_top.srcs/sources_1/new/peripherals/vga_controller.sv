module vga_controller (
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
    
    input wire [7:0] bram_0_dat_i,
    input wire [7:0] bram_1_dat_i,
    output reg [7:0] bram_dat_o

    input wire vga_ack_i
    output reg [2:0] vga_scale_o,
);

    typedef enum logic [1:0] { 
        STATE_IDLE,
        STATE_READ,
        STATE_WRITE,
        STATE_DONE
    } state_t;

    state_t state;

    reg [31:0] vga_scale_reg = 32'h0000_0003;  // 3/1
    reg [31:0] bram_which_reg = 32'h0000_0000;   // 0/1

    logic [2:0] vga_scale;
    logic bram_which;
    logic wb_dat_tmp;

    assign vga_scale_o = vga_scale;
    assign bram_dat_o = bram_which ? bram_1_dat_i : bram_0_dat_i;

    always_comb begin
        if (wb_adr_i[7:0] == 8'h00) begin
            wb_dat_tmp = vga_scale_reg;
        end else if (wb_adr_i[7:0] == 8'h04) begin
            wb_dat_tmp = bram_which_reg;
        end else begin
            wb_dat_tmp = 32'h0000_1111;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (wb_cyc_i && wb_stb_i) begin
                        if (wb_we_i) begin
                            if (wb_adr_i[7:0] == 8'h00) begin
                                vga_scale_reg <= wb_dat_i;
                            end else if (wb_adr_i[7:0] == 8'h04) begin
                                bram_which_reg <= wb_dat_i;
                            end
                            wb_ack_o <= 1'b0;
                            state <= STATE_WRITE;
                        end else begin
                            wb_dat_o <= wb_dat_tmp;
                            wb_ack_o <= 1'b1;
                            state <= STATE_READ;
                        end
                    end
                end
                STATE_READ: begin
                    wb_ack_o <= 1'b0;
                    state <= STATE_IDLE;
                end
                STATE_WRITE: begin
                    if (vga_ack_i) begin
                        wb_ack_o <= 1'b1;
                        vga_scale <= vga_scale_reg[2:0];
                        bram_which <= bram_which_reg[0];
                        state <= STATE_DONE;
                    end else begin
                        wb_ack_o <= 1'b0;
                        state <= STATE_WRITE;
                    end
                end
                STATE_DONE: begin
                    wb_ack_o <= 1'b0;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule