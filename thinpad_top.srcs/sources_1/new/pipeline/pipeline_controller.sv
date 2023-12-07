`include "../header.sv"


module pipeline_controller (
    // input wire if_ack_i,
    input wire                      if1_ack_i,
    input wire                      if2_ack_i,
    input wire                      mem1_ack_i,
    input wire                      mem2_ack_i,
    input wire                      branch_taken_i,
    input wire                      csr_branch_i,
    input wire                      csr_inst_i,
    
    input wire [REG_ADDR_WIDTH-1:0] id_rf_raddr_a_comb_i,
    input wire [REG_ADDR_WIDTH-1:0] id_rf_raddr_b_comb_i,
    input wire                      id_exe_mem_re_i,
    input wire                      id_exe_rf_wen_i,
    input wire [REG_ADDR_WIDTH-1:0] id_exe_rf_waddr_i,
    input wire                      exe_mem1_mem_re_i,
    input wire                      exe_mem1_rf_wen_i,
    input wire [REG_ADDR_WIDTH-1:0] exe_mem1_rf_waddr_i,

    input wire                      mem1_mem2_mem_re_i,
    input wire                      mem1_mem2_mem_we_i, 


    // output reg [3:0] stall_o,
    // output reg [3:0] bubble_o
    output reg                      if_stall_o,
    output reg                      if2_stall_o,
    output reg                      id_stall_o,
    output reg                      exe_stall_o,
    output reg                      mem1_stall_o,
    output reg                      mem2_stall_o,

    output reg                      if_bubble_o,
    output reg                      if2_bubble_o,
    output reg                      id_bubble_o,
    output reg                      exe_bubble_o,
    output reg                      mem1_bubble_o,
    output reg                      mem2_bubble_o
);

    // TODO：pipeline_controller 需要保证 MEM1-EXE, MEM2-EXE 的指令都不是 load-use 关系

    always_comb begin
        if (((mem1_mem2_mem_re_i || mem1_mem2_mem_we_i) && ~mem2_ack_i) || (csr_branch_i && (~mem1_ack_i || ~if2_ack_i || ~if1_ack_i))) begin
            {if_stall_o, if2_stall_o, id_stall_o, exe_stall_o, mem1_stall_o, mem2_stall_o}       = 6'b111110;
            {if_bubble_o, if2_bubble_o, id_bubble_o, exe_bubble_o, mem1_bubble_o, mem2_bubble_o} = 6'b000001;
        end else if (csr_branch_i) begin
            {if_stall_o, if2_stall_o, id_stall_o, exe_stall_o, mem1_stall_o, mem2_stall_o}       = 6'b000000;
            {if_bubble_o, if2_bubble_o, id_bubble_o, exe_bubble_o, mem1_bubble_o, mem2_bubble_o} = 6'b111111;
        end else if (~mem1_ack_i) begin
            {if_stall_o, if2_stall_o, id_stall_o, exe_stall_o, mem1_stall_o, mem2_stall_o}       = 6'b111100;
            {if_bubble_o, if2_bubble_o, id_bubble_o, exe_bubble_o, mem1_bubble_o, mem2_bubble_o} = 6'b000010;
        end else if (~branch_taken_i && (~if1_ack_i || ~if2_ack_i)) begin
            {if_stall_o, if2_stall_o, id_stall_o, exe_stall_o, mem1_stall_o, mem2_stall_o}       = 6'b111000;
            {if_bubble_o, if2_bubble_o, id_bubble_o, exe_bubble_o, mem1_bubble_o, mem2_bubble_o} = 6'b000100;
        end else if (~branch_taken_i) begin
            {if_stall_o, if2_stall_o, id_stall_o, exe_stall_o, mem1_stall_o, mem2_stall_o}       = 6'b000000;
            {if_bubble_o, if2_bubble_o, id_bubble_o, exe_bubble_o, mem1_bubble_o, mem2_bubble_o} = 6'b111000;
        end else if (
               (id_exe_mem_re_i && id_exe_rf_wen_i && id_exe_rf_waddr_i != 0 
            && (id_exe_rf_waddr_i == id_rf_raddr_a_comb_i || id_exe_rf_waddr_i == id_rf_raddr_b_comb_i))
            || (exe_mem1_mem_re_i && exe_mem1_rf_wen_i && exe_mem1_rf_waddr_i != 0 
            && (exe_mem1_rf_waddr_i == id_rf_raddr_a_comb_i || exe_mem1_rf_waddr_i == id_rf_raddr_b_comb_i))
        ) begin
            {if_stall_o, if2_stall_o, id_stall_o, exe_stall_o, mem1_stall_o, mem2_stall_o}       = 6'b110000;
            {if_bubble_o, if2_bubble_o, id_bubble_o, exe_bubble_o, mem1_bubble_o, mem2_bubble_o} = 6'b001000;
        end else if (csr_inst_i) begin
            {if_stall_o, if2_stall_o, id_stall_o, exe_stall_o, mem1_stall_o, mem2_stall_o}       = 6'b100000;
            {if_bubble_o, if2_bubble_o, id_bubble_o, exe_bubble_o, mem1_bubble_o, mem2_bubble_o} = 6'b010000;
        end else if (~if2_ack_i) begin
            {if_stall_o, if2_stall_o, id_stall_o, exe_stall_o, mem1_stall_o, mem2_stall_o}       = 6'b100000;
            {if_bubble_o, if2_bubble_o, id_bubble_o, exe_bubble_o, mem1_bubble_o, mem2_bubble_o} = 6'b010000;
        end else if (~if1_ack_i) begin
            {if_stall_o, if2_stall_o, id_stall_o, exe_stall_o, mem1_stall_o, mem2_stall_o}       = 6'b000000;
            {if_bubble_o, if2_bubble_o, id_bubble_o, exe_bubble_o, mem1_bubble_o, mem2_bubble_o} = 6'b100000;
        end else begin
            {if_stall_o, if2_stall_o, id_stall_o, exe_stall_o, mem1_stall_o, mem2_stall_o}       = 6'b000000;
            {if_bubble_o, if2_bubble_o, id_bubble_o, exe_bubble_o, mem1_bubble_o, mem2_bubble_o} = 6'b000000;
        end
    end

        // MEM 正在请求总线
    //     if ((exe_mem1_mem_re_i || exe_mem1_mem_we_i) && mem_ack_i == 0) begin
    //         {if_stall_o, id_stall_o, exe_stall_o, mem_stall_o}     = 4'b1110;
    //         {if_bubble_o, id_bubble_o, exe_bubble_o, mem_bubble_o} = 4'b0001;
    //     end else if (csr_branch_i == 1) begin
    //         {if_stall_o, id_stall_o, exe_stall_o, mem_stall_o}     = 4'b0000;
    //         {if_bubble_o, id_bubble_o, exe_bubble_o, mem_bubble_o} = 4'b1110;
    //     // 分支跳转成功，清空 IF、ID
    //     end else if (branch_taken_i == 0) begin
    //         {if_stall_o, id_stall_o, exe_stall_o, mem_stall_o}     = 4'b0000;
    //         {if_bubble_o, id_bubble_o, exe_bubble_o, mem_bubble_o} = 4'b1100;
    //     /* version 1: without data-forwarding */
    //     // end else if (
    //     //      (id_exe_rf_waddr_i != 0  && (id_rf_raddr_a_comb_i == id_exe_rf_waddr_i  || id_rf_raddr_b_comb_i == id_exe_rf_waddr_i))
    //     //   || (exe_mem1_rf_waddr_i != 0 && (id_rf_raddr_a_comb_i == exe_mem1_rf_waddr_i || id_rf_raddr_b_comb_i == exe_mem1_rf_waddr_i))
    //     // //   || (rf_waddr_i != 0         && (id_rf_raddr_a_comb_i == rf_waddr_i         || id_rf_raddr_b_comb_i == rf_waddr_i))
    //     // ) begin
    //     //     stall_o = 4'b1000;
    //     //     bubble_o = 4'b0100;
        
    //     /* version 2: data-forwarding */
    //     // 无法用旁路解决的数据冲突：load-use ([ID]use, [EXE]load)，则插入一个气泡到 ID/EXE
    //     end else if (
    //            id_exe_mem_re_i && id_exe_rf_wen_i && id_exe_rf_waddr_i != 0 
    //        && (id_exe_rf_waddr_i == id_rf_raddr_a_comb_i || id_exe_rf_waddr_i == id_rf_raddr_b_comb_i)
    //     ) begin
    //         {if_stall_o, id_stall_o, exe_stall_o, mem_stall_o}     = 4'b1000;
    //         {if_bubble_o, id_bubble_o, exe_bubble_o, mem_bubble_o} = 4'b0100;

    //     // IF 正在请求总线
    //     // end else if (if_ack_i == 0) begin
    //     //     stall_o = 4'b0000;
    //     //     bubble_o = 4'b1000;
    //     end else begin
    //         {if_stall_o, id_stall_o, exe_stall_o, mem_stall_o}     = 4'b0000;
    //         {if_bubble_o, id_bubble_o, exe_bubble_o, mem_bubble_o} = 4'b0000;
    //     end
    // end
    
endmodule