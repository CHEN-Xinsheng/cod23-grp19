`timescale 1ns / 1ps
`include "../header.sv"
`define  BRAM_ADDR_START 17'b0

//
// WIDTH: bits in register hdata & vdata
// HSIZE: horizontal size of visible field 
// HFP: horizontal front of pulse
// HSP: horizontal stop of pulse
// HMAX: horizontal max size of value
// VSIZE: vertical size of visible field 
// VFP: vertical front of pulse
// VSP: vertical stop of pulse
// VMAX: vertical max size of value
// HSPP: horizontal synchro pulse polarity (0 - negative, 1 - positive)
// VSPP: vertical synchro pulse polarity (0 - negative, 1 - positive)
//
module vga #(
    parameter WIDTH = 0,
    HSIZE = 0,
    HFP = 0,
    HSP = 0,
    HMAX = 0,
    VSIZE = 0,
    VFP = 0,
    VSP = 0,
    VMAX = 0,
    HSPP = 0,
    VSPP = 0
) (
    input wire vga_clk,
    input wire sys_rst,
    input wire [2:0] vga_scale_i,

    output reg [BRAM_ADDR_WIDTH-1:0]  bram_addr_o,
    input wire [BRAM_DATA_WIDTH-1:0]  bram_data_i,
    output reg vga_ack_o,

    output reg [2:0] video_red_o,
    output reg [2:0] video_green_o,
    output reg [1:0] video_blue_o,
    output reg video_hsync_o,
    output reg video_vsync_o,
    output reg video_de_o
);

  reg [WIDTH-1:0] hdata;
  reg [WIDTH-1:0] vdata;
  logic [7:0] pixel;
  logic [BRAM_ADDR_WIDTH-1:0] pixel_width;
  logic [BRAM_ADDR_WIDTH-1:0] bram_addr_x;
  logic [BRAM_ADDR_WIDTH-1:0] bram_addr_y;

  assign pixel_width = HSIZE >> vga_scale_i;
  assign bram_addr_x = hdata >> vga_scale_i;
  assign bram_addr_y = vdata >> vga_scale_i;
  assign bram_addr_o = `BRAM_ADDR_START + (bram_addr_y * pixel_width) + bram_addr_x;

  always @ (posedge vga_clk) begin
    if (sys_rst) begin
        hdata <= 0;
        vdata <= 0;
    end else begin
        hdata <= (hdata == (HMAX - 1)) ? 0 : hdata + 1;
        vdata <= (hdata == (HMAX - 1)) ? (vdata == (VMAX - 1) ? 0 : vdata + 1) : vdata;
    end
  end

  always_ff @ (posedge vga_clk) begin
    if (hdata < HSIZE && vdata < VSIZE) begin
      pixel <= bram_data_i;
      vga_ack_o <= 1'b0;
    end else begin
      if (vdata == VMAX - 1 && hdata > HMAX - 15) begin
        vga_ack_o <= 1'b1;
      end else begin
        vga_ack_o <= 1'b0;
      end
    end
  end

  assign video_red_o   = pixel[7:5];
  assign video_green_o = pixel[4:2];
  assign video_blue_o  = pixel[1:0];
  assign video_hsync_o = ((hdata >= HFP) && (hdata < HSP)) ? HSPP : !HSPP;
  assign video_vsync_o = ((vdata >= VFP) && (vdata < VSP)) ? VSPP : !VSPP;
  assign video_de_o    = ((hdata < HSIZE) & (vdata < VSIZE));

endmodule
