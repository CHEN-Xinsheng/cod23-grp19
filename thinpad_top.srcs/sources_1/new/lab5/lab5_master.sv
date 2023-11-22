module lab5_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    // TODO: 添加需要的控制信号，例如按键开关？
    input wire [31:0] dip_sw,
    output reg [15:0] leds,

    // wishbone master
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o
);

  // TODO: 实现实验 5 的内存+串口 Master
  typedef enum logic [3:0] {
    STATE_IDLE,
    READ_WAIT_ACTION,
    READ_WAIT_CHECK,
    READ_DATA_ACTION,
    READ_DATA_DONE,
    WRITE_SRAM_ACTION,
    WRITE_SRAM_DONE,
    WRITE_WAIT_ACTION,
    WRITE_WAIT_CHECK,
    WRITE_DATA_ACTION,
    WRITE_DATA_DONE
  } state_t;

  state_t state;
  reg [3:0] count;
  reg [ADDR_WIDTH-1:0] addr;
  reg [DATA_WIDTH-1:0] data;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      state <= STATE_IDLE;
      count <= 0;
      addr <= dip_sw;
      wb_cyc_o <= 0;
      wb_stb_o <= 0;
      wb_adr_o <= 0;
      wb_dat_o <= 0;
      wb_sel_o <= 0;
      wb_we_o <= 0;
      leds <= 0;
    end
    else begin
      case (state)
        STATE_IDLE: begin
          if (count < 10) begin
            wb_cyc_o <= 1;
            wb_stb_o <= 1;
            wb_adr_o <= 32'h10000005;
            wb_sel_o <= 4'b0010;
            wb_we_o <= 0;
            state <= READ_WAIT_ACTION;
            leds <= 1;
          end
        end
        READ_WAIT_ACTION: begin
          if (wb_ack_i) begin
            wb_cyc_o <= 0;
            wb_stb_o <= 0;
            state <= READ_WAIT_CHECK;
            leds <= 2;
          end
        end
        READ_WAIT_CHECK: begin
          if (wb_dat_i [8]) begin
            wb_cyc_o <= 1;
            wb_stb_o <= 1;
            wb_adr_o <= 32'h10000000;
            wb_sel_o <= 4'b0001;
            state <= READ_DATA_ACTION;
            leds <= 3;
          end 
          else begin
            wb_cyc_o <= 1;
            wb_stb_o <= 1;
            state <= READ_WAIT_ACTION;
            leds <= 1;
          end
        end
        READ_DATA_ACTION: begin
          if (wb_ack_i) begin
            wb_cyc_o <= 0;
            wb_stb_o <= 0;
            data <= wb_dat_i;
            state <= READ_DATA_DONE;
            leds <= 4;
          end
        end
        READ_DATA_DONE: begin
          wb_cyc_o <= 1;
          wb_stb_o <= 1;
          wb_adr_o <= addr;
          wb_dat_o <= data;
          wb_sel_o <= 4'b0001;
          wb_we_o <= 1;
          state <= WRITE_SRAM_ACTION;
          leds <= 5;
        end
        WRITE_SRAM_ACTION: begin
          if (wb_ack_i) begin
            wb_cyc_o <= 0;
            wb_stb_o <= 0;
            state <= WRITE_SRAM_DONE;
            leds <= 6;
          end
        end
        WRITE_SRAM_DONE: begin
          wb_cyc_o <= 1;
          wb_stb_o <= 1;
          wb_adr_o <= 32'h10000005;
          wb_sel_o <= 4'b0010;
          wb_we_o <= 0;
          state <= WRITE_WAIT_ACTION;
          leds <= 7;
        end
        WRITE_WAIT_ACTION: begin
          if (wb_ack_i) begin
            wb_cyc_o <= 0;
            wb_stb_o <= 0;
            state <= WRITE_WAIT_CHECK;
            leds <= 8;
          end
        end
        WRITE_WAIT_CHECK: begin
          if (wb_dat_i [13]) begin
            wb_cyc_o <= 1;
            wb_stb_o <= 1;
            wb_adr_o <= 32'h10000000;
            wb_dat_o <= data;
            wb_sel_o <= 4'b0001;
            wb_we_o <= 1;
            state <= WRITE_DATA_ACTION;
            leds <= 9;
          end
          else begin
            wb_cyc_o <= 1;
            wb_stb_o <= 1;
            state <= WRITE_WAIT_ACTION;
            leds <= 7;
          end
        end
        WRITE_DATA_ACTION: begin
          if (wb_ack_i) begin
            wb_cyc_o <= 0;
            wb_stb_o <= 0;
            state <= WRITE_DATA_DONE;
            leds <= 10;
          end
        end
        WRITE_DATA_DONE: begin
          count <= count + 1;
          addr <= addr + 4;
          state <= STATE_IDLE;
          leds <= 0;
        end
      endcase
    end
  end

endmodule
