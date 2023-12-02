`ifndef __PARAM_H_
`define __PARAM_H_


localparam DATA_WIDTH = 32;
localparam ADDR_WIDTH = 32;

`define TYPE_R 3'd1
`define TYPE_I 3'd2
`define TYPE_S 3'd3
`define TYPE_B 3'd4
`define TYPE_U 3'd5
`define TYPE_J 3'd6

`define ALU_ADD    4'd1
`define ALU_SUB    4'd2
`define ALU_AND    4'd3
`define ALU_OR     4'd4
`define ALU_XOR    4'd5
`define ALU_NEG    4'd6
`define ALU_SLL    4'd7
`define ALU_SRL    4'd8
`define ALU_SRA    4'd9
`define ALU_ROL    4'd10
`define ALU_MIN    4'd11
`define ALU_SBCLR  4'd12
`define ALU_CTZ    4'd13

`define MODE_WIDTH  2
`define MODE_M      `MODE_WIDTH'b11
`define MODE_S      `MODE_WIDTH'b01
`define MODE_U      `MODE_WIDTH'b00

`define MTIME_ADDR    32'h200bff8
`define MTIMECMP_ADDR 32'h2004000

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
  logic [18:0] wpri_1;
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

typedef logic [63:0] mtime_t;
typedef logic [63:0] mtimecmp_t;

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
  logic [9:0]  ppn2;
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
} pte_t;  // PTE (Page Table Entry), 32 bits

typedef struct packed {
  logic [9:0]  vpn1;
  logic [9:0]  vpn0;
  logic [11:0] offset;
} vaddr_t;  // Figure 4.13: Sv32 virtual address

typedef struct packed {
  logic [11:0] ppn1;
  logic [9:0]  ppn0;
  logic [11:0] offset;
} paddr_t;  // Figure 4.14: Sv32 physical address

`endif
