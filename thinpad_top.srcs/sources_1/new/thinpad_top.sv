`default_nettype none
`include "header.sv"


module thinpad_top (
    input wire clk_50M,     // 50MHz 时钟输入
    input wire clk_11M0592, // 11.0592MHz 时钟输入（备用，可不用）

    input wire push_btn,  // BTN5 按钮开关，带消抖电路，按下时为 1
    input wire reset_btn, // BTN6 复位按钮，带消抖电路，按下时为 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4，按钮开关，按下时为 1
    input  wire [31:0] dip_sw,     // 32 位拨码开关，拨到“ON”时为 1
    output wire [15:0] leds,       // 16 位 LED，输出时 1 点亮
    output wire [ 7:0] dpy0,       // 数码管低位信号，包括小数点，输出 1 点亮
    output wire [ 7:0] dpy1,       // 数码管高位信号，包括小数点，输出 1 点亮

    // CPLD 串口控制器信号
    output wire uart_rdn,        // 读串口信号，低有效
    output wire uart_wrn,        // 写串口信号，低有效
    input  wire uart_dataready,  // 串口数据准备好
    input  wire uart_tbre,       // 发送数据标志
    input  wire uart_tsre,       // 数据发送完毕标志

    // BaseRAM 信号
    inout wire [31:0] base_ram_data,  // BaseRAM 数据，低 8 位与 CPLD 串口控制器共享
    output wire [19:0] base_ram_addr,  // BaseRAM 地址
    output wire [3:0] base_ram_be_n,  // BaseRAM 字节使能，低有效。如果不使用字节使能，请保持为 0
    output wire base_ram_ce_n,  // BaseRAM 片选，低有效
    output wire base_ram_oe_n,  // BaseRAM 读使能，低有效
    output wire base_ram_we_n,  // BaseRAM 写使能，低有效

    // ExtRAM 信号
    inout wire [31:0] ext_ram_data,  // ExtRAM 数据
    output wire [19:0] ext_ram_addr,  // ExtRAM 地址
    output wire [3:0] ext_ram_be_n,  // ExtRAM 字节使能，低有效。如果不使用字节使能，请保持为 0
    output wire ext_ram_ce_n,  // ExtRAM 片选，低有效
    output wire ext_ram_oe_n,  // ExtRAM 读使能，低有效
    output wire ext_ram_we_n,  // ExtRAM 写使能，低有效

    // 直连串口信号
    output wire txd,  // 直连串口发送端
    input  wire rxd,  // 直连串口接收端

    // Flash 存储器信号，参考 JS28F640 芯片手册
    output wire [22:0] flash_a,  // Flash 地址，a0 仅在 8bit 模式有效，16bit 模式无意义
    inout wire [15:0] flash_d,  // Flash 数据
    output wire flash_rp_n,  // Flash 复位信号，低有效
    output wire flash_vpen,  // Flash 写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,  // Flash 片选信号，低有效
    output wire flash_oe_n,  // Flash 读使能信号，低有效
    output wire flash_we_n,  // Flash 写使能信号，低有效
    output wire flash_byte_n, // Flash 8bit 模式选择，低有效。在使用 flash 的 16 位模式时请设为 1

    // USB 控制器信号，参考 SL811 芯片手册
    output wire sl811_a0,
    // inout  wire [7:0] sl811_d,     // USB 数据线与网络控制器的 dm9k_sd[7:0] 共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    // 网络控制器信号，参考 DM9000A 芯片手册
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // 图像输出信号
    output wire [2:0] video_red,    // 红色像素，3 位
    output wire [2:0] video_green,  // 绿色像素，3 位
    output wire [1:0] video_blue,   // 蓝色像素，2 位
    output wire       video_hsync,  // 行同步（水平同步）信号
    output wire       video_vsync,  // 场同步（垂直同步）信号
    output wire       video_clk,    // 像素时钟输出
    output wire       video_de      // 行数据有效信号，用于区分消隐区
);

  /* =========== Demo code begin =========== */

  // PLL 分频示例
  logic locked, clk_10M, clk_20M;
  pll_example clock_gen (
      // Clock in ports
      .clk_in1(clk_50M),  // 外部时钟输入
      // Clock out ports
      .clk_out1(clk_10M),  // 时钟输出 1，频率在 IP 配置界面中设置
      .clk_out2(clk_20M),  // 时钟输出 2，频率在 IP 配置界面中设置
      // Status and control signals
      .reset(reset_btn),  // PLL 复位输入
      .locked(locked)  // PLL 锁定指示输出，"1"表示时钟稳定，
                       // 后级电路复位信号应当由它生成（见下）
  );

  logic reset_of_clk10M;
  // 异步复位，同步释放，将 locked 信号转为后级电路的复位 reset_of_clk10M
  always_ff @(posedge clk_10M or negedge locked) begin
    if (~locked) reset_of_clk10M <= 1'b1;
    else reset_of_clk10M <= 1'b0;
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

  assign sys_clk = clk_10M;
  assign sys_rst = reset_of_clk10M;

  // 本实验不使用 CPLD 串口，禁用防止总线冲突
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

  wb_mux_4 wb_mux (
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
      .wbs3_cyc_o(wbs3_cyc_o)
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

  // 串口控制器模块
  // NOTE: 如果修改系统时钟频率，也需要修改此处的时钟频率参数
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

  logic time_interrupt;

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
    .time_interrupt_o(time_interrupt)
  );

  // logic [3:0] stall;
  // logic [3:0] bubble;
  logic if_stall;
  logic id_stall;
  logic exe_stall;
  logic mem_stall;
  logic if_bubble;
  logic id_bubble;
  logic exe_bubble;
  logic mem_bubble;

  logic [4:0] id_rf_raddr_a_comb;
  logic [4:0] id_rf_raddr_b_comb;
  logic exe_branch_comb;

  logic branch_taken;
  logic [31:0] pc_true;


  pipeline_controller pipeline_controller (
    // .if_ack_i(wbm1_ack_i),
    .mem_ack_i(wbm0_ack_i),
    .exe_mem1_mem_en_i(exe_mem1_mem_en),

    .id_rf_raddr_a_comb_i(id_rf_raddr_a_comb),
    .id_rf_raddr_b_comb_i(id_rf_raddr_b_comb),
    .id_exe_mem_en_i(id_exe_mem_en),
    .id_exe_mem_we_i(id_exe_mem_we),
    .id_exe_rf_wen_i(id_exe_rf_wen),
    .id_exe_rf_waddr_i(id_exe_rf_waddr),
    .branch_taken_i(branch_taken),

    .exe_mem1_rf_waddr_i(exe_mem1_rf_waddr),
    .rf_waddr_i(rf_waddr),

    .exe_branch_comb_i(exe_branch_comb),
    .csr_branch_i(csr_branch),

    // .stall_o(stall),
    // .bubble_o(bubble)
    .if_stall_o(if_stall),
    .id_stall_o(id_stall),
    .exe_stall_o(exe_stall),
    .mem_stall_o(mem_stall),
    .if_bubble_o(if_bubble),
    .id_bubble_o(id_bubble),
    .exe_bubble_o(exe_bubble),
    .mem_bubble_o(mem_bubble)
  );

  logic fencei;
  logic [31:0] icache_pc_vaddr;
  logic [31:0] icache_pc_paddr;
  // logic [31:0] icache_pc_cached;
  logic [31:0] if_mmu_ack;
  logic icache_ack;
  logic [31:0] icache_inst;

  logic [31:0] pred_pc;

  /* ====================== IF1 ====================== */

  pc_mux pc_mux (
    // .branch_a_i(csr_branch),
    // .branch_b_i(exe_branch_comb),
    // .pc_next_a_i(csr_pc_next),
    // .pc_next_b_i(pc_next_comb),
    // .pc_now_i(icache_pc),
    // .branch_o(if_branch),
    // .pc_next_o(if_pc_next)
    .csr_branch_i(csr_branch),
    .exe_branch_comb_i(exe_branch_comb),
    .csr_pc_next_i(csr_pc_next),
    .id_exe_pc_now(id_exe_pc_now),
    .if_id_pc_now(if_id_pc_now),
    .pc_next_comb(pc_next_comb),
    .icache_pc(icache_pc),
    .branch_taken(branch_taken),
    .pc_true(pc_true)
  );

  IF IF (
    .clk(sys_clk),
    .rst(sys_rst),
    // .wb_cyc_o(wbm1_cyc_o),
    // .wb_stb_o(wbm1_stb_o),
    // .wb_ack_i(wbm1_ack_i),
    // .wb_adr_o(wbm1_adr_o),
    // .wb_dat_o(wbm1_dat_o),
    // .wb_dat_i(wbm1_dat_i),
    // .wb_sel_o(wbm1_sel_o),
    // .wb_we_o(wbm1_we_o),
    .inst_o(if_id_inst),
    .pc_now_o(if_id_pc_now),
    .branch_taken_i(branch_taken),
    .pc_true_i(pc_true),
    .pc_pred_i(pred_pc),
    .icache_ack_i(icache_ack),
    .inst_i(icache_inst),
    .pc_o(icache_pc_vaddr),
    .stall_i(if_stall),
    .bubble_i(if_bubble)
  );

  logic page_fault;
  logic access_fault;

  mmu if_mmu (
    .clk(sys_clk),
    .rst(sys_rst),
    .mode_i(csr_mode),
    .satp_i(csr_satp),
    .vaddr_i(icache_pc_vaddr),
    .paddr_o(icache_pc_paddr),
    .ack_o(if_mmu_ack),

    .read_en_i(1'b0), 
    .write_en_i(1'b0),
    .exe_en_i(1'b1),
    .page_fault_o(page_fault),
    .access_fault_o(access_fault),

    .wb_cyc_o(wbm2_cyc_o),
    .wb_stb_o(wbm2_stb_o),
    .wb_ack_i(wbm2_ack_i),
    .wb_adr_o(wbm2_adr_o),
    .wb_dat_o(wbm2_dat_o),
    .wb_dat_i(wbm2_dat_i),
    .wb_sel_o(wbm2_sel_o),
    .wb_we_o(wbm2_we_o)
  );

  btb btb (
    .clk(sys_clk),
    .rst(sys_rst),
    .pc_i(icache_pc_vaddr),
    .pred_pc_o(pred_pc),
    .branch_from_pc_i(id_exe_pc_now),
    .branch_to_pc_i(pc_next_comb),
    .branch_taken_i(branch_taken),
    .is_branch_i(id_exe_jump || id_exe_imm_type == `TYPE_B)
  );

  /* ====================== IF2 ====================== */
  icache icache (
    .clk(sys_clk),
    .rst(sys_rst),
    .fence_i(fencei),
    .pc_i(icache_pc_paddr),
    .enable_i(1'b1),
    .wb_cyc_o(wbm1_cyc_o),
    .wb_stb_o(wbm1_stb_o),
    .wb_ack_i(wbm1_ack_i),
    .wb_adr_o(wbm1_adr_o),
    .wb_dat_o(wbm1_dat_o),
    .wb_dat_i(wbm1_dat_i),
    .wb_sel_o(wbm1_sel_o),
    .wb_we_o(wbm1_we_o),
    .inst_o(icache_inst),
    .icache_ack_o(icache_ack)
  );

    //   always_ff @(posedge sys_clk) begin
    //     if (sys_rst) begin
    //         id_exe_inst <= 32'h0;
    //         if_id_pc_now <= 32'h0;
    //     end else begin
    //         if (stall[3]) begin
    //         end else if (bubble[3]) begin
    //             id_exe_inst <= 32'h0;
    //             if_id_pc_now <= 32'h0;
    //         end else if (icache_ack) begin
    //             if (icache_pc_cached != 0) begin
    //                 id_exe_inst <= 32'h0;
    //                 if_id_pc_now <= 32'h0;
    //             end else begin
    //                 id_exe_inst <= icache_inst;
    //                 if_id_pc_now <= icache_pc;
    //             end
    //         end else begin
    //             id_exe_inst <= 32'h0;
    //             if_id_pc_now <= 32'h0;
    //         end
    //     end
    // end

  /* ====================== IF2/ID regs ====================== */
  logic [31:0] if_id_inst;
  logic [31:0] if_id_pc_now;

  /* ====================== ID ====================== */
  ID ID (
    .clk(sys_clk),
    .rst(sys_rst),
    .inst_i(if_id_inst),
    .inst_o(id_exe_inst),
    .rf_raddr_a_o(id_exe_rf_raddr_a),
    .rf_raddr_b_o(id_exe_rf_raddr_b),
    .id_rf_raddr_a_comb(id_rf_raddr_a_comb),
    .id_rf_raddr_b_comb(id_rf_raddr_b_comb),
    .imm_type_o(id_exe_imm_type),
    .alu_op_o(id_exe_alu_op),
    .use_rs2_o(id_exe_use_rs2),
    .mem_en_o(id_exe_mem_en),
    .rf_wen_o(id_exe_rf_wen),
    .rf_waddr_o(id_exe_rf_waddr),
    .mem_we_o(id_exe_mem_we),
    .mem_sel_o(id_exe_mem_sel),
    .pc_now_i(if_id_pc_now),
    .pc_now_o(id_exe_pc_now),
    .use_pc_o(id_exe_use_pc),
    .jump_o(id_exe_jump),
    .comp_op_o(id_exe_comp_op),
    .csr_op_o(id_exe_csr_op),
    .ecall_o(id_exe_ecall),
    .ebreak_o(id_exe_ebreak),
    .mret_o(id_exe_mret),
    .fencei_o(fencei),
    .stall_i(id_stall),
    .bubble_i(if_bubble)
  );

  logic [4:0]  rf_waddr;
  logic [31:0] rf_wdata;
  logic rf_we;

  regfile regfile (
    .clk(sys_clk),
    .rst(sys_rst),
    .rf_raddr_a(id_exe_rf_raddr_a),
    .rf_rdata_a(rf_rdata_a),
    .rf_raddr_b(id_exe_rf_raddr_b),
    .rf_rdata_b(rf_rdata_b),
    .rf_waddr(rf_waddr),
    .rf_wdata(rf_wdata),
    .rf_we(rf_we)
  );

  logic [4:0]  id_exe_rf_raddr_a;
  logic [31:0] rf_rdata_a;
  logic [4:0]  id_exe_rf_raddr_b;
  logic [31:0] rf_rdata_b;

  logic [31:0] id_exe_inst;
  logic [2:0] id_exe_imm_type;
  logic [3:0] id_exe_alu_op;
  logic id_exe_use_rs2;
  logic id_exe_mem_en;
  logic id_exe_mem_we;
  logic id_exe_rf_wen;
  logic [4:0] id_exe_rf_waddr;
  logic [3:0] id_exe_mem_sel;
  logic [31:0] id_exe_pc_now;
  logic id_exe_use_pc;
  logic id_exe_comp_op;
  logic id_exe_jump;
  logic [2:0] id_exe_csr_op;
  logic id_exe_ecall;
  logic id_exe_ebreak;
  logic id_exe_mret;

  wire [31:0] pc_next_comb;

  EXE EXE (
    .clk(sys_clk),
    .rst(sys_rst),
    .rf_raddr_a_i(id_exe_rf_raddr_a),
    .rf_raddr_b_i(id_exe_rf_raddr_b),
    .rf_rdata_a_i(rf_rdata_a),
    .rf_rdata_b_i(rf_rdata_b),
    .inst_i(id_exe_inst),
    .imm_type_i(id_exe_imm_type),
    .use_rs2_i(id_exe_use_rs2),
    .alu_a_o(alu_a),
    .alu_b_o(alu_b),
    .alu_y_i(alu_y),
    .alu_result_o(exe_mem1_alu_result),
    .mem_en_i(id_exe_mem_en),
    .mem_en_o(exe_mem1_mem_en),
    .rf_wen_i(id_exe_rf_wen),
    .rf_wen_o(exe_mem1_rf_wen),
    .rf_waddr_i(id_exe_rf_waddr),
    .rf_waddr_o(exe_mem1_rf_waddr),
    .mem_we_i(id_exe_mem_we),
    .mem_we_o(exe_mem1_mem_we),
    .mem_sel_i(id_exe_mem_sel),
    .mem_sel_o(exe_mem1_mem_sel),
    .mem_wdata_o(exe_mem1_mem_wdata),
    .use_pc_i(id_exe_use_pc),
    .comp_op_i(id_exe_comp_op),
    .jump_i(id_exe_jump),
    .pc_now_i(id_exe_pc_now),
    .pc_next_o(pc_next_comb),
    .branch_comb_o(exe_branch_comb),
    .csr_op_i(id_exe_csr_op),
    .csr_raddr_o(csr_raddr),
    .csr_rdata_i(csr_rdata),
    .csr_waddr_o(csr_waddr),
    .csr_wdata_o(csr_wdata),
    .csr_we_o(csr_we),
    
    // data forwarding
    .exe_mem1_rf_waddr_i(exe_mem1_rf_waddr),
    .exe_mem1_alu_result_i(exe_mem1_alu_result),

    // stall & bubble
    .stall_i(exe_stall),
    .bubble_i(exe_bubble),

    // debug
    .pc_now_o(exe_mem1_pc_now)
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

  logic [11:0] csr_raddr;
  logic [31:0] csr_rdata;
  logic [11:0] csr_waddr;
  logic [31:0] csr_wdata;
  logic csr_we;

  logic [31:0] csr_pc_next;
  logic csr_branch;

  logic [1:0] csr_mode;
  satp_t csr_satp;

  csrfile csrfile (
    .clk(sys_clk),
    .rst(sys_rst),
    .raddr_i(csr_raddr),
    .rdata_o(csr_rdata),
    .waddr_i(csr_waddr),
    .wdata_i(csr_wdata),
    .we_i(csr_we),
    .pc_now_i(id_exe_pc_now),
    .pc_next_o(csr_pc_next),
    .branch_o(csr_branch),
    .ecall_i(id_exe_ecall),
    .ebreak_i(id_exe_ebreak),
    .mret_i(id_exe_mret),
    .time_interrupt_i(time_interrupt),
    .page_fault_i(page_fault),
    .access_fault_i(access_fault),
    .satp_o(csr_satp)
    .mode_o(csr_mode),
  );

  logic [ADDR_WIDTH-1:0]      exe_mem1_pc_now;  // only for debug
  logic                       exe_mem1_mem_en;
  logic                       exe_mem1_rf_wen;
  logic [REG_ADDR_WIDTH-1:0]  exe_mem1_rf_waddr;
  logic [DATA_WIDTH-1:0]      exe_mem1_alu_result;
  logic                       exe_mem1_mem_we;
  logic [DATA_WIDTH/8-1:0]    exe_mem1_mem_sel;
  logic [DATA_WIDTH-1:0]      exe_mem1_mem_wdata;

  /* ====================== MEM1 ====================== */
  logic                       mem_mmu_ack;
  mmu mem_mmu (
    .clk(sys_clk),
    .rst(sys_rst),

    .mode_i(csr_mode),
    .satp_i(csr_satp),
    .vaddr_i(exe_mem1_alu_result),
    .paddr_o(mem1_mem2_paddr),
    .ack_o(mem_mmu_ack),

    .read_en_i(1'b0), 
    .write_en_i(1'b0),
    .exe_en_i(1'b1),
    .page_fault_o(mem1_page_fault),
    .access_fault_o(mem1_access_fault),

    .wb_cyc_o(wbm3_cyc_o),
    .wb_stb_o(wbm3_stb_o),
    .wb_ack_i(wbm3_ack_i),
    .wb_adr_o(wbm3_adr_o),
    .wb_dat_o(wbm3_dat_o),
    .wb_dat_i(wbm3_dat_i),
    .wb_sel_o(wbm3_sel_o),
    .wb_we_o(wbm3_we_o),

    // data direct pass
    .exe_mem1_pc_now      (exe_mem1_pc_now),  // only for debug
    .exe_mem1_mem_en      (exe_mem1_mem_en),
    .exe_mem1_rf_wen      (exe_mem1_rf_wen),
    .exe_mem1_rf_waddr    (exe_mem1_rf_waddr),
    .exe_mem1_alu_result  (exe_mem1_alu_result),
    .exe_mem1_mem_we      (exe_mem1_mem_we),
    .exe_mem1_mem_sel     (exe_mem1_mem_sel),
    .exe_mem1_mem_wdata   (exe_mem1_mem_wdata),

    .mem1_mem2_pc_now     (mem1_mem2_pc_now),  // only for debug
    .mem1_mem2_mem_en     (mem1_mem2_mem_en),
    .mem1_mem2_rf_wen     (mem1_mem2_rf_wen),
    .mem1_mem2_rf_waddr   (mem1_mem2_rf_waddr),
    .mem1_mem2_alu_result (mem1_mem2_alu_result),  // only for debug
    .mem1_mem2_mem_we     (mem1_mem2_mem_we),
    .mem1_mem2_mem_sel    (mem1_mem2_mem_sel),
    .mem1_mem2_mem_wdata  (mem1_mem2_mem_wdata)
  );

  logic [ADDR_WIDTH-1:0]      mem1_mem2_paddr;

  logic [ADDR_WIDTH-1:0]      mem1_mem2_pc_now;      // only for debug
  logic                       mem1_mem2_mem_en;
  logic                       mem1_mem2_rf_wen;
  logic [REG_ADDR_WIDTH-1:0]  mem1_mem2_rf_waddr;
  logic [DATA_WIDTH-1:0]      mem1_mem2_alu_result;  // only for debug
  logic                       mem1_mem2_mem_we;
  logic [DATA_WIDTH/8-1:0]    mem1_mem2_mem_sel;
  logic [DATA_WIDTH-1:0]      mem1_mem2_mem_wdata;
  
  /* ====================== MEM2 ====================== */
  MEM MEM (
    .clk(sys_clk),
    .rst(sys_rst),

    .mem_en_i(mem1_mem2_mem_en),
    .mem_addr_i(mem1_mem2_paddr),
    .rf_wen_i(mem1_mem2_rf_wen),
    .rf_waddr_i(mem1_mem2_rf_waddr),
    .rf_wdata_o(rf_wdata),
    .rf_wen_o(rf_we),
    .rf_waddr_o(rf_waddr),
    .mem_we_i(mem1_mem2_mem_we),
    .mem_sel_i(mem1_mem2_mem_sel),
    .mem_wdata_i(mem1_mem2_mem_wdata),

    .stall_i(mem_stall),
    .bubble_i(mem_bubble),

    .wb_cyc_o(wbm0_cyc_o),
    .wb_stb_o(wbm0_stb_o),
    .wb_ack_i(wbm0_ack_i),
    .wb_adr_o(wbm0_adr_o),
    .wb_dat_o(wbm0_dat_o),
    .wb_dat_i(wbm0_dat_i),
    .wb_sel_o(wbm0_sel_o),
    .wb_we_o(wbm0_we_o),

    // debug
    .pc_now_i(mem1_mem2_pc_now),
    .pc_now_o(mem2_wb_pc_now)
  );

  logic [31:0] mem2_wb_pc_now;  // only for debug


  // // 不使用内存、串口时，禁用其使能信号
  // assign base_ram_ce_n = 1'b1;
  // assign base_ram_oe_n = 1'b1;
  // assign base_ram_we_n = 1'b1;

  // assign ext_ram_ce_n = 1'b1;
  // assign ext_ram_oe_n = 1'b1;
  // assign ext_ram_we_n = 1'b1;

  // assign uart_rdn = 1'b1;
  // assign uart_wrn = 1'b1;

  // // 数码管连接关系示意图，dpy1 同理
  // // p=dpy0[0] // ---a---
  // // c=dpy0[1] // |     |
  // // d=dpy0[2] // f     b
  // // e=dpy0[3] // |     |
  // // b=dpy0[4] // ---g---
  // // a=dpy0[5] // |     |
  // // f=dpy0[6] // e     c
  // // g=dpy0[7] // |     |
  // //           // ---d---  p

  // // 7 段数码管译码器演示，将 number 用 16 进制显示在数码管上面
  // logic [7:0] number;
  // SEG7_LUT segL (
  //     .oSEG1(dpy0),
  //     .iDIG (number[3:0])
  // );  // dpy0 是低位数码管
  // SEG7_LUT segH (
  //     .oSEG1(dpy1),
  //     .iDIG (number[7:4])
  // );  // dpy1 是高位数码管

  // logic [15:0] led_bits;
  // assign leds = led_bits;

  // always_ff @(posedge push_btn or posedge reset_btn) begin
  //   if (reset_btn) begin  // 复位按下，设置 LED 为初始值
  //     led_bits <= 16'h1;
  //   end else begin  // 每次按下按钮开关，LED 循环左移
  //     led_bits <= {led_bits[14:0], led_bits[15]};
  //   end
  // end

  // // 直连串口接收发送演示，从直连串口收到的数据再发送出去
  // logic [7:0] ext_uart_rx;
  // logic [7:0] ext_uart_buffer, ext_uart_tx;
  // logic ext_uart_ready, ext_uart_clear, ext_uart_busy;
  // logic ext_uart_start, ext_uart_avai;

  // assign number = ext_uart_buffer;

  // // 接收模块，9600 无检验位
  // async_receiver #(
  //     .ClkFrequency(50000000),
  //     .Baud(9600)
  // ) ext_uart_r (
  //     .clk           (clk_50M),         // 外部时钟信号
  //     .RxD           (rxd),             // 外部串行信号输入
  //     .RxD_data_ready(ext_uart_ready),  // 数据接收到标志
  //     .RxD_clear     (ext_uart_clear),  // 清除接收标志
  //     .RxD_data      (ext_uart_rx)      // 接收到的一字节数据
  // );

  // assign ext_uart_clear = ext_uart_ready; // 收到数据的同时，清除标志，因为数据已取到 ext_uart_buffer 中
  // always_ff @(posedge clk_50M) begin  // 接收到缓冲区 ext_uart_buffer
  //   if (ext_uart_ready) begin
  //     ext_uart_buffer <= ext_uart_rx;
  //     ext_uart_avai   <= 1;
  //   end else if (!ext_uart_busy && ext_uart_avai) begin
  //     ext_uart_avai <= 0;
  //   end
  // end
  // always_ff @(posedge clk_50M) begin  // 将缓冲区 ext_uart_buffer 发送出去
  //   if (!ext_uart_busy && ext_uart_avai) begin
  //     ext_uart_tx <= ext_uart_buffer;
  //     ext_uart_start <= 1;
  //   end else begin
  //     ext_uart_start <= 0;
  //   end
  // end

  // // 发送模块，9600 无检验位
  // async_transmitter #(
  //     .ClkFrequency(50000000),
  //     .Baud(9600)
  // ) ext_uart_t (
  //     .clk      (clk_50M),         // 外部时钟信号
  //     .TxD      (txd),             // 串行信号输出
  //     .TxD_busy (ext_uart_busy),   // 发送器忙状态指示
  //     .TxD_start(ext_uart_start),  // 开始发送信号
  //     .TxD_data (ext_uart_tx)      // 待发送的数据
  // );

  // // 图像输出演示，分辨率 800x600@75Hz，像素时钟为 50MHz
  // logic [11:0] hdata;
  // assign video_red   = hdata < 266 ? 3'b111 : 0;  // 红色竖条
  // assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0;  // 绿色竖条
  // assign video_blue  = hdata >= 532 ? 2'b11 : 0;  // 蓝色竖条
  // assign video_clk   = clk_50M;
  // vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
  //     .clk        (clk_50M),
  //     .hdata      (hdata),        // 横坐标
  //     .vdata      (),             // 纵坐标
  //     .hsync      (video_hsync),
  //     .vsync      (video_vsync),
  //     .data_enable(video_de)
  // );
  /* =========== Demo code end =========== */


endmodule
