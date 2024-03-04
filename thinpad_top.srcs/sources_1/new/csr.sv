`include "header.sv"

module csrfile (
    input wire                      clk,
    input wire                      rst,

    input wire [CSR_ADDR_WIDTH-1:0] raddr_i,
    output reg [DATA_WIDTH-1:0]     rdata_o,
    input wire [CSR_ADDR_WIDTH-1:0] waddr_i,
    input wire [DATA_WIDTH-1:0]     wdata_i,
    input wire we_i,
    input wire [31:0] pc_now_i,
    output reg [31:0] pc_next_o,
    input wire [63:0] mtime_i,
    output reg branch_o,
    input wire ecall_i,
    input wire ebreak_i,
    input wire mret_i,
    input wire sret_i,
    input wire [31:0] tval_i,
    input wire time_interrupt_i,
    input wire if_misaligned_i,
    input wire if_access_fault_i,
    input wire if_illegal_i,
    input wire load_misaligned_i,
    input wire load_access_fault_i,
    input wire store_misaligned_i,
    input wire store_access_fault_i,
    input wire if_page_fault_i,
    input wire load_page_fault_i,
    input wire store_page_fault_i,

    input wire stall_i,
    
    output satp_t satp_o,
    output reg sum_o,
    output reg [1:0] mode_o
);

mtvec_t mtvec;
mscratch_t mscratch;
mepc_t mepc;
mcause_t mcause;
mstatus_t mstatus;
mie_t mie;
mip_t mip;
mhartid_t mhartid;
mideleg_t mideleg;
medeleg_t medeleg;
mtval_t mtval;
// sstatus_t sstatus;
sepc_t sepc;
scause_t scause;
stval_t stval;
stvec_t stvec;
sscratch_t sscratch;
// sip_t sip;
// sie_t sie;
satp_t satp;
logic [1:0] mode;

assign satp_o = satp;
assign mode_o = mode;
assign sum_o = mstatus.sum;

logic [30:0] exception_code;
logic [2:0] handle_type;
logic handle_mode;

always_comb begin
    if ((mstatus.mie || mode < `MODE_M) && mip.mtip && mie.mtie) begin
        exception_code = 31'd7;
        handle_type = 3'd2;
    end else if ((mstatus.sie && mode == `MODE_S || mode == `MODE_U) && mip.stip && mie.stie) begin
        exception_code = 31'd5;
        handle_type = 3'd2;
    end else if (ebreak_i) begin
        exception_code = 31'd3;
        handle_type = 3'd1;
    end else if (if_page_fault_i) begin
        exception_code = 31'd12;
        handle_type = 3'd1;
    end else if (if_access_fault_i) begin
        exception_code = 31'd1;
        handle_type = 3'd1;
    end else if (if_misaligned_i) begin
        exception_code = 31'd0;
        handle_type = 3'd1;
    end else if (if_illegal_i) begin
        exception_code = 31'd2;
        handle_type = 3'd1;
    end else if (ecall_i) begin
        if (mode == `MODE_M) begin
            exception_code = 31'd11;
        end else if (mode == `MODE_S) begin
            exception_code = 31'd9;
        end else begin
            exception_code = 31'd8;
        end
        handle_type = 3'd1;
    end else if (store_misaligned_i) begin
        exception_code = 31'd6;
        handle_type = 3'd1;
    end else if (load_misaligned_i) begin
        exception_code = 31'd4;
        handle_type = 3'd1;
    end else if (store_page_fault_i) begin
        exception_code = 31'd15;
        handle_type = 3'd1;
    end else if (load_page_fault_i) begin
        exception_code = 31'd13;
        handle_type = 3'd1;
    end else if (store_access_fault_i) begin
        exception_code = 31'd7;
        handle_type = 3'd1;
    end else if (load_access_fault_i) begin
        exception_code = 31'd5;
        handle_type = 3'd1;
    end else begin
        exception_code = 31'd0;
        handle_type = 3'd0;
    end
end

always_comb begin
    if (handle_type == 3'd2) begin
        if ((mstatus.mie || mode < `MODE_M) && mip.mtip && mie.mtie) begin
            handle_mode = mideleg[exception_code[4:0]];     // 1: S, 0: M
        end else begin
            handle_mode = 1'b1;
        end
    end else if (handle_type == 3'd1) begin
        if (mode == `MODE_M) begin
            handle_mode = 1'b0;
        end else begin 
            handle_mode = medeleg[exception_code[4:0]];
        end
    end else begin
        handle_mode = 1'b0;
    end
end

always_comb begin
    if (mode == `MODE_M) begin
        case(raddr_i)
            12'h305: rdata_o = mtvec;
            12'h340: rdata_o = mscratch;
            12'h341: rdata_o = mepc;
            12'h342: rdata_o = mcause;
            12'h300: rdata_o = mstatus & 32'b0000_0000_0000_0100_0001_1001_1010_1010;
            12'h304: rdata_o = mie & 32'b0000_0000_0000_0000_0000_0000_1010_0000;
            12'h344: rdata_o = mip & 32'b0000_0000_0000_0000_0000_0000_1010_0000;
            12'hf14: rdata_o = mhartid;
            12'h303: rdata_o = mideleg;
            12'h302: rdata_o = medeleg;
            12'h343: rdata_o = mtval;
            12'h100: rdata_o = mstatus & 32'b0000_0000_0000_0100_0000_0001_0010_0010;
            12'h141: rdata_o = sepc;
            12'h142: rdata_o = scause;
            12'h143: rdata_o = stval;
            12'h105: rdata_o = stvec;
            12'h140: rdata_o = sscratch;
            12'h144: rdata_o = mip & 32'b0000_0000_0000_0000_0000_0000_0010_0000;
            12'h104: rdata_o = mie & 32'b0000_0000_0000_0000_0000_0000_0010_0000;
            12'h180: rdata_o = satp;
            12'hc01: rdata_o = mtime_i[31:0];
            12'hc81: rdata_o = mtime_i[63:32];
            default: rdata_o = 32'h0;
        endcase
    end else if (mode == `MODE_S) begin
        case(raddr_i)
            12'h100: rdata_o = mstatus & 32'b0000_0000_0000_0100_0000_0001_0010_0010;
            12'h141: rdata_o = sepc;
            12'h142: rdata_o = scause;
            12'h143: rdata_o = stval;
            12'h105: rdata_o = stvec;
            12'h140: rdata_o = sscratch;
            12'h144: rdata_o = mip & 32'b0000_0000_0000_0000_0000_0000_0010_0000;
            12'h104: rdata_o = mie & 32'b0000_0000_0000_0000_0000_0000_0010_0000;
            12'h180: rdata_o = satp;
            12'hc01: rdata_o = mtime_i[31:0];
            12'hc81: rdata_o = mtime_i[63:32];
            default: rdata_o = 32'h0;
        endcase
    end else begin
        case(raddr_i)
            12'hc01: rdata_o = mtime_i[31:0];
            12'hc81: rdata_o = mtime_i[63:32];
            default: rdata_o = 32'h0;
        endcase
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        mtvec <= 32'h0;
        mscratch <= 32'h0;
        mepc <= 32'h0;
        mcause <= 32'h0;
        mstatus <= 32'h0;
        mie <= 32'h0;
        mip <= 32'h0;
        mhartid <= 32'h0;
        mideleg <= 32'h0;
        medeleg <= 32'h0;
        mtval <= 32'h0;
        sepc <= 32'h0;
        scause <= 32'h0;
        stval <= 32'h0;
        stvec <= 32'h0;
        sscratch <= 32'h0;
        satp <= 32'h0;
        mode <= `MODE_M;
    end else if (stall_i) begin
    end else begin
        mip.mtip <= time_interrupt_i;
        if (mret_i) begin
            mode <= mstatus.mpp;
            mstatus.mpp <= 2'b0;
            mstatus.mpie <= 1'b1; 
            mstatus.mie <= mstatus.mpie;
        end else if (sret_i) begin
            mode <= {1'b0, mstatus.spp};
            mstatus.spp <= 1'b0;
            mstatus.spie <= 1'b1; 
            mstatus.sie <= mstatus.spie;
        end else if (handle_type && pc_now_i != 32'b0) begin
            if (handle_mode) begin
                mode <= `MODE_S;
                sepc <= pc_now_i;
                if (handle_type == 3'd2) begin
                    scause.interrupt <= 1'b1;
                end else begin
                    scause.interrupt <= 1'b0;
                end
                scause.exception <= exception_code;
                mstatus.spp <= mode;
                mstatus.spie <= mstatus.sie; 
                mstatus.sie <= 0;
                stval <= tval_i;
            end else begin
                mode <= `MODE_M;
                mepc <= pc_now_i;
                if (handle_type == 3'd2) begin
                    mcause.interrupt <= 1'b1;
                end else begin
                    mcause.interrupt <= 1'b0;
                end
                mcause.exception <= exception_code;
                mstatus.mpp <= mode;
                mstatus.mpie <= mstatus.mie; 
                mstatus.mie <= 0;
                mtval <= tval_i;
            end
        end else begin
            if (we_i) begin
                if (mode == `MODE_M) begin
                    case(waddr_i)
                        12'h305: mtvec <= wdata_i;      //
                        12'h340: mscratch <= wdata_i;
                        12'h341: mepc <= {wdata_i[31:2], 2'b0};
                        12'h342: mcause <= wdata_i;
                        12'h300: begin
                            mstatus.mpp <= wdata_i[12:11];
                            mstatus.mpie <= wdata_i[7];
                            mstatus.mie <= wdata_i[3];
                            mstatus.sum <= wdata_i[18];
                            mstatus.spp <= wdata_i[8];
                            mstatus.spie <= wdata_i[5];
                            mstatus.sie <= wdata_i[1];
                        end
                        12'h304: begin
                            mie.mtie <= wdata_i[7];
                            mie.stie <= wdata_i[5];
                        end
                        12'h344: begin
                            mip.stip <= wdata_i[5];
                        end
                        12'hf14: mhartid <= wdata_i;
                        12'h303: mideleg <= wdata_i;
                        12'h302: medeleg <= wdata_i;
                        12'h343: mtval <= wdata_i;
                        12'h100: begin
                            mstatus.sum <= wdata_i[18];
                            mstatus.spp <= wdata_i[8];
                            mstatus.spie <= wdata_i[5];
                            mstatus.sie <= wdata_i[1];
                        end
                        12'h141: sepc <= {wdata_i[31:2], 2'b0};
                        12'h142: scause <= wdata_i;
                        12'h143: stval <= wdata_i;
                        12'h105: stvec <= wdata_i;      //
                        12'h140: sscratch <= wdata_i;
                        12'h144: begin
                            mip.stip <= wdata_i[5];
                        end
                        12'h104: begin
                            mie.stie <= wdata_i[5];
                        end
                        12'h180: satp <= wdata_i;
                    endcase
                end else if (mode == `MODE_S) begin
                    case(waddr_i)
                        12'h100: begin
                            mstatus.sum <= wdata_i[18];
                            mstatus.spp <= wdata_i[8];
                            mstatus.spie <= wdata_i[5];
                            mstatus.sie <= wdata_i[1];
                        end
                        12'h141: sepc <= {wdata_i[31:2], 2'b0};
                        12'h142: scause <= wdata_i;
                        12'h143: stval <= wdata_i;
                        12'h105: stvec <= wdata_i;      //
                        12'h140: sscratch <= wdata_i;
                        12'h144: begin
                            mip.stip <= wdata_i[5];
                        end
                        12'h104: begin
                            mie.stie <= wdata_i[5];
                        end
                        12'h180: satp <= wdata_i;
                    endcase
                end
            end
        end
    end
end

always_comb begin
    branch_o = 1'b1;
    if (mret_i)
        pc_next_o = mepc;
    else if (sret_i)
        pc_next_o = sepc;
    else if (handle_type && pc_now_i != 32'b0) begin
        if (handle_mode)
            pc_next_o = stvec.mode == 2'b0 ? {stvec.base, 2'b0} : {stvec.base, 2'b0} + (exception_code << 2);
        else
            pc_next_o = mtvec.mode == 2'b0 ? {mtvec.base, 2'b0} : {mtvec.base, 2'b0} + (exception_code << 2);
    end else begin
        pc_next_o = 32'h0;
        branch_o = 1'b0;
    end
end

endmodule   