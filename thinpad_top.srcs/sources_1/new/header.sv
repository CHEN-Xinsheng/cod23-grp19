`ifndef __PARAM_H_
`define __PARAM_H_


localparam DATA_WIDTH = 32;
localparam ADDR_WIDTH = 32;
localparam BRAM_DATA_WIDTH = 8;
localparam BRAM_ADDR_WIDTH = 17;
localparam FLASH_DATA_WIDTH = 8;
localparam FLASH_ADDR_WIDTH = 23;
localparam DATA_WIDTH     = 32;
localparam ADDR_WIDTH     = 32;
localparam REG_ADDR_WIDTH = 5;
localparam CSR_ADDR_WIDTH = 12;

`define INSTR_TYPE_WIDTH  3
`define TYPE_R            `INSTR_TYPE_WIDTH'd1
`define TYPE_I            `INSTR_TYPE_WIDTH'd2
`define TYPE_S            `INSTR_TYPE_WIDTH'd3
`define TYPE_B            `INSTR_TYPE_WIDTH'd4
`define TYPE_U            `INSTR_TYPE_WIDTH'd5
`define TYPE_J            `INSTR_TYPE_WIDTH'd6

`define ALU_OP_WIDTH      4
`define ALU_ADD           `ALU_OP_WIDTH'd1
`define ALU_SUB           `ALU_OP_WIDTH'd2
`define ALU_AND           `ALU_OP_WIDTH'd3
`define ALU_OR            `ALU_OP_WIDTH'd4
`define ALU_XOR           `ALU_OP_WIDTH'd5
`define ALU_NEG           `ALU_OP_WIDTH'd6
`define ALU_SLL           `ALU_OP_WIDTH'd7
`define ALU_SRL           `ALU_OP_WIDTH'd8
`define ALU_SRA           `ALU_OP_WIDTH'd9
`define ALU_ROL           `ALU_OP_WIDTH'd10
`define ALU_MIN           `ALU_OP_WIDTH'd11
`define ALU_SBCLR         `ALU_OP_WIDTH'd12
`define ALU_CTZ           `ALU_OP_WIDTH'd13

`define MODE_WIDTH  2
`define MODE_M      `MODE_WIDTH'b11
`define MODE_S      `MODE_WIDTH'b01
`define MODE_U      `MODE_WIDTH'b00

`define MTIME_ADDR    32'h200bff8
`define MTIMECMP_ADDR 32'h2004000

`define CSR_OP_WIDTH  3

typedef struct packed {
  logic [29:0] base;
  logic [1:0] mode; 
} mtvec_t;

typedef logic [31:0] mscratch_t;

typedef logic [31:0] mepc_t;

typedef struct packed {
  logic        interrupt;
  logic [30:0] exception;
} mcause_t;

typedef struct packed {
  logic [12:0] wpri_0;
  logic       sum;
  logic [4:0] wpri_1;
  logic [1:0] mpp;
  logic [1:0] wpri_2;
  logic       spp;
  logic       mpie;
  logic       wpri_3;
  logic       spie;
  logic       upie;
  logic       mie;
  logic       wpri_4;
  logic       sie;
  logic       uie;
} mstatus_t;

typedef struct packed {
  logic [19:0] wpri_1;
  logic        meip;
  logic        wpri_2;
  logic        seip;
  logic        ueip;
  logic        mtip;
  logic        wpri_3;
  logic        stip;
  logic        utip;
  logic        msip;
  logic        wpri_4;
  logic        ssip;
  logic        usip;
} mip_t;

typedef struct packed {
  logic [19:0] wpri_1;
  logic        meie;
  logic        wpri_2;
  logic        seie;
  logic        ueie;
  logic        mtie;
  logic        wpri_3;
  logic        stie;
  logic        utie;
  logic        msie;
  logic        wpri_4;
  logic        ssie;
  logic        usie;
} mie_t;

typedef logic [31:0] mhartid_t;

typedef logic [31:0] mideleg_t;

typedef logic [31:0] medeleg_t;

typedef logic [31:0] mtval_t;

typedef logic [63:0] mtime_t;
typedef logic [63:0] mtimecmp_t;

typedef struct packed {
  logic [12:0] wpri_1;
  logic       sum;
  logic [8:0] wpri_2;
  logic       spp;
  logic [1:0] wpri_3;
  logic       spie;
  logic [2:0] wpri_4;
  logic       sie;
  logic       wpri_5;
} sstatus_t;

typedef logic [31:0] sepc_t;

typedef struct packed {
  logic        interrupt;
  logic [30:0] exception;
} scause_t;

typedef logic [31:0] stval_t;

typedef struct packed {
  logic [29:0] base;
  logic [1:0] mode; 
} stvec_t;

typedef logic [31:0] sscratch_t;

typedef struct packed {
  logic [21:0] wpri_1;
  logic        seip;
  logic        ueip;
  logic [ 1:0] wpri_2;
  logic        stip;
  logic        utip;
  logic [ 1:0] wpri_3;
  logic        ssip;
  logic        usip;
} sip_t;

typedef struct packed {
  logic [21:0] wpri_1;
  logic        seie;
  logic        ueie;
  logic [ 1:0] wpri_2;
  logic        stie;
  logic        utie;
  logic [ 1:0] wpri_3;
  logic        ssie;
  logic        usie;
} sie_t;

// Ref: RISC-V Privileged Architectures V20211203, 4.1.12, 4.3
typedef struct packed {
  logic        mode;
  /* 
   * Value  Name    Description
   * 0      Bare    No translation or protection. To select MODE=Bare, software must write zero to the remaining fields of satp (bits 30–0 when SXLEN=32) 
   * 1      Sv32    Page-based 32-bit virtual addressing 
   */
  logic [8:0]  asid;
  /* 
   * MODE=Bare and ASID[8:7]=3, whereas the encodings corresponding to MODE=Bare and ASID[8:7]̸=3 are reserved for future standard use.
   */
  logic [21:0] ppn;  // page number (PPN) of the root page table
} satp_t;  // satp (Supervisor Address Translation and Protection Register) 

typedef struct packed {
  logic [11:0] ppn1;
  logic [9:0]  ppn0;
  logic [1:0]  rsw;  // [not implemented] RSW 是保留的，用于操作系统软件。
  logic        d;    // [not implemented] Dirty 位指示了虚拟页最近是否被写过。
  logic        a;    // [not implemented] Access 位指示了该页最近是否被读、写、取
  logic        g;    // [not implemented] Global 指示了全局映射，存在于所有的地址空间中
  logic        u;    // User 位指示了该页是否可以被用户模式访问。 U-mode software may only access the page when U=1.
  logic        x;    // Readable，Writeable，eXecutable 指示了该页是否可读、可写、可运行，当这三位都是 0 时，表明该 PTE 指向了下一层页表，其为非叶 PTE ，否则就是叶 PTE。
  logic        w;    // Writable pages must also be marked readable
  logic        r;
  logic        v;    //  The V bit indicates whether the PTE is valid; if it is 0, all other bits in the PTE are don’t-cares and may be used freely by software.
  // 对于非叶 PTE，D，A，U 位被保留，并被清零。
} pte_t;
/* PTE (Page Table Entry), 32 bits
  |31    20|19    10|9   8|7                             0|
  | PPN[1] | PPN[0] | RSW | D | A | G | U | X | W | R | V |
  |   12   |   10   |  2  | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
 */

typedef struct packed {
  logic [9:0]  vpn1;
  logic [9:0]  vpn0;
  logic [11:0] offset;
} vaddr_t;  // Figure 4.13: Sv32 virtual address, 32 bits

typedef struct packed {
  logic [11:0] ppn1;
  logic [9:0]  ppn0;
  logic [11:0] offset;
} paddr_t; 
/* Figure 4.14: Sv32 physical address, 34 bits
  |33        22|21      12|11         0|
  |   PPN[1]   |  PPN[0]  |   offset   |
  |     12     |    10    |     12     |
 */

localparam N_TLB_ENTRY     = 32;
localparam TLB_INDEX_WIDTH = 5;
localparam TLB_TAG_WIDTH   = 32-12-TLB_INDEX_WIDTH;
/* virtual address:
  |    VPN (virtual page number)    | offset |
  |        TLB tag      | TLB index |        |
  |31                 17|16       12|11     0|
  |         15          |     5     |   12   |
*/
typedef struct packed {
  logic [TLB_TAG_WIDTH-1:0] tag;
  logic              [21:0] ppn;
  logic              [ 8:0] asid;
  logic                     valid;
} tlb_entry_t;  // 37 bits (TLB_TAG_WIDTH + 22 + 9 + 1)

`endif
