`ifndef __CSR_H__
`define __CSR_H__

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

`endif