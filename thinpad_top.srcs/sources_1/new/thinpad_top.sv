`default_nettype none
`include "header.sv"


module thinpad_top (
    input wire clk_50M,     // 50MHz ćśéčžĺĽ
    input wire clk_11M0592, // 11.0592MHz ćśéčžĺĽďźĺ¤ç¨ďźĺŻä¸ç¨ďź

    input wire push_btn,  // BTN5 按钮�?????????关，带消抖电路，按下时为 1
    input wire reset_btn, // BTN6 复位按钮，带消抖电路，按下时�????????? 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4，按钮开关，按下时为 1
    input  wire [31:0] dip_sw,     // 32 位拨码开关，拨到“ON”时�????????? 1
    output wire [15:0] leds,       // 16 �????????? LED，输出时 1 点亮
    output wire [ 7:0] dpy0,       // 数码管低位信号，包括小数点，输出 1 点亮
    output wire [ 7:0] dpy1,       // 数码管高位信号，包括小数点，输出 1 点亮

    // CPLD 串口控制器信�?????????
    output wire uart_rdn,        // 读串口信号，低有�?????????
    output wire uart_wrn,        // 写串口信号，低有�?????????
    input  wire uart_dataready,  // 串口数据准备�?????????
    input  wire uart_tbre,       // 发�?�数据标�?????????
    input  wire uart_tsre,       // 数据发�?�完毕标�?????????

    // BaseRAM 信号
    inout wire [31:0] base_ram_data,  // BaseRAM 数据，低 8 位与 CPLD 串口控制器共�?????????
    output wire [19:0] base_ram_addr,  // BaseRAM 地址
    output wire [3:0] base_ram_be_n,  // BaseRAM 字节使能，低有效。如果不使用字节使能，请保持�????????? 0
    output wire base_ram_ce_n,  // BaseRAM 片�?�，低有�?????????
    output wire base_ram_oe_n,  // BaseRAM 读使能，低有�?????????
    output wire base_ram_we_n,  // BaseRAM 写使能，低有�?????????

    // ExtRAM 信号
    inout wire [31:0] ext_ram_data,  // ExtRAM 数据
    output wire [19:0] ext_ram_addr,  // ExtRAM 地址
    output wire [3:0] ext_ram_be_n,  // ExtRAM 字节使能，低有效。如果不使用字节使能，请保持�????????? 0
    output wire ext_ram_ce_n,  // ExtRAM 片�?�，低有�?????????
    output wire ext_ram_oe_n,  // ExtRAM 读使能，低有�?????????
    output wire ext_ram_we_n,  // ExtRAM 写使能，低有�?????????

    // 直连串口信号
    output wire txd,  // 直连串口发�?�端
    input  wire rxd,  // 直连串口接收�?????????

    // Flash 存储器信号，参�?? JS28F640 芯片手册
    output wire [22:0] flash_a,  // Flash 地址，a0 仅在 8bit 模式有效�?????????16bit 模式无意�?????????
    inout wire [15:0] flash_d,  // Flash 数据
    output wire flash_rp_n,  // Flash 复位信号，低有效
    output wire flash_vpen,  // Flash 写保护信号，低电平时不能擦除、烧�?????????
    output wire flash_ce_n,  // Flash 片�?�信号，低有�?????????
    output wire flash_oe_n,  // Flash 读使能信号，低有�?????????
    output wire flash_we_n,  // Flash 写使能信号，低有�?????????
    output wire flash_byte_n, // Flash 8bit 模式选择，低有效。在使用 flash �????????? 16 位模式时请设�????????? 1

    // USB 控制器信号，参�?? SL811 芯片手册
    output wire sl811_a0,
    // inout  wire [7:0] sl811_d,     // USB ć°ćŽçşżä¸ç˝çťć§ĺśĺ¨ç dm9k_sd[7:0] ĺąäşŤ
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    // 网络控制器信号，参�?? DM9000A 芯片手册
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // 图像输出信号
    output wire [2:0] video_red,    // 红色像素�?????????3 �?????????
    output wire [2:0] video_green,  // 绿色像素�?????????3 �?????????
    output wire [1:0] video_blue,   // 蓝色像素�?????????2 �?????????
    output wire       video_hsync,  // 行同步（水平同步）信�?????????
    output wire       video_vsync,  // 场同步（垂直同步）信�?????????
    output wire       video_clk,    // 像素时钟输出
    output wire       video_de      // 行数据有效信号，用于区分消隐�?????????
);

  /* =========== Demo code begin =========== */

  // PLL ĺé˘ç¤şäž
  logic locked, clk_10M, clk_20M;
  pll_example clock_gen (
      // Clock in ports
      .clk_in1(clk_50M),  // ĺ¤é¨ćśéčžĺĽ
      // Clock out ports
      .clk_out1(clk_10M),  // 时钟输出 1，频率在 IP 配置界面中设�?????????
      .clk_out2(clk_20M),  // 时钟输出 2，频率在 IP 配置界面中设�?????????
      // Status and control signals
      .reset(reset_btn),  // PLL 复位输入
      .locked(locked)  // PLL 锁定指示输出�?????????"1"表示时钟稳定�?????????
                       // 后级电路复位信号应当由它生成（见下）
  );

  logic reset_of_clk10M;
  // 异步复位，同步释放，�????????? locked 信号转为后级电路的复�????????? reset_of_clk10M
  always_ff @(posedge clk_10M or negedge locked) begin
    if (~locked) reset_of_clk10M <= 1'b1;
    else reset_of_clk10M <= 1'b0;
  end

  logic reset_of_clk50M;
  // 异步复位，同步释放，�????????? locked 信号转为后级电路的复�????????? reset_of_clk10M
  always_ff @(posedge clk_50M or negedge locked) begin
    if (~locked) reset_of_clk50M <= 1'b1;
    else reset_of_clk50M <= 1'b0;
  end

  // always_ff @(posedge clk_10M or posedge reset_of_clk10M) begin
  //   if (reset_of_clk10M) begin
  //     // Your Code
  //   end else begin
  //     // Your Code
  //   end
  // end

  logic sys_clk;
  logic sys_rst;

  assign sys_clk = clk_50M;
  assign sys_rst = reset_of_clk50M;
  

  // 本实验不使用 CPLD 串口，禁用防止�?�线冲突
  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;

  logic        wbm0_cyc_o;
  logic        wbm0_stb_o;
  logic        wbm0_ack_i;
  logic [31:0] wbm0_adr_o;
  logic [31:0] wbm0_dat_o;
  logic [31:0] wbm0_dat_i;
  logic [ 3:0] wbm0_sel_o;
  logic        wbm0_we_o;

  logic        wbm1_cyc_o;
  logic        wbm1_stb_o;
  logic        wbm1_ack_i;
  logic [31:0] wbm1_adr_o;
  logic [31:0] wbm1_dat_o;
  logic [31:0] wbm1_dat_i;
  logic [ 3:0] wbm1_sel_o;
  logic        wbm1_we_o;

  logic        wbm2_cyc_o;
  logic        wbm2_stb_o;
  logic        wbm2_ack_i;
  logic [31:0] wbm2_adr_o;
  logic [31:0] wbm2_dat_o;
  logic [31:0] wbm2_dat_i;
  logic [ 3:0] wbm2_sel_o;
  logic        wbm2_we_o;

  logic        wbm3_cyc_o;
  logic        wbm3_stb_o;
  logic        wbm3_ack_i;
  logic [31:0] wbm3_adr_o;
  logic [31:0] wbm3_dat_o;
  logic [31:0] wbm3_dat_i;
  logic [ 3:0] wbm3_sel_o;
  logic        wbm3_we_o;

  logic        wbs_cyc_o;
  logic        wbs_stb_o;
  logic        wbs_ack_i;
  logic [31:0] wbs_adr_o;
  logic [31:0] wbs_dat_o;
  logic [31:0] wbs_dat_i;
  logic [ 3:0] wbs_sel_o;
  logic        wbs_we_o;

  wb_arbiter_4 wb_arbiter (
    .clk(sys_clk),
    .rst(sys_rst),

    .wbm0_adr_i(wbm0_adr_o),    
    .wbm0_dat_i(wbm0_dat_o),    
    .wbm0_dat_o(wbm0_dat_i),    
    .wbm0_we_i (wbm0_we_o ),    
    .wbm0_sel_i(wbm0_sel_o),    
    .wbm0_stb_i(wbm0_stb_o),    
    .wbm0_ack_o(wbm0_ack_i),    
    .wbm0_err_o(),    
    .wbm0_rty_o(),    
    .wbm0_cyc_i(wbm0_cyc_o),    

    .wbm1_adr_i(wbm1_adr_o),    
    .wbm1_dat_i(wbm1_dat_o),    
    .wbm1_dat_o(wbm1_dat_i),    
    .wbm1_we_i (wbm1_we_o ),    
    .wbm1_sel_i(wbm1_sel_o),    
    .wbm1_stb_i(wbm1_stb_o),    
    .wbm1_ack_o(wbm1_ack_i),    
    .wbm1_err_o(),    
    .wbm1_rty_o(),    
    .wbm1_cyc_i(wbm1_cyc_o),   

    .wbm2_adr_i(wbm2_adr_o),    
    .wbm2_dat_i(wbm2_dat_o),    
    .wbm2_dat_o(wbm2_dat_i),    
    .wbm2_we_i (wbm2_we_o ),    
    .wbm2_sel_i(wbm2_sel_o),    
    .wbm2_stb_i(wbm2_stb_o),    
    .wbm2_ack_o(wbm2_ack_i),    
    .wbm2_err_o(),    
    .wbm2_rty_o(),    
    .wbm2_cyc_i(wbm2_cyc_o),   

    .wbm3_adr_i(wbm3_adr_o),    
    .wbm3_dat_i(wbm3_dat_o),    
    .wbm3_dat_o(wbm3_dat_i),    
    .wbm3_we_i (wbm3_we_o ),    
    .wbm3_sel_i(wbm3_sel_o),    
    .wbm3_stb_i(wbm3_stb_o),    
    .wbm3_ack_o(wbm3_ack_i),    
    .wbm3_err_o(),    
    .wbm3_rty_o(),    
    .wbm3_cyc_i(wbm3_cyc_o),   

    .wbs_adr_o(wbs_adr_o),
    .wbs_dat_i(wbs_dat_i),
    .wbs_dat_o(wbs_dat_o),
    .wbs_we_o (wbs_we_o ), 
    .wbs_sel_o(wbs_sel_o),
    .wbs_stb_o(wbs_stb_o),
    .wbs_ack_i(wbs_ack_i),
    .wbs_err_i(0),
    .wbs_rty_i(0),
    .wbs_cyc_o(wbs_cyc_o) 
  );

  logic wbs0_cyc_o;
  logic wbs0_stb_o;
  logic wbs0_ack_i;
  logic [31:0] wbs0_adr_o;
  logic [31:0] wbs0_dat_o;
  logic [31:0] wbs0_dat_i;
  logic [3:0] wbs0_sel_o;
  logic wbs0_we_o;

  logic wbs1_cyc_o;
  logic wbs1_stb_o;
  logic wbs1_ack_i;
  logic [31:0] wbs1_adr_o;
  logic [31:0] wbs1_dat_o;
  logic [31:0] wbs1_dat_i;
  logic [3:0] wbs1_sel_o;
  logic wbs1_we_o;

  logic wbs2_cyc_o;
  logic wbs2_stb_o;
  logic wbs2_ack_i;
  logic [31:0] wbs2_adr_o;
  logic [31:0] wbs2_dat_o;
  logic [31:0] wbs2_dat_i;
  logic [3:0] wbs2_sel_o;
  logic wbs2_we_o;

  logic wbs3_cyc_o;
  logic wbs3_stb_o;
  logic wbs3_ack_i;
  logic [31:0] wbs3_adr_o;
  logic [31:0] wbs3_dat_o;
  logic [31:0] wbs3_dat_i;
  logic [3:0] wbs3_sel_o;
  logic wbs3_we_o;

  logic wbs4_cyc_o;
  logic wbs4_stb_o;
  logic wbs4_ack_i;
  logic [31:0] wbs4_adr_o;
  logic [31:0] wbs4_dat_o;
  logic [31:0] wbs4_dat_i;
  logic [3:0] wbs4_sel_o;
  logic wbs4_we_o;

  logic wbs5_cyc_o;
  logic wbs5_stb_o;
  logic wbs5_ack_i;
  logic [31:0] wbs5_adr_o;
  logic [31:0] wbs5_dat_o;
  logic [31:0] wbs5_dat_i;
  logic [3:0] wbs5_sel_o;
  logic wbs5_we_o;

  logic wbs6_cyc_o;
  logic wbs6_stb_o;
  logic wbs6_ack_i;
  logic [31:0] wbs6_adr_o;
  logic [31:0] wbs6_dat_o;
  logic [31:0] wbs6_dat_i;
  logic [3:0] wbs6_sel_o;
  logic wbs6_we_o;

  logic wbs7_cyc_o;
  logic wbs7_stb_o;
  logic wbs7_ack_i;
  logic [31:0] wbs7_adr_o;
  logic [31:0] wbs7_dat_o;
  logic [31:0] wbs7_dat_i;
  logic [3:0] wbs7_sel_o;
  logic wbs7_we_o;

  logic wbs8_cyc_o;
  logic wbs8_stb_o;
  logic wbs8_ack_i;
  logic [31:0] wbs8_adr_o;
  logic [31:0] wbs8_dat_o;
  logic [31:0] wbs8_dat_i;
  logic [3:0] wbs8_sel_o;
  logic wbs8_we_o;

  wb_mux_9 wb_mux (
      .clk(sys_clk),
      .rst(sys_rst),

      // Master interface (to Lab5 master)
      .wbm_adr_i(wbs_adr_o),
      .wbm_dat_i(wbs_dat_o),
      .wbm_dat_o(wbs_dat_i),
      .wbm_we_i (wbs_we_o),
      .wbm_sel_i(wbs_sel_o),
      .wbm_stb_i(wbs_stb_o),
      .wbm_ack_o(wbs_ack_i),
      .wbm_err_o(),
      .wbm_rty_o(),
      .wbm_cyc_i(wbs_cyc_o),

      // Slave interface 0 (to BaseRAM controller)
      // Address range: 0x8000_0000 ~ 0x803F_FFFF
      .wbs0_addr    (32'h8000_0000),
      .wbs0_addr_msk(32'hFFC0_0000),

      .wbs0_adr_o(wbs0_adr_o),
      .wbs0_dat_i(wbs0_dat_i),
      .wbs0_dat_o(wbs0_dat_o),
      .wbs0_we_o (wbs0_we_o),
      .wbs0_sel_o(wbs0_sel_o),
      .wbs0_stb_o(wbs0_stb_o),
      .wbs0_ack_i(wbs0_ack_i),
      .wbs0_err_i('0),
      .wbs0_rty_i('0),
      .wbs0_cyc_o(wbs0_cyc_o),

      // Slave interface 1 (to ExtRAM controller)
      // Address range: 0x8040_0000 ~ 0x807F_FFFF
      .wbs1_addr    (32'h8040_0000),
      .wbs1_addr_msk(32'hFFC0_0000),

      .wbs1_adr_o(wbs1_adr_o),
      .wbs1_dat_i(wbs1_dat_i),
      .wbs1_dat_o(wbs1_dat_o),
      .wbs1_we_o (wbs1_we_o),
      .wbs1_sel_o(wbs1_sel_o),
      .wbs1_stb_o(wbs1_stb_o),
      .wbs1_ack_i(wbs1_ack_i),
      .wbs1_err_i('0),
      .wbs1_rty_i('0),
      .wbs1_cyc_o(wbs1_cyc_o),

      // Slave interface 2 (to UART controller)
      // Address range: 0x1000_0000 ~ 0x1000_FFFF
      .wbs2_addr    (32'h1000_0000),
      .wbs2_addr_msk(32'hFFFF_0000),

      .wbs2_adr_o(wbs2_adr_o),
      .wbs2_dat_i(wbs2_dat_i),
      .wbs2_dat_o(wbs2_dat_o),
      .wbs2_we_o (wbs2_we_o),
      .wbs2_sel_o(wbs2_sel_o),
      .wbs2_stb_o(wbs2_stb_o),
      .wbs2_ack_i(wbs2_ack_i),
      .wbs2_err_i('0),
      .wbs2_rty_i('0),
      .wbs2_cyc_o(wbs2_cyc_o),

      // Slave interface 3 (to mtime)
      // Address range: 0x0200_0000 ~ 0x0200_FFFF
      .wbs3_addr    (32'h0200_0000),
      .wbs3_addr_msk(32'hFFFF_0000),

      .wbs3_adr_o(wbs3_adr_o),
      .wbs3_dat_i(wbs3_dat_i),
      .wbs3_dat_o(wbs3_dat_o),
      .wbs3_we_o (wbs3_we_o),
      .wbs3_sel_o(wbs3_sel_o),
      .wbs3_stb_o(wbs3_stb_o),
      .wbs3_ack_i(wbs3_ack_i),
      .wbs3_err_i('0),
      .wbs3_rty_i('0),
      .wbs3_cyc_o(wbs3_cyc_o),

      // Slave interface 4 (to flash)
      // Address range: 0x8300_0000 ~ 0x83FF_FFFF
      .wbs4_addr    (32'h8300_0000),
      .wbs4_addr_msk(32'hFF00_0000),

      .wbs4_adr_o(wbs4_adr_o),
      .wbs4_dat_i(wbs4_dat_i),
      .wbs4_dat_o(wbs4_dat_o),
      .wbs4_we_o (wbs4_we_o),
      .wbs4_sel_o(wbs4_sel_o),
      .wbs4_stb_o(wbs4_stb_o),
      .wbs4_ack_i(wbs4_ack_i),
      .wbs4_err_i('0),
      .wbs4_rty_i('0),
      .wbs4_cyc_o(wbs4_cyc_o),

      // Slave interface 5 (to block ram 0)
      // Address range: 0x8400_0000 ~ 0x84FF_FFFF
      .wbs5_addr    (32'h8400_0000),
      .wbs5_addr_msk(32'hFF00_0000),

      .wbs5_adr_o(wbs5_adr_o),
      .wbs5_dat_i(wbs5_dat_i),
      .wbs5_dat_o(wbs5_dat_o),
      .wbs5_we_o (wbs5_we_o),
      .wbs5_sel_o(wbs5_sel_o),
      .wbs5_stb_o(wbs5_stb_o),
      .wbs5_ack_i(wbs5_ack_i),
      .wbs5_err_i('0),
      .wbs5_rty_i('0),
      .wbs5_cyc_o(wbs5_cyc_o), 
  
      // Slave interface 6 (to block ram 1)
      // Address range: 0x8500_0000 ~ 0x85FF_FFFF
      .wbs6_addr    (32'h8500_0000),
      .wbs6_addr_msk(32'hFF00_0000),

      .wbs6_adr_o(wbs6_adr_o),
      .wbs6_dat_i(wbs6_dat_i),
      .wbs6_dat_o(wbs6_dat_o),
      .wbs6_we_o (wbs6_we_o),
      .wbs6_sel_o(wbs6_sel_o),
      .wbs6_stb_o(wbs6_stb_o),
      .wbs6_ack_i(wbs6_ack_i),
      .wbs6_err_i('0),
      .wbs6_rty_i('0),
      .wbs6_cyc_o(wbs6_cyc_o), 
  
      // Slave interface 7 (to vga register)
      // Address range: 0x8600_0000 ~ 0x8600_00FF
      .wbs7_addr    (32'h8600_0000),
      .wbs7_addr_msk(32'hFFFF_FF00),

      .wbs7_adr_o(wbs7_adr_o),
      .wbs7_dat_i(wbs7_dat_i),
      .wbs7_dat_o(wbs7_dat_o),
      .wbs7_we_o (wbs7_we_o),
      .wbs7_sel_o(wbs7_sel_o),
      .wbs7_stb_o(wbs7_stb_o),
      .wbs7_ack_i(wbs7_ack_i),
      .wbs7_err_i('0),
      .wbs7_rty_i('0),
      .wbs7_cyc_o(wbs7_cyc_o),

      // Slave interface 3 (to gpio)
      // Address range: 0x8700_0000 ~ 0x8700_00FF
      .wbs8_addr    (32'h8700_0000),
      .wbs8_addr_msk(32'hFFFF_FF00),

      .wbs8_adr_o(wbs8_adr_o),
      .wbs8_dat_i(wbs8_dat_i),
      .wbs8_dat_o(wbs8_dat_o),
      .wbs8_we_o (wbs8_we_o),
      .wbs8_sel_o(wbs8_sel_o),
      .wbs8_stb_o(wbs8_stb_o),
      .wbs8_ack_i(wbs8_ack_i),
      .wbs8_err_i('0),
      .wbs8_rty_i('0),
      .wbs8_cyc_o(wbs8_cyc_o)
  );

  /* =========== Lab5 MUX end =========== */

  /* =========== Lab5 Slaves begin =========== */
  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) sram_controller_base (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs0_cyc_o),
      .wb_stb_i(wbs0_stb_o),
      .wb_ack_o(wbs0_ack_i),
      .wb_adr_i(wbs0_adr_o),
      .wb_dat_i(wbs0_dat_o),
      .wb_dat_o(wbs0_dat_i),
      .wb_sel_i(wbs0_sel_o),
      .wb_we_i (wbs0_we_o),

      // To SRAM chip
      .sram_addr(base_ram_addr),
      .sram_data(base_ram_data),
      .sram_ce_n(base_ram_ce_n),
      .sram_oe_n(base_ram_oe_n),
      .sram_we_n(base_ram_we_n),
      .sram_be_n(base_ram_be_n)
  );

  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) sram_controller_ext (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs1_cyc_o),
      .wb_stb_i(wbs1_stb_o),
      .wb_ack_o(wbs1_ack_i),
      .wb_adr_i(wbs1_adr_o),
      .wb_dat_i(wbs1_dat_o),
      .wb_dat_o(wbs1_dat_i),
      .wb_sel_i(wbs1_sel_o),
      .wb_we_i (wbs1_we_o),

      // To SRAM chip
      .sram_addr(ext_ram_addr),
      .sram_data(ext_ram_data),
      .sram_ce_n(ext_ram_ce_n),
      .sram_oe_n(ext_ram_oe_n),
      .sram_we_n(ext_ram_we_n),
      .sram_be_n(ext_ram_be_n)
  );

  // 串口控制器模�?????????
  // TODO NOTE: 如果修改系统时钟频率，也�?????????要修改此处的时钟频率参数 
  uart_controller #(
      .CLK_FREQ(10_000_000),
      .BAUD    (115200)
  ) uart_controller (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      .wb_cyc_i(wbs2_cyc_o),
      .wb_stb_i(wbs2_stb_o),
      .wb_ack_o(wbs2_ack_i),
      .wb_adr_i(wbs2_adr_o),
      .wb_dat_i(wbs2_dat_o),
      .wb_dat_o(wbs2_dat_i),
      .wb_sel_i(wbs2_sel_o),
      .wb_we_i (wbs2_we_o),

      // to UART pins
      .uart_txd_o(txd),
      .uart_rxd_i(rxd)
  );

//  ila_0 ila(
//    .clk(sys_clk),
//    .probe0({ wbs0_sel_o, 
//              wbs1_sel_o, 
//              wbs2_sel_o, 
//              wbs3_sel_o, 
//              wbs4_sel_o, 
//              wbs5_sel_o, 
//              wbs6_sel_o, 
//              wbs7_sel_o, 
//              wbs8_sel_o}),
//    .probe1({ wbs0_we_o, 
//              wbs1_we_o, 
//              wbs2_we_o, 
//              wbs3_we_o, 
//              wbs4_we_o, 
//              wbs5_we_o, 
//              wbs6_we_o, 
//              wbs7_we_o, 
//              wbs8_we_o}),
//    .probe2(1'b0),
//    .probe3(1'b0),
//    .probe4(1'b0),
//    .probe5(wbs_adr_o),
//    .probe6(wbs_dat_o),
//    .probe7(wbs_dat_i),
//    .probe8(wbs_we_o),
//    .probe9(1'b0),
//    .probe10(if1_if2_pc_now),
//    .probe11(if2_id_pc_now),
//    .probe12(id_exe_pc_now),
//    .probe13(exe_mem1_pc_now),
//    .probe14(mem1_mem2_pc_now),
//    .probe15(rf_waddr),
//    .probe16(rf_wdata),
//    .probe17({wbs0_cyc_o, 
//              wbs1_cyc_o, 
//              wbs2_cyc_o, 
//              wbs3_cyc_o, 
//              wbs4_cyc_o, 
//              wbs5_cyc_o, 
//              wbs6_cyc_o, 
//              wbs7_cyc_o, 
//              wbs8_cyc_o}),
//    .probe18({wbm0_ack_i, wbm1_ack_i, wbm2_ack_i, wbm3_ack_i,  
//              wbs_ack_i ,wbs0_ack_i, wbs1_ack_i, wbs2_ack_i, wbs3_ack_i, wbs4_ack_i, wbs5_ack_i, wbs6_ack_i, wbs7_ack_i, wbs8_ack_i}),
//    .probe19(wbm1_adr_o),    // mem_mmu
//    .probe20(wbm1_dat_i),    // mem_mmu
//    .probe21({ exe_mem1_mem_sel, 
//              (exe_mem1_mem_re | exe_mem1_mem_we) & ~mem1_trap, 
//               exe_mem1_mem_re,
//               exe_mem1_mem_we
//            }),  // mem_mmu: {mem_sel_i, enable_i, read_en_i, write_en_i}
//    .probe22({mem1_mem2_load_page_fault,   mem1_mem2_store_page_fault, 
//              mem1_mem2_load_access_fault, mem1_mem2_store_access_fault,
//              mem1_mem2_load_misaligned,   mem1_mem2_store_misaligned
//            }), // mem_mmu
//    .probe23({flash_a, // 23 bits
//              flash_d, // 16
//              flash_rp_n, 
//              flash_ce_n, 
//              flash_oe_n}),
//    .probe24(1'b0),
//    .probe25(1'b0),
//    .probe26(1'b0),
//    .probe27(1'b0),
//    .probe28(1'b0),
//    .probe29(1'b0),
//    .probe30(1'b0),
//    .probe31(1'b0),
//    .probe32(1'b0),
//    .probe33(1'b0),
//    .probe34(1'b0),
//    .probe35(1'b0),
//    .probe36(1'b0),
//    .probe37(if2_id_inst),
//    .probe38(id_exe_inst),
//    .probe39(exe_mem1_inst),
//    .probe40(mem1_mem2_inst),
//    .probe41(bram_0_wea),
//    .probe42(bram_0_waddr),  // 17 bits
//    .probe43(bram_0_wdata),  // 8 bits
//    .probe44(bram_raddr),
//    .probe45(bram_0_rdata),
//    .probe46(bram_1_wea),
//    .probe47(bram_1_waddr),
//    .probe48(bram_1_wdata),
//    .probe49(bram_1_rdata),
//    .probe50(real_bram_rdata),
//    .probe51(vga_ack),
//    .probe52(vga_scale),
//    .probe53(hdata_o),
//    .probe54(vdata_o),
//    .probe55(1'b0),
//    .probe56(1'b0),
//    .probe57(1'b0),
//    .probe58(1'b0),
//    .probe59(1'b0),
//    .probe60(1'b0),
//    .probe61(1'b0),
//    .probe62(1'b0),
//    .probe63(1'b0)
//  );

  logic [MTIME_WIDTH-1:0] mtime;
  logic                   time_interrupt;

  mtime csr_mtime (
    .clk(sys_clk),
    .rst(sys_rst),

    .wb_cyc_i(wbs3_cyc_o),
    .wb_stb_i(wbs3_stb_o),
    .wb_ack_o(wbs3_ack_i),
    .wb_adr_i(wbs3_adr_o),
    .wb_dat_i(wbs3_dat_o),
    .wb_dat_o(wbs3_dat_i),
    .wb_sel_i(wbs3_sel_o),
    .wb_we_i (wbs3_we_o),
    .mtime_o(mtime),
    .time_interrupt_o(time_interrupt)
  );

  logic if1_stall;
  logic if2_stall;
  logic id_stall;
  logic exe_stall;
  logic mem1_stall;
  logic mem2_stall;
  logic if1_bubble;
  logic if2_bubble;
  logic id_bubble;
  logic exe_bubble;
  logic mem1_bubble;
  logic mem2_bubble;

  logic [REG_ADDR_WIDTH-1:0]  id_rf_raddr_a_comb;
  logic [REG_ADDR_WIDTH-1:0]  id_rf_raddr_b_comb;
  logic                       exe_branch_comb;

  logic                       branch_taken;   // previous prediction is correct(1)/wrong(0)
  logic [ADDR_WIDTH-1:0]      pc_true;


  /* ====================== controller ====================== */
  pipeline_controller pipeline_controller (
    .if1_ack_i(if_mmu_ack),
    .if2_ack_i(icache_ack),
    .mem1_ack_i(mem_mmu_ack),
    .mem2_ack_i(wbm0_ack_i),
    .branch_taken_i(branch_taken),
    .csr_branch_i(csr_branch),

    .exe_mem1_mem_re_i(exe_mem1_mem_re),
    .exe_mem1_rf_wen_i(exe_mem1_rf_wen),
    .exe_mem1_rf_waddr_i(exe_mem1_rf_waddr),

    .id_rf_raddr_a_comb_i(id_rf_raddr_a_comb),
    .id_rf_raddr_b_comb_i(id_rf_raddr_b_comb),
    .id_exe_mem_re_i(id_exe_mem_re),
    .id_exe_rf_wen_i(id_exe_rf_wen),
    .id_exe_rf_waddr_i(id_exe_rf_waddr),

    .mem1_mem2_mem_re_i(mem1_mem2_mem_re & ~csr_branch),
    .mem1_mem2_mem_we_i(mem1_mem2_mem_we & ~csr_branch),

    .fencei_i(fencei),
    .sfence_vma_i(if2_sfence_vma),

    .csr_inst_i(id_csr_op_comb || id_exe_csr_op || exe_mem1_csr_op || mem1_mem2_csr_op),

    .if1_stall_o(if1_stall),
    .if2_stall_o(if2_stall),
    .id_stall_o(id_stall),
    .exe_stall_o(exe_stall),
    .mem1_stall_o(mem1_stall),
    .mem2_stall_o(mem2_stall),
    .if1_bubble_o(if1_bubble),
    .if2_bubble_o(if2_bubble),
    .id_bubble_o(id_bubble),
    .exe_bubble_o(exe_bubble),
    .mem1_bubble_o(mem1_bubble),
    .mem2_bubble_o(mem2_bubble)
  );

  /* ====================== IF1 ====================== */
  pc_mux pc_mux (
    .csr_branch_i       (csr_branch),
    .csr_pc_next_i      (csr_pc_next),
    .exe_branch_comb_i  (exe_branch_comb),
    .exe_pc_next_comb_i (exe_pc_next_comb),

    .id_exe_pc_now      (id_exe_pc_now),
    .if2_id_pc_now      (if2_id_pc_now),
    .if1_if2_pc_vaddr   (if1_if2_pc_now),
    .if1_pc_vaddr       (if1_pc_vaddr),

    .branch_taken_o     (branch_taken),
    .pc_true_o          (pc_true)
  );

  logic [ADDR_WIDTH-1:0] pc_pred;   // next PC predicted by BTB

  btb btb (
    .clk              (sys_clk),
    .rst              (sys_rst),

    .pc_i             (if1_pc_vaddr),
    .pred_pc_o        (pc_pred),
    .branch_from_pc_i (id_exe_pc_now),
    .branch_to_pc_i   (exe_pc_next_comb),
    .branch_taken_i   (branch_taken),
    .is_branch_i      (id_exe_jump || id_exe_imm_type == `TYPE_B)
  );

  logic [ADDR_WIDTH-1:0] if1_pc_vaddr;

  IF IF (
    .clk            (sys_clk),
    .rst            (sys_rst),

    .pc_o           (if1_pc_vaddr),
    .branch_taken_i (branch_taken),
    .pc_true_i      (pc_true),
    .pc_pred_i      (pc_pred),

    .stall_i        (if1_stall),
    .bubble_i       (if1_bubble)
  );

  logic if_mmu_ack;

  mmu if_mmu (
    .clk(sys_clk),
    .rst(sys_rst),

    .mode_i                 (csr_mode),
    .satp_i                 (csr_satp),
    .mstatus_sum_i          (mstatus_sum),
    .vaddr_i                (if1_pc_vaddr),
    .paddr_o                (if1_if2_pc_paddr),
    .ack_o                  (if_mmu_ack),

    .mem_sel_i              (4'b1111),
    .enable_i               (1'b1),
    .read_en_i              (1'b0),
    .write_en_i             (1'b0),
    .exe_en_i               (1'b1),
    .load_page_fault_o      (),
    .store_page_fault_o     (),
    .instr_page_fault_o     (if1_if2_instr_page_fault),
    .load_access_fault_o    (),
    .store_access_fault_o   (),
    .instr_access_fault_o   (if1_if2_instr_access_fault),
    .load_misaligned_o      (),
    .store_misaligned_o     (),
    .instr_misaligned_o     (if1_if2_instr_misaligned),


    .tlb_reset_i            (if2_sfence_vma),
    .stall_i                (if1_stall),
    .bubble_i               (if1_bubble),

    .wb_cyc_o(wbm3_cyc_o),
    .wb_stb_o(wbm3_stb_o),
    .wb_ack_i(wbm3_ack_i),
    .wb_adr_o(wbm3_adr_o),
    .wb_dat_o(wbm3_dat_o),
    .wb_dat_i(wbm3_dat_i),
    .wb_sel_o(wbm3_sel_o),
    .wb_we_o(wbm3_we_o),

    .if1_if2_icache_enable(if1_if2_icache_enable),
    // data direct pass
    .if1_if2_pc_now         (if1_if2_pc_now)
  );

  /* ====================== IF1/IF2 regs ====================== */
  logic if1_if2_instr_page_fault;
  logic if1_if2_instr_access_fault;
  logic if1_if2_instr_misaligned;
  logic if1_if2_icache_enable;
  logic [31:0] if1_if2_pc_paddr;
  logic [31:0] if1_if2_pc_now;

  /* ====================== IF2 ====================== */
  logic icache_ack;
  logic if2_sfence_vma;

  icache icache (
    .clk(sys_clk),
    .rst(sys_rst),

    .fence_i(fencei),
    .pc_i(if1_if2_pc_paddr),
    .enable_i(if1_if2_icache_enable),
    .icache_ack_o(icache_ack),
    .inst_o(if2_id_inst),
    .pc_now_i(if1_if2_pc_now),
    .pc_now_o(if2_id_pc_now),
    .page_fault_i(if1_if2_instr_page_fault),
    .access_fault_i(if1_if2_instr_access_fault),
    .page_fault_o(if2_id_instr_page_fault),
    .access_fault_o(if2_id_instr_access_fault),
    .instr_misaligned_i(if1_if2_instr_misaligned),
    .instr_misaligned_o(if2_id_instr_misaligned),
    .sfence_vma_o(if2_sfence_vma),

    .stall_i(if2_stall),
    .bubble_i(if2_bubble),

    .wb_cyc_o(wbm2_cyc_o),
    .wb_stb_o(wbm2_stb_o),
    .wb_ack_i(wbm2_ack_i),
    .wb_adr_o(wbm2_adr_o),
    .wb_dat_o(wbm2_dat_o),
    .wb_dat_i(wbm2_dat_i),
    .wb_sel_o(wbm2_sel_o),
    .wb_we_o(wbm2_we_o)
  );

  /* ====================== IF2/ID regs ====================== */
  logic [31:0] if2_id_inst;
  logic [31:0] if2_id_pc_now;
  logic if2_id_instr_page_fault;
  logic if2_id_instr_access_fault;
  logic if2_id_instr_misaligned;

  /* ====================== ID ====================== */
  logic [2:0] id_csr_op_comb;
  logic fencei;

  ID ID (
    .clk(sys_clk),
    .rst(sys_rst),

    .inst_i                 (if2_id_inst),
    .inst_o                 (id_exe_inst),
    .rf_raddr_a_o           (id_exe_rf_raddr_a),
    .rf_raddr_b_o           (id_exe_rf_raddr_b),
    .id_rf_raddr_a_comb     (id_rf_raddr_a_comb),
    .id_rf_raddr_b_comb     (id_rf_raddr_b_comb),
    .imm_type_o             (id_exe_imm_type),
    .alu_op_o               (id_exe_alu_op),
    .use_rs2_o              (id_exe_use_rs2),
    .rf_wen_o               (id_exe_rf_wen),
    .rf_waddr_o             (id_exe_rf_waddr),
    .mem_re_o               (id_exe_mem_re),
    .mem_we_o               (id_exe_mem_we),
    .mem_sel_o              (id_exe_mem_sel),
    .pc_now_i               (if2_id_pc_now),
    .pc_now_o               (id_exe_pc_now),
    .use_pc_o               (id_exe_use_pc),
    .jump_o                 (id_exe_jump),
    .comp_op_o              (id_exe_comp_op),
    .load_type_o            (id_exe_load_type),
    .csr_op_o               (id_exe_csr_op),
    .ecall_o                (id_exe_ecall),
    .ebreak_o               (id_exe_ebreak),
    .mret_o                 (id_exe_mret),
    .sret_o                 (id_exe_sret),
    .fencei_o               (fencei),
    .instr_page_fault_i     (if2_id_instr_page_fault),
    .instr_access_fault_i   (if2_id_instr_access_fault),
    .instr_page_fault_o     (id_exe_instr_page_fault),
    .instr_access_fault_o   (id_exe_instr_access_fault),
    .instr_misaligned_i     (if2_id_instr_misaligned),
    .instr_misaligned_o     (id_exe_instr_misaligned),
    .illegal_instr_o        (id_exe_illegal_instr),
    .csr_op_comb            (id_csr_op_comb),
    .sfence_vma_o            (id_exe_sfence_vma),


    .stall_i                (id_stall),
    .bubble_i               (id_bubble)
  );

  /* ====================== ID/EXE regs ====================== */
  logic [4:0]  rf_waddr;
  logic [31:0] rf_wdata;
  logic rf_we;

  logic [4:0]  id_exe_rf_raddr_a;
  logic [31:0] rf_rdata_a;
  logic [4:0]  id_exe_rf_raddr_b;
  logic [31:0] rf_rdata_b;

  logic [31:0] id_exe_inst;
  logic [2:0] id_exe_imm_type;
  logic [3:0] id_exe_alu_op;
  logic id_exe_use_rs2;
  logic id_exe_mem_re;
  logic id_exe_mem_we;
  logic id_exe_rf_wen;
  logic [4:0] id_exe_rf_waddr;
  logic [3:0] id_exe_mem_sel;
  logic [31:0] id_exe_pc_now;
  logic id_exe_use_pc;
  logic [2:0] id_exe_comp_op;
  logic id_exe_load_type;
  logic id_exe_jump;
  logic [2:0] id_exe_csr_op;
  logic id_exe_ecall;
  logic id_exe_ebreak;
  logic id_exe_mret;
  logic id_exe_sret;
  logic id_exe_instr_page_fault;
  logic id_exe_instr_access_fault;
  logic id_exe_instr_misaligned;
  logic id_exe_illegal_instr;
  logic id_exe_sfence_vma;

  /* ====================== EXE ====================== */

  // logic [31:0] rf_regs_debug[0:31];  // [debug]

  regfile regfile (
    .clk(sys_clk),
    .rst(sys_rst),
    // .rf_regs_debug(rf_regs_debug),

    .rf_raddr_a(id_exe_rf_raddr_a),
    .rf_rdata_a(rf_rdata_a),
    .rf_raddr_b(id_exe_rf_raddr_b),
    .rf_rdata_b(rf_rdata_b),
    .rf_waddr(rf_waddr),
    .rf_wdata(rf_wdata),
    .rf_we(rf_we)
  );

  wire [31:0] exe_pc_next_comb;

  EXE EXE (
    .clk(sys_clk),
    .rst(sys_rst),

    .rf_raddr_a_i           (id_exe_rf_raddr_a),
    .rf_raddr_b_i           (id_exe_rf_raddr_b),
    .rf_rdata_a_i           (rf_rdata_a),
    .rf_rdata_b_i           (rf_rdata_b),
    .inst_i                 (id_exe_inst),
    .inst_o                 (exe_mem1_inst),
    .imm_type_i             (id_exe_imm_type),
    .use_rs2_i              (id_exe_use_rs2),
    .alu_a_o                (alu_a),
    .alu_b_o                (alu_b),
    .alu_y_i                (alu_y),
    .alu_result_o           (exe_mem1_alu_result),
    .rf_wen_i               (id_exe_rf_wen),
    .rf_wen_o               (exe_mem1_rf_wen),
    .rf_waddr_i             (id_exe_rf_waddr),
    .rf_waddr_o             (exe_mem1_rf_waddr),
    .mem_re_i               (id_exe_mem_re),
    .mem_re_o               (exe_mem1_mem_re),
    .mem_we_i               (id_exe_mem_we),
    .mem_we_o               (exe_mem1_mem_we),
    .mem_sel_i              (id_exe_mem_sel),
    .mem_sel_o              (exe_mem1_mem_sel),
    .mem_wdata_o            (exe_mem1_mem_wdata),
    .use_pc_i               (id_exe_use_pc),
    .comp_op_i              (id_exe_comp_op),
    .load_type_i            (id_exe_load_type),
    .load_type_o            (exe_mem1_load_type),
    .jump_i                 (id_exe_jump),
    .pc_now_i               (id_exe_pc_now),
    .pc_next_o              (exe_pc_next_comb),
    .branch_comb_o          (exe_branch_comb),
    .csr_op_i               (id_exe_csr_op),
    .csr_op_o               (exe_mem1_csr_op),
    .csr_data_o             (exe_mem1_csr_data),
    .instr_page_fault_i     (id_exe_instr_page_fault),
    .instr_access_fault_i   (id_exe_instr_access_fault),
    .instr_page_fault_o     (exe_mem1_instr_page_fault),
    .instr_access_fault_o   (exe_mem1_instr_access_fault),
    .instr_misaligned_i     (id_exe_instr_misaligned),
    .instr_misaligned_o     (exe_mem1_instr_misaligned),
    .illegal_instr_i        (id_exe_illegal_instr),
    .illegal_instr_o        (exe_mem1_illegal_instr),
    .ecall_i                (id_exe_ecall),
    .ebreak_i               (id_exe_ebreak),
    .mret_i                 (id_exe_mret),
    .ecall_o                (exe_mem1_ecall),
    .ebreak_o               (exe_mem1_ebreak),
    .mret_o                 (exe_mem1_mret),
    .sret_i                 (id_exe_sret),
    .sret_o                 (exe_mem1_sret),
    .sfence_vma_i           (id_exe_sfence_vma),
    .sfence_vma_o           (exe_mem1_sfence_vma),
    .pc_now_o               (exe_mem1_pc_now),
    
    // data forwarding
    .exe_mem1_rf_waddr_i    (exe_mem1_rf_waddr),
    .exe_mem1_alu_result_i  (exe_mem1_alu_result),
    .mem1_mem2_rf_waddr_i   (mem1_mem2_rf_waddr),
    .mem1_mem2_rf_wdata_i   (mem1_mem2_rf_wdata),

    // stall & bubble
    .stall_i                (exe_stall),
    .bubble_i               (exe_bubble)
  );

  logic [DATA_WIDTH-1:0] alu_a;
  logic [DATA_WIDTH-1:0] alu_b;
  logic [DATA_WIDTH-1:0] alu_y;

  alu_32 alu_32 (
    .a(alu_a),
    .b(alu_b),
    .op(id_exe_alu_op),
    .y(alu_y)
  );

  /* ====================== EXE/MEM1 regs ====================== */

  logic [ADDR_WIDTH-1:0]      exe_mem1_pc_now;
  logic                       exe_mem1_rf_wen;
  logic [REG_ADDR_WIDTH-1:0]  exe_mem1_rf_waddr;
  logic [DATA_WIDTH-1:0]      exe_mem1_alu_result;
  logic                       exe_mem1_mem_re;
  logic                       exe_mem1_mem_we;
  logic [DATA_WIDTH/8-1:0]    exe_mem1_mem_sel;
  logic [DATA_WIDTH-1:0]      exe_mem1_mem_wdata;
  logic                       exe_mem1_load_type;
  logic [2:0]                 exe_mem1_csr_op;
  logic [DATA_WIDTH-1:0]      exe_mem1_inst;
  logic [DATA_WIDTH-1:0]      exe_mem1_csr_data;
  logic                       exe_mem1_instr_page_fault;
  logic                       exe_mem1_instr_access_fault;
  logic                       exe_mem1_instr_misaligned;
  logic                       exe_mem1_illegal_instr;
  logic                       exe_mem1_ecall;
  logic                       exe_mem1_ebreak;
  logic                       exe_mem1_mret;
  logic                       exe_mem1_sret;
  logic                       exe_mem1_sfence_vma;

  /* ====================== MEM1 ====================== */
  logic                       mem_mmu_ack;
  logic                       mem1_trap;

  assign mem1_trap = exe_mem1_instr_page_fault | exe_mem1_instr_access_fault | exe_mem1_instr_misaligned | exe_mem1_illegal_instr;

  mmu mem_mmu (
    .clk(sys_clk),
    .rst(sys_rst),

    .mode_i                 (csr_mode),
    .satp_i                 (csr_satp),
    .mstatus_sum_i          (mstatus_sum),
    .vaddr_i                (exe_mem1_alu_result),
    .paddr_o                (mem1_mem2_paddr),
    .ack_o                  (mem_mmu_ack),

    .mem_sel_i              (exe_mem1_mem_sel),
    .enable_i               ((exe_mem1_mem_re | exe_mem1_mem_we) & ~mem1_trap),
    .read_en_i              (exe_mem1_mem_re),
    .write_en_i             (exe_mem1_mem_we),
    .exe_en_i               (1'b0),
    .load_page_fault_o      (mem1_mem2_load_page_fault),
    .store_page_fault_o     (mem1_mem2_store_page_fault),
    .instr_page_fault_o     (),
    .load_access_fault_o    (mem1_mem2_load_access_fault),
    .store_access_fault_o   (mem1_mem2_store_access_fault),
    .instr_access_fault_o   (),
    .load_misaligned_o      (mem1_mem2_load_misaligned),
    .store_misaligned_o     (mem1_mem2_store_misaligned),
    .instr_misaligned_o     (),

    .tlb_reset_i            (exe_mem1_sfence_vma),
    .stall_i                (mem1_stall),
    .bubble_i               (mem1_bubble),

    .wb_cyc_o(wbm1_cyc_o),
    .wb_stb_o(wbm1_stb_o),
    .wb_ack_i(wbm1_ack_i),
    .wb_adr_o(wbm1_adr_o),
    .wb_dat_o(wbm1_dat_o),
    .wb_dat_i(wbm1_dat_i),
    .wb_sel_o(wbm1_sel_o),
    .wb_we_o(wbm1_we_o),

    // data direct pass
    .exe_mem1_pc_now              (exe_mem1_pc_now),
    .exe_mem1_rf_wen              (exe_mem1_rf_wen),
    .exe_mem1_rf_waddr            (exe_mem1_rf_waddr),
    .exe_mem1_alu_result          (exe_mem1_alu_result),
    .exe_mem1_mem_re              (exe_mem1_mem_re),
    .exe_mem1_mem_we              (exe_mem1_mem_we),
    .exe_mem1_mem_sel             (exe_mem1_mem_sel),
    .exe_mem1_mem_wdata           (exe_mem1_mem_wdata),
    .exe_mem1_load_type           (exe_mem1_load_type),
    .exe_mem1_inst                (exe_mem1_inst),
    .exe_mem1_csr_op              (exe_mem1_csr_op),
    .exe_mem1_csr_data            (exe_mem1_csr_data),
    .exe_mem1_instr_page_fault    (exe_mem1_instr_page_fault),
    .exe_mem1_instr_access_fault  (exe_mem1_instr_access_fault),
    .exe_mem1_instr_misaligned    (exe_mem1_instr_misaligned),
    .exe_mem1_illegal_instr       (exe_mem1_illegal_instr),
    .exe_mem1_ecall               (exe_mem1_ecall),
    .exe_mem1_ebreak              (exe_mem1_ebreak),
    .exe_mem1_mret                (exe_mem1_mret),
    .exe_mem1_sret                (exe_mem1_sret),

    .mem1_mem2_pc_now             (mem1_mem2_pc_now),
    .mem1_mem2_rf_wen             (mem1_mem2_rf_wen),
    .mem1_mem2_rf_waddr           (mem1_mem2_rf_waddr),
    .mem1_mem2_rf_wdata           (mem1_mem2_rf_wdata),
    .mem1_mem2_mem_vaddr          (mem1_mem2_mem_vaddr),
    .mem1_mem2_load_type          (mem1_mem2_load_type),
    .mem1_mem2_mem_re             (mem1_mem2_mem_re),
    .mem1_mem2_mem_we             (mem1_mem2_mem_we),
    .mem1_mem2_mem_sel            (mem1_mem2_mem_sel),
    .mem1_mem2_mem_wdata          (mem1_mem2_mem_wdata),
    .mem1_mem2_inst               (mem1_mem2_inst),
    .mem1_mem2_csr_op             (mem1_mem2_csr_op),
    .mem1_mem2_csr_data           (mem1_mem2_csr_data),
    .mem1_mem2_instr_page_fault   (mem1_mem2_instr_page_fault),
    .mem1_mem2_instr_access_fault (mem1_mem2_instr_access_fault),
    .mem1_mem2_instr_misaligned   (mem1_mem2_instr_misaligned),
    .mem1_mem2_illegal_instr      (mem1_mem2_illegal_instr),
    .mem1_mem2_ecall              (mem1_mem2_ecall),
    .mem1_mem2_ebreak             (mem1_mem2_ebreak),
    .mem1_mem2_mret               (mem1_mem2_mret),
    .mem1_mem2_sret               (mem1_mem2_sret)

    // // [debug]
    // .state_o        (mem_mmu_state),
    // .cur_level_o    (mem_mmu_cur_level),
    // .direct_trans_o (mem_mmu_direct_trans),
    // .fault_case_o   (mem_mmu_fault_case)
  );
  // // [debug]
  // logic [2:0] mem_mmu_state;
  // logic       mem_mmu_cur_level;
  // logic       mem_mmu_direct_trans;
  // logic [4:0] mem_mmu_fault_case;

  /* ====================== MEM1/MEM2 regs ====================== */

  logic [ADDR_WIDTH-1:0]      mem1_mem2_paddr;

  logic [ADDR_WIDTH-1:0]      mem1_mem2_pc_now;
  logic                       mem1_mem2_rf_wen;
  logic [REG_ADDR_WIDTH-1:0]  mem1_mem2_rf_waddr;
  logic [DATA_WIDTH-1:0]      mem1_mem2_rf_wdata;
  logic [ADDR_WIDTH-1:0]      mem1_mem2_mem_vaddr;
  logic                       mem1_mem2_mem_re;
  logic                       mem1_mem2_mem_we;
  logic [DATA_WIDTH/8-1:0]    mem1_mem2_mem_sel;
  logic [DATA_WIDTH-1:0]      mem1_mem2_mem_wdata;
  logic                       mem1_mem2_load_type;
  logic [2:0]                 mem1_mem2_csr_op;
  logic [DATA_WIDTH-1:0]      mem1_mem2_inst;
  logic [DATA_WIDTH-1:0]      mem1_mem2_csr_data;
  logic                       mem1_mem2_load_page_fault;
  logic                       mem1_mem2_store_page_fault;
  logic                       mem1_mem2_load_access_fault;
  logic                       mem1_mem2_store_access_fault;
  logic                       mem1_mem2_load_misaligned;
  logic                       mem1_mem2_store_misaligned;
  logic                       mem1_mem2_instr_page_fault;
  logic                       mem1_mem2_instr_access_fault;
  logic                       mem1_mem2_instr_misaligned;
  logic                       mem1_mem2_illegal_instr;
  logic                       mem1_mem2_ecall;
  logic                       mem1_mem2_ebreak;
  logic                       mem1_mem2_mret;
  logic                       mem1_mem2_sret;


  /* ====================== MEM2 ====================== */
  logic [CSR_ADDR_WIDTH-1:0]  csr_raddr;
  logic [DATA_WIDTH-1:0]      csr_rdata;
  logic [CSR_ADDR_WIDTH-1:0]  csr_waddr;
  logic [DATA_WIDTH-1:0]      csr_wdata;
  logic csr_we;

  logic [31:0] csr_pc_next;
  logic csr_branch;

  logic [1:0] csr_mode;
  satp_t csr_satp;
  logic mstatus_sum;

  logic [31:0] csr_tval;
  assign csr_tval = (mem1_mem2_instr_page_fault | mem1_mem2_instr_access_fault | mem1_mem2_instr_misaligned) ? mem1_mem2_pc_now :
                      mem1_mem2_illegal_instr ? mem1_mem2_inst :
                     (mem1_mem2_load_page_fault | mem1_mem2_load_access_fault | mem1_mem2_load_misaligned 
                     | mem1_mem2_store_page_fault | mem1_mem2_store_access_fault | mem1_mem2_store_misaligned) ? mem1_mem2_mem_vaddr : 32'b0; 

  csrfile csrfile (
    .clk(sys_clk),
    .rst(sys_rst),
    .raddr_i(csr_raddr),
    .rdata_o(csr_rdata),
    .waddr_i(csr_waddr),
    .wdata_i(csr_wdata),
    .we_i(csr_we),
    .pc_now_i(mem1_mem2_pc_now),
    .pc_next_o(csr_pc_next),
    .branch_o(csr_branch),
    .ecall_i(mem1_mem2_ecall),
    .ebreak_i(mem1_mem2_ebreak),
    .mret_i(mem1_mem2_mret),
    .sret_i(mem1_mem2_sret),
    .time_interrupt_i(time_interrupt),
    // .time_interrupt_i(1'b0),      // [debug]
    .satp_o(csr_satp),
    .sum_o(mstatus_sum),
    .mode_o(csr_mode),
    .mtime_i(mtime),
    .tval_i(csr_tval),
    .if_illegal_i(mem1_mem2_illegal_instr),
    .if_page_fault_i(mem1_mem2_instr_page_fault),
    .if_access_fault_i(mem1_mem2_instr_access_fault),
    .if_misaligned_i(mem1_mem2_instr_misaligned),
    .load_page_fault_i(mem1_mem2_load_page_fault),
    .load_access_fault_i(mem1_mem2_load_access_fault),
    .load_misaligned_i(mem1_mem2_load_misaligned),
    .store_page_fault_i(mem1_mem2_store_page_fault),
    .store_access_fault_i(mem1_mem2_store_access_fault),
    .store_misaligned_i(mem1_mem2_store_misaligned),

    .stall_i(mem1_stall)
  );

  MEM MEM (
    .clk(sys_clk),
    .rst(sys_rst),

    .rf_wdata_i(mem1_mem2_rf_wdata),
    .rf_wen_i(mem1_mem2_rf_wen),
    .rf_waddr_i(mem1_mem2_rf_waddr),
    .rf_wdata_o(rf_wdata),
    .rf_wen_o(rf_we),
    .rf_waddr_o(rf_waddr),
    .mem_re_i(mem1_mem2_mem_re & ~csr_branch),
    .mem_we_i(mem1_mem2_mem_we & ~csr_branch),
    .mem_addr_i(mem1_mem2_paddr),
    .mem_sel_i(mem1_mem2_mem_sel),
    .mem_wdata_i(mem1_mem2_mem_wdata),
    .load_type_i(mem1_mem2_load_type),
    .inst_i(mem1_mem2_inst),

    .stall_i(mem2_stall),
    .bubble_i(mem2_bubble),

    .wb_cyc_o(wbm0_cyc_o),
    .wb_stb_o(wbm0_stb_o),
    .wb_ack_i(wbm0_ack_i),
    .wb_adr_o(wbm0_adr_o),
    .wb_dat_o(wbm0_dat_o),
    .wb_dat_i(wbm0_dat_i),
    .wb_sel_o(wbm0_sel_o),
    .wb_we_o(wbm0_we_o),

    .csr_op_i(mem1_mem2_csr_op),
    .csr_data_i(mem1_mem2_csr_data),
    .csr_raddr_o(csr_raddr),
    .csr_rdata_i(csr_rdata),
    .csr_waddr_o(csr_waddr),
    .csr_wdata_o(csr_wdata),
    .csr_we_o(csr_we)

    // // [debug]
    // .pc_now_i(mem1_mem2_pc_now),
    // .pc_now_o(mem2_wb_pc_now)
  );

  /* ====================== MEM2/WB regs ====================== */
  // logic [31:0] mem2_wb_pc_now;  // [debug]

  /* ====================== Flash & Block RAM ====================== */
  assign flash_vpen = 1'b1;
  assign flash_we_n = 1'b1;
  assign flash_byte_n = 1'b0;
  
  flash_controller flash_controller (
      .clk(sys_clk),
      .rst(sys_rst),

      .wb_cyc_i(wbs4_cyc_o),
      .wb_stb_i(wbs4_stb_o),
      .wb_ack_o(wbs4_ack_i),
      .wb_adr_i(wbs4_adr_o),
      .wb_dat_i(wbs4_dat_o),
      .wb_dat_o(wbs4_dat_i),
      .wb_sel_i(wbs4_sel_o),
      .wb_we_i (wbs4_we_o),

      .flash_a_o(flash_a),
      .flash_d(flash_d),
      .flash_rp_o(flash_rp_n),
      .flash_ce_o(flash_ce_n),
      .flash_oe_o(flash_oe_n)
  );

  logic [BRAM_DATA_WIDTH-1:0] bram_0_wdata;
  logic [BRAM_ADDR_WIDTH-1:0] bram_0_waddr;
  logic bram_0_wea;

  logic [BRAM_DATA_WIDTH-1:0] bram_1_wdata;
  logic [BRAM_ADDR_WIDTH-1:0] bram_1_waddr;
  logic bram_1_wea;
  logic [BRAM_ADDR_WIDTH-1:0] bram_raddr;

  bram_controller bram_controller_0 (
      .clk(sys_clk),
      .rst(sys_rst),

      .wb_cyc_i(wbs5_cyc_o),
      .wb_stb_i(wbs5_stb_o),
      .wb_ack_o(wbs5_ack_i),
      .wb_adr_i(wbs5_adr_o),
      .wb_dat_i(wbs5_dat_o),
      .wb_dat_o(wbs5_dat_i),
      .wb_sel_i(wbs5_sel_o),
      .wb_we_i (wbs5_we_o),

      // BRAM read (not supported, always read 0)
      .bram_addr_b_o(),
      .bram_data_i({BRAM_DATA_WIDTH{1'b0}}),

      // BRAM write
      .bram_addr_a_o(bram_0_waddr),
      .bram_data_o(bram_0_wdata),
      .bram_wea_o(bram_0_wea)
  );

  bram_controller bram_controller_1 (
      .clk(sys_clk),
      .rst(sys_rst),

      .wb_cyc_i(wbs6_cyc_o),
      .wb_stb_i(wbs6_stb_o),
      .wb_ack_o(wbs6_ack_i),
      .wb_adr_i(wbs6_adr_o),
      .wb_dat_i(wbs6_dat_o),
      .wb_dat_o(wbs6_dat_i),
      .wb_sel_i(wbs6_sel_o),
      .wb_we_i (wbs6_we_o),

      // BRAM read (not supported, always read 0)
      .bram_addr_b_o(),
      .bram_data_i({BRAM_DATA_WIDTH{1'b0}}),

      // BRAM write
      .bram_addr_a_o(bram_1_waddr),
      .bram_data_o(bram_1_wdata),
      .bram_wea_o(bram_1_wea)
  );

  logic [BRAM_DATA_WIDTH-1:0] bram_0_rdata;
  logic [BRAM_DATA_WIDTH-1:0] bram_1_rdata;
  logic [BRAM_DATA_WIDTH-1:0] real_bram_rdata;
  logic vga_ack;
  logic [2:0] vga_scale;
  
  vga_controller vga_controller (
    .clk(sys_clk),
    .rst(sys_rst),

    .wb_cyc_i(wbs7_cyc_o),
    .wb_stb_i(wbs7_stb_o),
    .wb_ack_o(wbs7_ack_i),
    .wb_adr_i(wbs7_adr_o),
    .wb_dat_i(wbs7_dat_o),
    .wb_dat_o(wbs7_dat_i),
    .wb_sel_i(wbs7_sel_o),
    .wb_we_i (wbs7_we_o),
  
    .bram_0_rdata_i(bram_0_rdata),
    .bram_1_rdata_i(bram_1_rdata),
    .bram_rdata_o(real_bram_rdata),

    .vga_ack_i(vga_ack),
    .vga_scale_o(vga_scale)
  );

  gpio_controller gpio_controller (
      .clk(sys_clk),
      .rst(sys_rst),

      .wb_cyc_i(wbs8_cyc_o),
      .wb_stb_i(wbs8_stb_o),
      .wb_ack_o(wbs8_ack_i),
      .wb_adr_i(wbs8_adr_o),
      .wb_dat_i(wbs8_dat_o),
      .wb_dat_o(wbs8_dat_i),
      .wb_sel_i(wbs8_sel_o),
      .wb_we_i (wbs8_we_o),

      .dip_sw_i(dip_sw),
      .touch_btn_i(touch_btn),
      .push_btn_i(push_btn)
  );

  assign video_clk = clk_50M;

  // [debug]
  wire [12-1:0] hdata_o;
  wire [12-1:0] vdata_o;

  vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .vga_clk(clk_50M),
    .sys_rst(sys_rst),
    .vga_scale_i(vga_scale),
    .bram_raddr_o(bram_raddr),
    .bram_data_i(real_bram_rdata),
    .vga_ack_o(vga_ack),
    .video_red_o(video_red),
    .video_green_o(video_green),
    .video_blue_o(video_blue),
    .video_hsync_o(video_hsync),
    .video_vsync_o(video_vsync),
    .video_de_o(video_de),

    // [debug]
    .hdata_o(hdata_o),
    .vdata_o(vdata_o) 
  );

  bram0 bram_0 (
    .clka (sys_clk),
    .ena  (1'b1),
    .wea  (bram_0_wea),
    .addra(bram_0_waddr),
    .dina (bram_0_wdata),
    .clkb (clk_50M),
    .enb  (1'b1),
    .addrb(bram_raddr),
    .doutb(bram_0_rdata)
  );

  bram1 bram_1 (
    .clka (sys_clk),
    .ena  (1'b1),
    .wea  (bram_1_wea),
    .addra(bram_1_waddr),
    .dina (bram_1_wdata),
    .clkb (clk_50M),
    .enb  (1'b1),
    .addrb(bram_raddr),
    .doutb(bram_1_rdata)
  );

  // // 不使用内存�?�串口时，禁用其使能信号
  // assign base_ram_ce_n = 1'b1;
  // assign base_ram_oe_n = 1'b1;
  // assign base_ram_we_n = 1'b1;

  // assign ext_ram_ce_n = 1'b1;
  // assign ext_ram_oe_n = 1'b1;
  // assign ext_ram_we_n = 1'b1;

  // assign uart_rdn = 1'b1;
  // assign uart_wrn = 1'b1;

  // // ć°ç çŽĄčżćĽĺłçłťç¤şćĺžďźdpy1 ĺç
  // // p=dpy0[0] // ---a---
  // // c=dpy0[1] // |     |
  // // d=dpy0[2] // f     b
  // // e=dpy0[3] // |     |
  // // b=dpy0[4] // ---g---
  // // a=dpy0[5] // |     |
  // // f=dpy0[6] // e     c
  // // g=dpy0[7] // |     |
  // //           // ---d---  p

  // // 7 段数码管译码器演示，�????????? number �????????? 16 进制显示在数码管上面
  // logic [7:0] number;
  // SEG7_LUT segL (
  //     .oSEG1(dpy0),
  //     .iDIG (number[3:0])
  // );  // dpy0 ćŻä˝ä˝ć°ç çŽĄ
  // SEG7_LUT segH (
  //     .oSEG1(dpy1),
  //     .iDIG (number[7:4])
  // );  // dpy1 ćŻéŤä˝ć°ç çŽĄ

  // logic [15:0] led_bits;
  // assign leds = led_bits;

  // always_ff @(posedge push_btn or posedge reset_btn) begin
  //   if (reset_btn) begin  // 复位按下，设�????????? LED 为初始�??
  //     led_bits <= 16'h1;
  //   end else begin  // 每次按下按钮�?????????关，LED 循环左移
  //     led_bits <= {led_bits[14:0], led_bits[15]};
  //   end
  // end

  // // 直连串口接收发�?�演示，从直连串口收到的数据再发送出�?????????
  // logic [7:0] ext_uart_rx;
  // logic [7:0] ext_uart_buffer, ext_uart_tx;
  // logic ext_uart_ready, ext_uart_clear, ext_uart_busy;
  // logic ext_uart_start, ext_uart_avai;

  // assign number = ext_uart_buffer;

  // // 接收模块�?????????9600 无检验位
  // async_receiver #(
  //     .ClkFrequency(50000000),
  //     .Baud(9600)
  // ) ext_uart_r (
  //     .clk           (clk_50M),         // 外部时钟信号
  //     .RxD           (rxd),             // 外部串行信号输入
  //     .RxD_data_ready(ext_uart_ready),  // 数据接收到标�?????????
  //     .RxD_clear     (ext_uart_clear),  // 清除接收标志
  //     .RxD_data      (ext_uart_rx)      // 接收到的�?????????字节数据
  // );

  // assign ext_uart_clear = ext_uart_ready; // 收到数据的同时，清除标志，因为数据已取到 ext_uart_buffer �?????????
  // always_ff @(posedge clk_50M) begin  // 接收到缓冲区 ext_uart_buffer
  //   if (ext_uart_ready) begin
  //     ext_uart_buffer <= ext_uart_rx;
  //     ext_uart_avai   <= 1;
  //   end else if (!ext_uart_busy && ext_uart_avai) begin
  //     ext_uart_avai <= 0;
  //   end
  // end
  // always_ff @(posedge clk_50M) begin  // 将缓冲区 ext_uart_buffer 发�?�出�?????????
  //   if (!ext_uart_busy && ext_uart_avai) begin
  //     ext_uart_tx <= ext_uart_buffer;
  //     ext_uart_start <= 1;
  //   end else begin
  //     ext_uart_start <= 0;
  //   end
  // end

  // // 发�?�模块，9600 无检验位
  // async_transmitter #(
  //     .ClkFrequency(50000000),
  //     .Baud(9600)
  // ) ext_uart_t (
  //     .clk      (clk_50M),         // 外部时钟信号
  //     .TxD      (txd),             // 串行信号输出
  //     .TxD_busy (ext_uart_busy),   // 发�?�器忙状态指�?????????
  //     .TxD_start(ext_uart_start),  // �?????????始发送信�?????????
  //     .TxD_data (ext_uart_tx)      // 待发送的数据
  // );

  /* =========== Demo code end =========== */


endmodule
