`include "header.sv"

module mmu (
    input wire                          clk,
    input wire                          rst,

    // CPU interface
    input wire [`MODE_WIDTH-1:0]        mode_i,
    input wire satp_t                   satp_i,
    input wire                          mstatus_sum_i,
    input wire                          mstatus_mxr_i,
    input wire vaddr_t                  vaddr_i,  // virtual address
    output reg [ADDR_WIDTH-1:0]         paddr_o,  // physical address
    output reg                          ack_o,    // 仅当 ack_o == 1 时，CPU interface output is valid

    input wire                          read_en_i,  // for MEM stage, load instruction
    input wire                          write_en_i, // for MEM stage, store instruction
    input wire                          exe_en_i,   // for IF stage
    output reg                          load_page_fault_o,
    output reg                          store_page_fault_o,
    output reg                          instr_page_fault_o,
    output reg                          load_access_fault_o,
    output reg                          store_access_fault_o,
    output reg                          instr_access_fault_o,

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
    output reg                          if1_if2_pc_now,

    // data direct pass (for MEM1/MEM2)
    input wire  [ADDR_WIDTH-1:0]        exe_mem1_pc_now,
    input wire                          exe_mem1_mem_en,
    input wire                          exe_mem1_rf_wen,
    input wire  [REG_ADDR_WIDTH-1:0]    exe_mem1_rf_waddr,
    input wire  [DATA_WIDTH-1:0]        exe_mem1_alu_result,
    input wire                          exe_mem1_mem_we,
    input wire  [DATA_WIDTH/8-1:0]      exe_mem1_mem_sel,
    input wire  [DATA_WIDTH-1:0]        exe_mem1_mem_wdata,
    input wire  [DATA_WIDTH-1:0]        exe_mem1_inst,
    input wire  [2:0]                   exe_mem1_csr_op,

    output reg  [ADDR_WIDTH-1:0]        mem1_mem2_pc_now,      // only for debug
    output reg                          mem1_mem2_mem_en,
    output reg                          mem1_mem2_rf_wen,
    output reg  [REG_ADDR_WIDTH-1:0]    mem1_mem2_rf_waddr,
    output reg  [DATA_WIDTH-1:0]        mem1_mem2_rf_wdata,
    output reg                          mem1_mem2_mem_we,
    output reg  [DATA_WIDTH/8-1:0]      mem1_mem2_mem_sel,
    output reg  [DATA_WIDTH-1:0]        mem1_mem2_mem_wdata,
    output reg  [DATA_WIDTH-1:0]        mem1_mem2_inst,
    output reg  [2:0]                   mem1_mem2_csr_op
);

reg page_fault;
reg access_fault;
assign load_page_fault_o    = page_fault   & read_en_i;
assign store_page_fault_o   = page_fault   & write_en_i;
assign instr_page_fault_o   = page_fault   & exe_en_i;
assign load_access_fault_o  = access_fault & read_en_i;
assign store_access_fault_o = access_fault & write_en_i;
assign instr_access_fault_o = access_fault & exe_en_i;


wire direct_trans;
assign direct_trans = (mode_i == `MODE_M || satp_i.mode == 1'b0);

pte_t read_pte;
assign read_pte = pte_t'(wb_dat_i);
// Ref: 4.3.2 Virtual Address Translation Process
reg         cur_level;
pte_t       lv1_pte;
wire [33:0] pte_addr;
assign pte_addr = (cur_level == 1'b1) 
                    ? (satp_i.ppn << 12)                   + (vaddr_i.vpn1 << 2)
                    : ({lv1_pte.ppn1, lv1_pte.ppn0} << 12) + (vaddr_i.vpn0 << 2);

// wishbone interface
assign wb_stb_o = wb_cyc_o;
assign wb_adr_o = pte_addr[ADDR_WIDTH-1:0];  // “拼出来�? 34 佝物睆地�?坯以直接去掉�?高的两佝当作 32 佝地�?进行使用。�??
assign wb_dat_o = {DATA_WIDTH{1'b0}};
assign wb_sel_o = {{DATA_WIDTH/8}{1'b0}};
assign wb_we_o  = 1'b0;

enum logic [2:0] {
    IDLE,
    FETCH_PTE,
    FETCH_PTE_LV0
} state;

// TLB
tlb_entry_t  tlb[0: N_TLB_ENTRY-1];

wire [TLB_INDEX_WIDTH-1:0]  tlb_index;
tlb_entry_t                 tlb_entry;
wire                        tlb_hit;
assign tlb_index = vaddr_i[12+TLB_INDEX_WIDTH-1: 12];
assign tlb_entry = tlb[tlb_index];
assign tlb_hit = tlb_entry.valid 
                && tlb_entry.asid == satp_i.asid
                && tlb_entry.tag == vaddr_i[31:31-TLB_TAG_WIDTH+1];


always_ff @(posedge clk) begin
    if (rst) begin
        // CPU interface
        ack_o <= 1'b0;
        paddr_o <= 'b0;
        page_fault <= 1'b0;
        access_fault <= 1'b0;
        // wishbone interface
        wb_cyc_o <= 1'b0;
        // inner data
        state <= FETCH_PTE;
        cur_level <= 1'b1;
        lv1_pte <= 'b0;
        // TLB
        reset_tlb();
    end else begin
        casez (state) 
            IDLE: begin
                if (direct_trans) begin
                    if (!paddr_valid(vaddr_i)) begin
                        raise_access_fault();
                    end else begin
                        ack_paddr(vaddr_i);
                    end
                end else begin
                    if (!paddr_valid(pte_addr[ADDR_WIDTH-1:0])) begin
                        raise_access_fault();
                    end else if (tlb_hit) begin
                        ack_paddr_in_tlb();
                    end else begin
                        // CPU interface
                        ack_o <= 1'b0;
                        // wishbone interface
                        wb_cyc_o <= 1'b1;
                        // inner data
                        state <= FETCH_PTE;
                        cur_level <= 1'b1;
                    end
                end
            end
            FETCH_PTE: begin
                if (wb_ack_i) begin
                    // If PTE is invalid, raise page fault
                    if (!read_pte.v || (!read_pte.r && read_pte.w)) begin
                        /* 3. If pte.v = 0, or if pte.r = 0 and pte.w = 1, or if any bits or encodings that are reserved for
                            future standard use are set within pte, stop and raise a page-fault exception corresponding
                            to the original access type.*/
                        raise_page_fault();
                    // Otherwise, the PTE is valid
                    // If it is leaf PTE
                    end else if (read_pte.r || read_pte.x) begin
                        /* 5. Determine if the requested memory access is allowed by the pte.r, pte.w, pte.x, and pte.u bits, 
                            given the current privilege mode and the value of the SUM and MXR fields of the mstatus register. 
                            If not, stop and raise a page-fault exception corresponding to the original access type.*/
                        // TODO (DONE?): "the value of the SUM and MXR fields of the mstatus register"?
                        if (   (!mstatus_mxr_i && read_en_i && !read_pte.r)
                            || (mstatus_mxr_i  && read_en_i && !(read_pte.r || read_pte.x))
                            /* (Ref: page 23) When MXR=0, only loads from pages marked readable (R=1 in Figure 4.18) will succeed.
                                When MXR=1, loads from pages marked either readable or executable (R=1 or X=1) will succeed. */
                            || (write_en_i        && !read_pte.w)
                            || (exe_en_i          && !read_pte.x)
                            || (mode_i == `MODE_U && !read_pte.u)
                            || (mode_i == `MODE_S && read_pre.u && !mstatus_sum_i)
                            /* (Ref: page 23) When SUM=0, S-mode memory accesses to pages that are accessible by U-mode (U=1 in Figure 4.18) will fault. */
                            ) begin
                            raise_page_fault();
                        end else if (cur_level == 1 && read_pte.ppn0 != 0) begin
                            /* 6. If i > 0 and pte.ppn[i �? 1 : 0] != 0, this is a misaligned superpage; 
                                stop and raise a page-fault exception corresponding to the original access type */
                            raise_page_fault();
                        end else if (!paddr_valid(pte_addr[ADDR_WIDTH-1:0])) begin
                            raise_access_fault();
                        end else begin
                            // update TLB
                            tlb[tlb_index].tag   <= vaddr_i[31:31-TLB_TAG_WIDTH+1];
                            tlb[tlb_index].ppn   <= wb_dat_i[31:10];
                            tlb[tlb_index].asid  <= satp_i.asid;
                            tlb[tlb_index].valid <= 1'b1;
                            // ack physical address
                            ack_paddr({wb_dat_i[29:10], vaddr_i[11:0]});
                        end
                    // If it is non-leaf PTE
                    end else begin
                        /* 4. ... Otherwise, this PTE is a pointer to the next level of the page table. 
                            Let i = i �? 1. If i < 0, stop and raise a page-fault exception corresponding to the original access type. 
                            Otherwise, let a = pte.ppn × PAGESIZE and go to step 2. */
                        if (cur_level == 0) begin
                            raise_page_fault();
                        end else if (!paddr_valid(pte_addr[ADDR_WIDTH-1:0])) begin
                            raise_access_fault();
                        end else begin
                            wb_cyc_o <= 1'b0;   // close wishbone for a cycle
                            lv1_pte <= pte_t'(wb_dat_i);  // cache the just-read level-1 PTE
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


/* ================= utils ================= */
function automatic logic paddr_valid(
    logic [ADDR_WIDTH-1:0] paddr
);
    return ( ~|((paddr ^ 32'h1000_0000) & 32'hFFFF_0000) )            // UART [equivalent to (32'h1000_0000 <= paddr && paddr <= 32'h1000_FFFF) ]   
        || (paddr == `MTIMECMP_ADDR) || (paddr == `MTIMECMP_ADDR+4)   // CSR - mtimecmp
        || (paddr == `MTIME_ADDR)    || (paddr == `MTIME_ADDR+4)      // CSR - mtime
        || ( ~|((paddr ^ 32'h8000_0000) & 32'hFF80_0000) );           // codes and data [equivalent to (32'h8000_0000 <= paddr && paddr <= 32'h807F_FFFF)]
    // TODO: 如果增加更多外设，需覝在这里补上相应的物睆地�?区间
    /* 
        0x10000000-0x10000007	串坣数杮坊状�?
        0x80000000-0x807FFFFF:
            0x80000000-0x800FFFFF	监控程庝代砝
            0x80100000-0x803FFFFF	用户程庝代砝
            0x80400000-0x807EFFFF	用户程庝数杮
            0x807F0000-0x807FFFFF	监控程庝数杮
     */
endfunction

task raise_page_fault();
    // CPU interface
    ack_o <= 1'b1;
    paddr_o <= {ADDR_WIDTH{1'b0}};
    page_fault <= 1'b1;
    access_fault <= 1'b0;
    // wishbone interface
    wb_cyc_o <= 1'b0;
    // inner data
    state <= IDLE;    // TODO: to 'DONE'?
    cur_level <= 1'b1;
    output_other_data();
endtask

task raise_access_fault();
    // CPU interface
    ack_o <= 1'b1;
    paddr_o <= {ADDR_WIDTH{1'b0}};
    page_fault <= 1'b0;
    access_fault <= 1'b1;
    // wishbone interface
    wb_cyc_o <= 1'b0;
    // inner data
    state <= IDLE;    // TODO: to 'DONE'?
    cur_level <= 1'b1;
    output_other_data();
endtask

task automatic ack_paddr(
    logic [ADDR_WIDTH-1:0] paddr_to_ret
);
    // CPU interface
    ack_o <= 1'b1;
    paddr_o <= paddr_to_ret;
    page_fault <= 1'b0;
    access_fault <= 1'b0;
    // wishbone interface
    wb_cyc_o <= 1'b0;
    // inner data
    state <= IDLE;
    cur_level <= 1'b1;
    output_other_data();
endtask

task ack_paddr_in_tlb();
    // CPU interface
    ack_o <= 1'b1;
    paddr_o <= {tlb_entry.ppn[19:0], vaddr_i[11:0]};
    page_fault <= 1'b0;
    access_fault <= 1'b0;
    // wishbone interface
    wb_cyc_o <= 1'b0;
    // inner data
    state <= IDLE;
    cur_level <= 1'b1;
    output_other_data();
endtask

task output_other_data();
    // IF1/IF2
    if1_if2_pc_now        <= vaddr_i;
    // MEM1/MEM2
    mem1_mem2_pc_now      <= exe_mem1_pc_now;      // only for debug
    mem1_mem2_mem_en      <= exe_mem1_mem_en;
    mem1_mem2_rf_wen      <= exe_mem1_rf_wen;
    mem1_mem2_rf_waddr    <= exe_mem1_rf_waddr;
    mem1_mem2_rf_wdata    <= exe_mem1_alu_result;  // only for debug
    mem1_mem2_mem_we      <= exe_mem1_mem_we;
    mem1_mem2_mem_sel     <= exe_mem1_mem_sel;
    mem1_mem2_mem_wdata   <= exe_mem1_mem_wdata;
    mem1_mem2_inst        <= exe_mem1_inst;
    mem1_mem2_csr_op      <= exe_mem1_csr_op;

endtask

// function automatic logic[33:0] calc_pte_addr(pte_t prev_pte = 'b0);
//     return (cur_level == 1'b1) 
//                 ? (satp_i.ppn << 12)                     + (vaddr_i.vpn1 << 2)
//                 : ({prev_pte.ppn1, prev_pte.ppn0} << 12) + (vaddr_i.vpn0 << 2);
// endfunction

task reset_tlb();
    for (int i = 0; i < N_TLB_ENTRY; ++i) begin
        tlb[i] <= 'b0;
    end
endtask

endmodule
