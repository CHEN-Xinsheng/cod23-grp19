`include "header.sv"

module mmu (
    input wire                      clk,
    input wire                      rst,

    // CPU interface
    input wire [`MODE_WIDTH-1:0]    mode_i,
    input wire satp_t               satp_i,
    input wire vaddr_t              vaddr_i,  // virtual address
    output reg [ADDR_WIDTH-1:0]     paddr_o,  // physical address
    output reg                      ack_o,    // 仅当 ack_o == 1 时，CPU interface 的输出有效
    
    input wire                      read_en_i,  // for MEM stage, load instruction
    input wire                      write_en_i, // for MEM stage, store instruction
    input wire                      exe_en_i,   // for IF stage
    output reg                      page_fault_o,
    output reg                      access_fault_o,

    // wishbone interface
    output reg                      wb_cyc_o,
    output reg                      wb_stb_o,
    input wire                      wb_ack_i,
    output reg [ADDR_WIDTH-1:0]     wb_adr_o,
    output reg [DATA_WIDTH-1:0]     wb_dat_o,
    input wire [DATA_WIDTH-1:0]     wb_dat_i,
    output reg [DATA_WIDTH/8-1:0]   wb_sel_o,
    output reg                      wb_we_o 
);


wire direct_trans;
assign direct_trans = (mode_i == `MODE_M || satp_i.mode == 1'b0);

// paddr(output)
paddr_t paddr;
assign paddr_o = paddr[ADDR_WIDTH-1:0];  // “拼出来的 34 位物理地址可以直接去掉最高的两位当作 32 位地址进行使用。”

// wishbone interface
assign wb_stb_o = wb_cyc_o;
assign wb_adr_o = pte_addr[ADDR_WIDTH-1:0];  // “拼出来的 34 位物理地址可以直接去掉最高的两位当作 32 位地址进行使用。”
assign wb_dat_o = {DATA_WIDTH{1'b0}};
assign wb_sel_o = {{DATA_WIDTH/8}{1'b0}};
assign wb_we_o  = 1'b0;

// Ref: 4.3.2 Virtual Address Translation Process
reg         cur_level;
pte_t       lv1_pte;
wire [33:0] pte_addr;
assign pte_addr = (cur_level == 1'b1) 
                    ? (satp_i.ppn << 12)                   + (vaddr_i.vpn1 << 2)
                    : ({lv1_pte.ppn1, lv1_pte.ppn0} << 12) + (vaddr_i.vpn0 << 2);

enum logic [2:0] {
    IDLE,
    FETCH_PTE,
    FETCH_PTE_LV0
} state;

always_ff @(posedge clk) begin
    if (rst) begin
        // CPU interface
        ack_o <= 1'b0;
        paddr <= 'b0;
        page_fault_o <= 1'b0;
        access_fault_o <= 1'b0;
        // wishbone interface
        wb_cyc_o <= 1'b0;
        // inner data
        state <= FETCH_PTE;
        cur_level <= 1'b1;
        lv1_pte <= 'b0;
    end else begin
        casez (state) 
            IDLE: begin
                if (direct_trans) begin
                    if (!paddr_valid({2'b0, vaddr_i})) begin
                        raise_access_fault();
                    end else begin
                        ack_paddr({2'b0, vaddr_i});
                    end
                end else begin
                    if (!paddr_valid(pte_addr)) begin
                        raise_access_fault();
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
                        // TODO: "the value of the SUM and MXR fields of the mstatus register"?
                        if (   (read_en_i         && !read_pte.r)
                            || (write_en_i        && !read_pte.w)
                            || (exe_en_i          && !read_pte.x)
                            || (mode_i == `MODE_U && !read_pte.u)
                            ) begin
                            raise_page_fault();
                        end else if (cur_level == 1 && read_pte.ppn0 != 0) begin
                            /* 6. If i > 0 and pte.ppn[i − 1 : 0] ̸= 0, this is a misaligned superpage; 
                                stop and raise a page-fault exception corresponding to the original access type */
                            raise_page_fault();
                        end else if (!paddr_valid(pte_addr)) begin
                            raise_access_fault();
                        end else begin
                            // TODO update TLB
                            ack_paddr({2'b0, wb_dat_i});
                        end
                    // If it is non-leaf PTE
                    end else begin
                        /* 4. ... Otherwise, this PTE is a pointer to the next level of the page table. 
                            Let i = i − 1. If i < 0, stop and raise a page-fault exception corresponding to the original access type. 
                            Otherwise, let a = pte.ppn × PAGESIZE and go to step 2. */
                        if (cur_level == 0) begin
                            raise_page_fault();
                        end else if (!paddr_valid(pte_addr)) begin
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
function automatic logic paddr_valid(logic [34-1:0] paddr_i);
    logic [31:0] paddr = paddr_i[31:0];
    return ( ~|((paddr ^ 32'h1000_0000) & 32'hFFFF_0000) )            // UART [equivalent to (32'h1000_0000 <= paddr && paddr <= 32'h1000_FFFF) ]   
        || (paddr == `MTIMECMP_ADDR) || (paddr == `MTIMECMP_ADDR+4)   // CSR - mtimecmp
        || (paddr == `MTIME_ADDR)    || (paddr == `MTIME_ADDR+4)      // CSR - mtime
        || ( ~|((paddr ^ 32'h8000_0000) & 32'hFF80_0000) );           // codes and data [equivalent to (32'h8000_0000 <= paddr && paddr <= 32'h807F_FFFF)]
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

task raise_page_fault();
    // CPU interface
    ack_o <= 1'b1;
    paddr <= 'b0;
    page_fault_o <= 1'b1;
    access_fault_o <= 1'b0;
    // wishbone interface
    wb_cyc_o <= 1'b0;
    wb_adr_o <= 'b0;
    // inner data
    state <= IDLE;    // TODO: to 'DONE'?
    cur_level <= 1'b1;
endtask

task raise_access_fault();
    // CPU interface
    ack_o <= 1'b1;
    paddr <= 'b0;
    page_fault_o <= 1'b0;
    access_fault_o <= 1'b1;
    // wishbone interface
    wb_cyc_o <= 1'b0;
    wb_adr_o <= 'b0;
    // inner data
    state <= IDLE;    // TODO: to 'DONE'?
    cur_level <= 1'b1;
endtask

task automatic ack_paddr(logic [33:0] paddr_to_ret);
    // CPU interface
    ack_o <= 1'b1;
    paddr <= paddr_to_ret;
    page_fault_o <= 1'b0;
    access_fault_o <= 1'b0;
    // wishbone interface
    wb_cyc_o <= 1'b0;
    wb_adr_o <= 'b0;
    // inner data
    state <= IDLE;
    cur_level <= 1'b1;
endtask

// function automatic logic[33:0] calc_pte_addr(pte_t prev_pte = 'b0);
//     return (cur_level == 1'b1) 
//                 ? (satp_i.ppn << 12)                     + (vaddr_i.vpn1 << 2)
//                 : ({prev_pte.ppn1, prev_pte.ppn0} << 12) + (vaddr_i.vpn0 << 2);
// endfunction

endmodule