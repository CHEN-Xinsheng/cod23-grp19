`include "../header.sv"


module pipeline_controller (
    // input wire if_ack_i,
    input wire                      mem_ack_i,
    input wire                      exe_mem1_mem_en_i,
    
    input wire [REG_ADDR_WIDTH-1:0] id_rf_raddr_a_comb_i,
    input wire [REG_ADDR_WIDTH-1:0] id_rf_raddr_b_comb_i,
    input wire                      id_exe_mem_en_i,
    input wire                      id_exe_mem_we_i,
    input wire                      id_exe_rf_wen_i,
    input wire [REG_ADDR_WIDTH-1:0] id_exe_rf_waddr_i,
    input wire                      branch_taken_i,

    input wire [REG_ADDR_WIDTH-1:0] exe_mem1_rf_waddr_i,
    input wire [REG_ADDR_WIDTH-1:0] rf_waddr_i,


    input wire                      exe_branch_comb_i,
    input wire                      csr_branch_i,

    // output reg [3:0] stall_o,
    // output reg [3:0] bubble_o
    output reg                      if_stall_o,
    output reg                      id_stall_o,
    output reg                      exe_stall_o,
    output reg                      mem_stall_o,

    output reg                      if_bubble_o,
    output reg                      id_bubble_o,
    output reg                      exe_bubble_o,
    output reg                      mem_bubble_o
);

    always_comb begin
        // MEM 正在请求总线
        if (exe_mem1_mem_en_i == 1 && mem_ack_i == 0) begin
            {if_stall_o, id_stall_o, exe_stall_o, mem_stall_o}     = 4'b1110;
            {if_bubble_o, id_bubble_o, exe_bubble_o, mem_bubble_o} = 4'b0001;
        end else if (csr_branch_i == 1) begin
            {if_stall_o, id_stall_o, exe_stall_o, mem_stall_o}     = 4'b0000;
            {if_bubble_o, id_bubble_o, exe_bubble_o, mem_bubble_o} = 4'b1110;
        // 分支跳转成功，清空 IF、ID
        end else if (branch_taken_i == 0) begin
            {if_stall_o, id_stall_o, exe_stall_o, mem_stall_o}     = 4'b0000;
            {if_bubble_o, id_bubble_o, exe_bubble_o, mem_bubble_o} = 4'b1100;
        /* version 1: without data-forwarding */
        // end else if (
        //      (id_exe_rf_waddr_i != 0  && (id_rf_raddr_a_comb_i == id_exe_rf_waddr_i  || id_rf_raddr_b_comb_i == id_exe_rf_waddr_i))
        //   || (exe_mem1_rf_waddr_i != 0 && (id_rf_raddr_a_comb_i == exe_mem1_rf_waddr_i || id_rf_raddr_b_comb_i == exe_mem1_rf_waddr_i))
        // //   || (rf_waddr_i != 0         && (id_rf_raddr_a_comb_i == rf_waddr_i         || id_rf_raddr_b_comb_i == rf_waddr_i))
        // ) begin
        //     stall_o = 4'b1000;
        //     bubble_o = 4'b0100;
        
        /* version 2: data-forwarding */
        // 无法用旁路解决的数据冲突：load-use ([ID]use, [EXE]load)，则插入一个气泡到 ID/EXE
        end else if (
               id_exe_mem_en_i && !id_exe_mem_we_i && id_exe_rf_wen_i && id_exe_rf_waddr_i != 0 
           && (id_exe_rf_waddr_i == id_rf_raddr_a_comb_i || id_exe_rf_waddr_i == id_rf_raddr_b_comb_i)
        ) begin
            {if_stall_o, id_stall_o, exe_stall_o, mem_stall_o}     = 4'b1000;
            {if_bubble_o, id_bubble_o, exe_bubble_o, mem_bubble_o} = 4'b0100;

        // IF 正在请求总线
        // end else if (if_ack_i == 0) begin
        //     stall_o = 4'b0000;
        //     bubble_o = 4'b1000;
        end else begin
            {if_stall_o, id_stall_o, exe_stall_o, mem_stall_o}     = 4'b0000;
            {if_bubble_o, id_bubble_o, exe_bubble_o, mem_bubble_o} = 4'b0000;
        end
    end
    
endmodule