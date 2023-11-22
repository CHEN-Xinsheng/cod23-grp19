module sram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,

    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 32,

    localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8,
    localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
) (
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    // sram interface
    output reg [SRAM_ADDR_WIDTH-1:0] sram_addr,
    inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
    output reg sram_ce_n,
    output reg sram_oe_n,
    output reg sram_we_n,
    output reg [SRAM_BYTES-1:0] sram_be_n
);

  // TODO: ?? SRAM ???

  // tri-state gate
  wire [SRAM_DATA_WIDTH-1:0] sram_data_i;
  reg  [SRAM_DATA_WIDTH-1:0] sram_data_o;
  reg  sram_is_writing;
  assign sram_data = sram_is_writing ? sram_data_o : {SRAM_DATA_WIDTH{1'bz}};
  assign sram_data_i = sram_data;

  // states definition
  typedef enum logic [2:0] {
    IDLE,
    READ,
    WRITE,
    WRITE_2
  } state_t;
  state_t state, next_state;

  // state transfer
  always_ff @ (posedge clk_i, posedge rst_i) begin
    if (rst_i) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  // next state
  always_comb begin
    next_state = IDLE;  // default
    case (state)
      IDLE: begin
        if (wb_cyc_i && wb_stb_i) begin
          if (wb_we_i) next_state = WRITE;
          else         next_state = READ;
        end
      end
      READ:    next_state = IDLE;
      WRITE:   next_state = WRITE_2;
      WRITE_2: next_state = IDLE;
    endcase
  end

  always_comb begin
    // default
    sram_addr = wb_adr_i[SRAM_ADDR_WIDTH+1: 2];  // always
    sram_ce_n = 1'b1;
    sram_oe_n = 1'b1;
    sram_we_n = 1'b1;
    sram_be_n = ~wb_sel_i;  // always
    sram_is_writing = 1'b0;
    sram_data_o = wb_dat_i;  // always
    wb_ack_o = 1'b0;
    wb_dat_o = {DATA_WIDTH{1'b0}};

    // cases
    case (state)

      IDLE: begin
        if (wb_cyc_i && wb_stb_i) begin
          wb_ack_o = 1'b0;
          sram_ce_n = 1'b0;
          if (wb_we_i) begin  // write
            sram_is_writing = 1'b1;
          end else begin   // read
            sram_oe_n = 1'b0;
          end
        end
      end

      READ: begin
        sram_ce_n = 1'b0;
        sram_oe_n = 1'b0;
        wb_ack_o = 1'b1;
        wb_dat_o = sram_data_i;
      end

      WRITE: begin
        sram_ce_n = 1'b0;
        sram_we_n = 1'b0;
        sram_is_writing = 1'b1;
      end

      WRITE_2: begin
        sram_ce_n = 1'b0;
        sram_we_n = 1'b1;
        wb_ack_o = 1'b1;
      end

    endcase
  end

  // function automatic logic[DATA_WIDTH-1:0]  modify_z_to_0 (logic[SRAM_DATA_WIDTH-1:0] in);
  //   logic[DATA_WIDTH-1:0] result;
  //   for (int i = 0; i < DATA_WIDTH; i++) begin
  //     if (i < SRAM_DATA_WIDTH && in[i] !== 1'bZ)
  //       result[i] = in[i];
  //     else
  //       result[i] = 1'b0;
  //   end
  //   return result;
  // endfunction

endmodule
