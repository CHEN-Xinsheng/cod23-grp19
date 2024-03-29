`include "header.sv"

module mmu (
    input wire                          clk,
    input wire                          rst,

    // CPU interface
    input wire [`MODE_WIDTH-1:0]        mode_i,
    input wire satp_t                   satp_i,
    input wire                          mstatus_sum_i,
    // input wire                          mstatus_mxr_i, // mstatus.mxr is not implemented
    input wire vaddr_t                  vaddr_i,  // virtual address
    output reg [ADDR_WIDTH-1:0]         paddr_o,  // physical address
    output reg                          ack_o,    // If enable_i == 1, then only when ack_o == 1, the data that output to CPU interface is valid

    input wire [ADDR_WIDTH/8-1:0]       mem_sel_i,
    input wire                          enable_i,   // use MMU (some instructions does not need to read/write MEM, in such case, let enable_i = 0 in MEM stage)
    input wire                          read_en_i,  // for MEM stage, load instruction
    input wire                          write_en_i, // for MEM stage, store instruction
    input wire                          exe_en_i,   // for IF stage
    output reg                          load_page_fault_o,
    output reg                          store_page_fault_o,
    output reg                          instr_page_fault_o,
    output reg                          load_access_fault_o,
    output reg                          store_access_fault_o,
    output reg                          instr_access_fault_o,
    output reg                          load_misaligned_o,
    output reg                          store_misaligned_o,
    output reg                          instr_misaligned_o,

    // tlb reset
    input wire                          tlb_reset_i,   // for sfence.vma instruction

    // stall & bubble
    input wire                          stall_i,
    input wire                          bubble_i,

    // wishbone interface
    output reg                          wb_cyc_o,
    output reg                          wb_stb_o,
    input wire                          wb_ack_i,
    output reg [ADDR_WIDTH-1:0]         wb_adr_o,
    output reg [DATA_WIDTH-1:0]         wb_dat_o,
    input wire [DATA_WIDTH-1:0]         wb_dat_i,
    output reg [DATA_WIDTH/8-1:0]       wb_sel_o,
    output reg                          wb_we_o,

    // data direct pass (for IF1/IF2)
    output reg [ADDR_WIDTH-1:0]         if1_if2_pc_now,
    output reg                          if1_if2_icache_enable,

    // data direct pass (for MEM1/MEM2)
    input wire  [ADDR_WIDTH-1:0]        exe_mem1_pc_now,
    input wire                          exe_mem1_rf_wen,
    input wire  [REG_ADDR_WIDTH-1:0]    exe_mem1_rf_waddr,
    input wire  [DATA_WIDTH-1:0]        exe_mem1_alu_result,
    input wire                          exe_mem1_mem_re,
    input wire                          exe_mem1_mem_we,
    input wire  [DATA_WIDTH/8-1:0]      exe_mem1_mem_sel,
    input wire  [DATA_WIDTH-1:0]        exe_mem1_mem_wdata,
    input wire                          exe_mem1_load_type,
    input wire  [DATA_WIDTH-1:0]        exe_mem1_inst,
    input wire  [2:0]                   exe_mem1_csr_op,
    input wire  [DATA_WIDTH-1:0]        exe_mem1_csr_data,
    input wire                          exe_mem1_instr_page_fault,
    input wire                          exe_mem1_instr_access_fault,
    input wire                          exe_mem1_instr_misaligned,
    input wire                          exe_mem1_illegal_instr,
    input wire                          exe_mem1_ecall,
    input wire                          exe_mem1_ebreak,
    input wire                          exe_mem1_mret,
    input wire                          exe_mem1_sret,

    output reg  [ADDR_WIDTH-1:0]        mem1_mem2_pc_now,      // only for debug
    output reg                          mem1_mem2_rf_wen,
    output reg  [REG_ADDR_WIDTH-1:0]    mem1_mem2_rf_waddr,
    output reg  [DATA_WIDTH-1:0]        mem1_mem2_rf_wdata,
    output reg                          mem1_mem2_load_type,
    output reg  [ADDR_WIDTH-1:0]        mem1_mem2_mem_vaddr,
    output reg                          mem1_mem2_mem_re,
    output reg                          mem1_mem2_mem_we,
    output reg  [DATA_WIDTH/8-1:0]      mem1_mem2_mem_sel,
    output reg  [DATA_WIDTH-1:0]        mem1_mem2_mem_wdata,
    output reg  [DATA_WIDTH-1:0]        mem1_mem2_inst,
    output reg  [2:0]                   mem1_mem2_csr_op,
    output reg  [DATA_WIDTH-1:0]        mem1_mem2_csr_data,
    output reg                          mem1_mem2_instr_page_fault,
    output reg                          mem1_mem2_instr_access_fault,
    output reg                          mem1_mem2_instr_misaligned,
    output reg                          mem1_mem2_illegal_instr,
    output reg                          mem1_mem2_ecall,
    output reg                          mem1_mem2_ebreak,
    output reg                          mem1_mem2_mret,
    output reg                          mem1_mem2_sret

    // // [debug]
    // output reg [2:0]                    state_o,
    // output reg                          cur_level_o,
    // output reg                          direct_trans_o,
    // output reg [4:0]                    fault_case_o
);


wire direct_trans = (mode_i == `MODE_M || satp_i.mode == 1'b0)
                    || ( ~|((vaddr_i ^ 32'h8300_0000) & 32'hFF00_0000) )
                    || ( ~|((vaddr_i ^ 32'h8400_0000) & 32'hFF00_0000) )
                    || ( ~|((vaddr_i ^ 32'h8500_0000) & 32'hFF00_0000) )
                    || ( ~|((vaddr_i ^ 32'h8600_0000) & 32'hFFFF_FF00) )
                    || ( ~|((vaddr_i ^ 32'h8700_0000) & 32'hFFFF_FF00) );

wire pte_t  read_pte = pte_t'(wb_dat_i);
// Ref: 4.3.2 Virtual Address Translation Process
reg         cur_level;
pte_t       lv1_pte;
wire [33:0] pte_addr = (cur_level == 1'b1) 
                        ? {satp_i.ppn,                 vaddr_i.vpn1, 2'b00}   // (satp_i.ppn << 12)                   + (vaddr_i.vpn1 << 2)
                        : {lv1_pte.ppn1, lv1_pte.ppn0, vaddr_i.vpn0, 2'b00};  // ({lv1_pte.ppn1, lv1_pte.ppn0} << 12) + (vaddr_i.vpn0 << 2)
                        // |          PPN(22)        |   VPN(10)   |  00  |

// wishbone interface
assign wb_stb_o = wb_cyc_o;
assign wb_adr_o = pte_addr[ADDR_WIDTH-1:0];  // "拼出来的 34 位物理地址可以直接去掉最高的两位当作 32 位地址进行使用。"
assign wb_dat_o = {DATA_WIDTH{1'b0}};
assign wb_sel_o = {{DATA_WIDTH/8}{1'b1}};
assign wb_we_o  = 1'b0;

enum logic [2:0] {
    IDLE          = 1,
    FETCH_PTE     = 2,
    FETCH_PTE_LV0 = 3
} state;

// TLB
tlb_entry_t  tlb[0: N_TLB_ENTRY-1];

wire [TLB_INDEX_WIDTH-1:0]  tlb_index = vaddr_i[12+TLB_INDEX_WIDTH-1: 12];
wire tlb_entry_t            tlb_entry = tlb[tlb_index];
wire                        tlb_hit   = tlb_entry.valid 
                                        && tlb_entry.asid == satp_i.asid
                                        && tlb_entry.tag == vaddr_i[31:31-TLB_TAG_WIDTH+1];
// wire tlb_hit = 1'b0;

logic [ADDR_WIDTH-1:0] paddr_comb;
logic                  page_fault_comb;
logic                  access_fault_comb;
logic                  misaligned_comb;


// for convenience
wire leaf_pte_access_allowed = 
           (read_en_i        && !read_pte.r)
        // (!mstatus_mxr_i && read_en_i && !read_pte.r)
        // || (mstatus_mxr_i  && read_en_i && !(read_pte.r || read_pte.x))
        // /* (Ref: page 23) When MXR=0, only loads from pages marked readable (R=1 in Figure 4.18) will succeed.
        //     When MXR=1, loads from pages marked either readable or executable (R=1 or X=1) will succeed. */
        // /* mstatus.mxr is not implemented */
        || (write_en_i        && !read_pte.w)
        || (exe_en_i          && !read_pte.x)
        || (mode_i == `MODE_U && !read_pte.u)
        || (mode_i == `MODE_S && read_pte.u && !mstatus_sum_i);
        /* (Ref: page 23) When SUM=0, S-mode memory accesses to pages that are accessible by U-mode (U=1 in Figure 4.18) will fault. */

// // [debug]
// logic [4:0] fault_case;
// assign fault_case_o   = fault_case;
// assign state_o        = state;
// assign cur_level_o    = cur_level;
// assign direct_trans_o = direct_trans;


always_comb begin: output_ack_and_output_comb
    // default
    ack_o             = 1'b0;
    paddr_comb        = {ADDR_WIDTH{1'b0}};
    page_fault_comb   = 1'b0;
    access_fault_comb = 1'b0;
    misaligned_comb   = 1'b0;
    // fault_case   = 0;  // [debug]
    // cases
    casez (state)
        IDLE: begin
            if (enable_i) begin
                if (!(
                       (mem_sel_i == 4'b1111 && vaddr_i[1:0] == 2'b00)
                    || (mem_sel_i == 4'b0011 && vaddr_i[0]   == 1'b0)
                    || (mem_sel_i == 4'b0001)
                )) begin
                    raise_misaligned_comb();
                    // fault_case = 9;
                end else if (direct_trans) begin
                    if (!paddr_valid(vaddr_i)) begin
                        raise_access_fault_comb();
                        // fault_case = 1;
                    end else begin
                        ack_paddr_comb(vaddr_i);
                    end
                end else begin
                    /* need translation (vaddr -> paddr) */
                    if (!paddr_valid(pte_addr[ADDR_WIDTH-1:0])) begin
                        raise_access_fault_comb();
                        // fault_case = 2;
                    end else if (tlb_hit) begin
                        ack_paddr_comb({tlb_entry.ppn[19:0], vaddr_i[11:0]});
                    end else begin
                        ack_o = 1'b0;
                    end
                end
            end else begin
                ack_o = 1'b1;
            end
        end
        FETCH_PTE: begin
            if (wb_ack_i) begin
                // If PTE is invalid, raise page fault
                if (!read_pte.v || (!read_pte.r && read_pte.w)) begin
                    /* 3. If pte.v = 0, or if pte.r = 0 and pte.w = 1, or if any bits or encodings that are reserved for
                        future standard use are set within pte, stop and raise a page-fault exception corresponding
                        to the original access type.*/
                    raise_page_fault_comb();
                    // fault_case = 3;
                // Otherwise, the PTE is valid
                // If it is leaf PTE
                end else if (read_pte.r || read_pte.x) begin
                    /* 5. Determine if the requested memory access is allowed by the pte.r, pte.w, pte.x, and pte.u bits, 
                        given the current privilege mode and the value of the SUM and MXR fields of the mstatus register. 
                        If not, stop and raise a page-fault exception corresponding to the original access type.*/
                    // TODO (DONE?): "the value of the SUM and MXR fields of the mstatus register"?
                    if (leaf_pte_access_allowed) begin
                        raise_page_fault_comb();
                        // fault_case = 4;
                    end else if (cur_level == 1 && read_pte.ppn0 != 0) begin
                        /* 6. If i > 0 and pte.ppn[i-1 : 0] != 0, this is a misaligned superpage; 
                            stop and raise a page-fault exception corresponding to the original access type */
                        raise_page_fault_comb();
                        // fault_case = 5;
                    end else if (!paddr_valid(pte_addr[ADDR_WIDTH-1:0])) begin
                        raise_access_fault_comb();
                        // fault_case = 6;
                    end else begin
                        ack_paddr_comb({wb_dat_i[29:10], vaddr_i[11:0]});
                    end
                // If it is non-leaf PTE
                end else begin
                    /* 4. ... Otherwise, this PTE is a pointer to the next level of the page table. 
                        Let i = i - 1. If i < 0, stop and raise a page-fault exception corresponding to the original access type. 
                        Otherwise, let a = pte.ppn × PAGESIZE and go to step 2. */
                    if (cur_level == 0) begin
                        raise_page_fault_comb();
                        // fault_case = 7;
                    end else if (!paddr_valid(pte_addr[ADDR_WIDTH-1:0])) begin
                        raise_access_fault_comb();
                        // fault_case = 8;
                    end else begin
                        ack_o = 1'b0;
                    end
                end
            end
        end
        FETCH_PTE_LV0: begin
            ack_o = 1'b0;
        end
    endcase
end



always_ff @(posedge clk) begin: inner_data_and_wishbone
    if (rst) begin
        reset_state_and_wb();
    end else begin
        casez (state)
            IDLE: begin
                if (enable_i) begin
                    if (!(
                           (mem_sel_i == 4'b1111 && vaddr_i[1:0] == 2'b00)
                        || (mem_sel_i == 4'b0011 && vaddr_i[0]   == 1'b0)
                        || (mem_sel_i == 4'b0001)
                    )) begin
                        reset_state_and_wb();
                    // do not translate (i.e., direct translatation)
                    end else if (direct_trans) begin
                        reset_state_and_wb();
                    // need translation (vaddr -> paddr)
                    end else begin
                        if (!paddr_valid(pte_addr[ADDR_WIDTH-1:0])) begin
                            reset_state_and_wb();
                        end else if (tlb_hit) begin
                            reset_state_and_wb();
                        end else begin
                            // inner data
                            state     <= FETCH_PTE;
                            cur_level <= 1'b1;
                            lv1_pte   <= 'b0;
                            // wishbone interface
                            wb_cyc_o  <= 1'b1;
                        end
                    end
                end else begin
                    reset_state_and_wb();
                end 
            end
            FETCH_PTE: begin
                if (wb_ack_i) begin
                    if (!read_pte.v || (!read_pte.r && read_pte.w)) begin
                        reset_state_and_wb();
                    end else if (read_pte.r || read_pte.x) begin
                        if (leaf_pte_access_allowed) begin
                            reset_state_and_wb();
                        end else if (cur_level == 1 && read_pte.ppn0 != 0) begin
                            reset_state_and_wb();
                        end else if (!paddr_valid(pte_addr[ADDR_WIDTH-1:0])) begin
                            reset_state_and_wb();
                        end else begin
                            reset_state_and_wb();
                            // and update TLB
                        end
                    end else begin
                        if (cur_level == 0) begin
                            reset_state_and_wb();
                        end else if (!paddr_valid(pte_addr[ADDR_WIDTH-1:0])) begin
                            reset_state_and_wb();
                        end else begin
                            wb_cyc_o <= 1'b0;   // close wishbone for a cycle
                            lv1_pte <= read_pte;  // cache the just-read level-1 PTE
                            cur_level <= cur_level -1;  // cur_level <= 1'b0;
                            state <= FETCH_PTE_LV0;
                        end
                    end
                end
            end
            FETCH_PTE_LV0: begin
                wb_cyc_o <= 1'b1;
                state <= FETCH_PTE;
            end
        endcase
    end
end

always_ff @(posedge clk) begin: update_tlb
    if (rst) begin
        reset_tlb();
    end else if (ack_o && tlb_reset_i) begin
        reset_tlb();
    end else begin
        if (state == FETCH_PTE && wb_ack_i) begin
            if (!read_pte.v || (!read_pte.r && read_pte.w)) begin
            end else if (read_pte.r || read_pte.x) begin
                if (leaf_pte_access_allowed) begin
                end else if (cur_level == 1 && read_pte.ppn0 != 0) begin
                end else if (!paddr_valid(pte_addr[ADDR_WIDTH-1:0])) begin
                end else begin
                    // update TLB
                    tlb[tlb_index].tag   <= vaddr_i[31:31-TLB_TAG_WIDTH+1];
                    tlb[tlb_index].ppn   <= wb_dat_i[31:10];
                    tlb[tlb_index].asid  <= satp_i.asid;
                    tlb[tlb_index].valid <= 1'b1;
                end
            end else begin
            end
        end
    end
end

always_ff @(posedge clk) begin: output_data
    if (rst) begin
        output_bubble();
    end else if (stall_i) begin
        // do nothing
    end else if (bubble_i) begin
        output_bubble();
    end else begin
        paddr_o               <= paddr_comb;
        load_page_fault_o    <= page_fault_comb   & read_en_i;
        store_page_fault_o   <= page_fault_comb   & write_en_i;
        instr_page_fault_o   <= page_fault_comb   & exe_en_i;
        load_access_fault_o  <= access_fault_comb & read_en_i;
        store_access_fault_o <= access_fault_comb & write_en_i;
        instr_access_fault_o <= access_fault_comb & exe_en_i;
        load_misaligned_o    <= misaligned_comb   & read_en_i;
        store_misaligned_o   <= misaligned_comb   & write_en_i;
        instr_misaligned_o   <= misaligned_comb   & exe_en_i;

        if1_if2_icache_enable <= ~page_fault_comb & ~access_fault_comb;
        direct_pass_data();
    end
end



/* ================= utils ================= */
function automatic logic paddr_valid(
    logic [ADDR_WIDTH-1:0] paddr
);
    return ( ~|((paddr ^ 32'h1000_0000) & 32'hFFFF_0000) )            // UART [equivalent to (32'h1000_0000 <= paddr && paddr <= 32'h1000_FFFF) ]   
        || (paddr == `MTIMECMP_ADDR) || (paddr == `MTIMECMP_ADDR+4)   // CSR - mtimecmp
        || (paddr == `MTIME_ADDR)    || (paddr == `MTIME_ADDR+4)      // CSR - mtime
        || ( ~|((paddr ^ 32'h8000_0000) & 32'hFF80_0000) )            // codes and data [equivalent to (32'h8000_0000 <= paddr && paddr <= 32'h807F_FFFF)]
        || ( ~|((paddr ^ 32'h8300_0000) & 32'hFF00_0000) )
        || ( ~|((paddr ^ 32'h8400_0000) & 32'hFF00_0000) )
        || ( ~|((paddr ^ 32'h8500_0000) & 32'hFF00_0000) )
        || ( ~|((paddr ^ 32'h8600_0000) & 32'hFFFF_FF00) )
        || ( ~|((paddr ^ 32'h8700_0000) & 32'hFFFF_FF00) );
    // TODO: 如果增加更多外设，需要在这里补上相应的物理地址区间
    /* 
        0x10000000-0x10000007	串口数据及状态
        0x80000000-0x807FFFFF:
            0x80000000-0x800FFFFF	监控程序代码
            0x80100000-0x803FFFFF	用户程序代码
            0x80400000-0x807EFFFF	用户程序数据
            0x807F0000-0x807FFFFF	监控程序数据
     */
endfunction
    
function raise_misaligned_comb();
    ack_o             = 1'b1;
    // paddr_comb        = {ADDR_WIDTH{1'b0}};  // omitted, because it is default value
    // page_fault_comb   = 1'b0;
    // access_fault_comb = 1'b0;
    misaligned_comb   = 1'b1;
endfunction

function raise_page_fault_comb();
    ack_o             = 1'b1;
    // paddr_comb        = {ADDR_WIDTH{1'b0}};
    page_fault_comb   = 1'b1;
    // access_fault_comb = 1'b0;
    // misaligned_comb   = 1'b0;
endfunction

function raise_access_fault_comb();
    ack_o             = 1'b1;
    // paddr_comb        = {ADDR_WIDTH{1'b0}};
    // page_fault_comb   = 1'b0;
    access_fault_comb = 1'b1;
    // misaligned_comb   = 1'b0;
endfunction

function automatic ack_paddr_comb(
    logic [ADDR_WIDTH-1:0] paddr_to_ret
);
    ack_o             = 1'b1;
    paddr_comb        = paddr_to_ret;
    // page_fault_comb   = 1'b0;
    // access_fault_comb = 1'b0;
    // misaligned_comb   = 1'b0;
endfunction


task direct_pass_data();
    // IF1/IF2
    if1_if2_pc_now                  <= vaddr_i;
    // MEM1/MEM2
    mem1_mem2_pc_now                <= exe_mem1_pc_now;      // only for debug
    mem1_mem2_rf_wen                <= exe_mem1_rf_wen;
    mem1_mem2_rf_waddr              <= exe_mem1_rf_waddr;
    mem1_mem2_rf_wdata              <= exe_mem1_alu_result;
    mem1_mem2_mem_vaddr             <= exe_mem1_alu_result;
    mem1_mem2_mem_re                <= exe_mem1_mem_re;
    mem1_mem2_mem_we                <= exe_mem1_mem_we;
    mem1_mem2_mem_sel               <= exe_mem1_mem_sel;
    mem1_mem2_mem_wdata             <= exe_mem1_mem_wdata;
    mem1_mem2_load_type             <= exe_mem1_load_type;
    mem1_mem2_inst                  <= exe_mem1_inst;
    mem1_mem2_csr_op                <= exe_mem1_csr_op;
    mem1_mem2_csr_data              <= exe_mem1_csr_data;
    mem1_mem2_instr_page_fault      <= exe_mem1_instr_page_fault;
    mem1_mem2_instr_access_fault    <= exe_mem1_instr_access_fault;
    mem1_mem2_instr_misaligned      <= exe_mem1_instr_misaligned;
    mem1_mem2_illegal_instr         <= exe_mem1_illegal_instr;
    mem1_mem2_ecall                 <= exe_mem1_ecall;
    mem1_mem2_ebreak                <= exe_mem1_ebreak;
    mem1_mem2_mret                  <= exe_mem1_mret;
    mem1_mem2_sret                  <= exe_mem1_sret;
endtask

task output_bubble();
    // CPU interface
    paddr_o               <= {ADDR_WIDTH{1'b0}};
    load_page_fault_o     <= 1'b0;
    store_page_fault_o    <= 1'b0;
    instr_page_fault_o    <= 1'b0;
    load_access_fault_o   <= 1'b0;
    store_access_fault_o  <= 1'b0;
    instr_access_fault_o  <= 1'b0;
    load_misaligned_o     <= 1'b0;
    store_misaligned_o    <= 1'b0;
    instr_misaligned_o    <= 1'b0;

    if1_if2_icache_enable <= 1'b0;
    // IF1/IF2
    if1_if2_pc_now                  <= 0;
    // MEM1/MEM2
    mem1_mem2_pc_now                <= 0;  // only for debug
    mem1_mem2_rf_wen                <= 0;
    mem1_mem2_rf_waddr              <= 0;
    mem1_mem2_rf_wdata              <= 0;
    mem1_mem2_load_type             <= 0;
    mem1_mem2_mem_vaddr             <= 0;
    mem1_mem2_mem_re                <= 0;
    mem1_mem2_mem_we                <= 0;
    mem1_mem2_mem_sel               <= 0;
    mem1_mem2_mem_wdata             <= 0;
    mem1_mem2_inst                  <= 0;
    mem1_mem2_csr_op                <= 0;
    mem1_mem2_csr_data              <= 0;
    mem1_mem2_instr_page_fault      <= 0;
    mem1_mem2_instr_access_fault    <= 0;
    mem1_mem2_instr_misaligned      <= 0;
    mem1_mem2_illegal_instr         <= 0;
    mem1_mem2_ecall                 <= 0;
    mem1_mem2_ebreak                <= 0;
    mem1_mem2_mret                  <= 0;
    mem1_mem2_sret                  <= 0;
endtask

task reset_state_and_wb();
    // inner data
    state     <= IDLE;
    cur_level <= 1'b1;
    lv1_pte   <= 'b0;
    // wishbone
    wb_cyc_o  <= 1'b0;
endtask

task reset_tlb();
    for (int i = 0; i < N_TLB_ENTRY; ++i) begin
        tlb[i] <= 'b0;
    end
endtask

endmodule
