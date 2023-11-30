`include "csr.svh"

module csrfile (
    input wire clk,
    input wire rst,
    input wire [11:0] raddr_i,
    output reg [31:0] rdata_o,
    input wire [11:0] waddr_i,
    input wire [31:0] wdata_i,
    input wire we_i,
    input wire [31:0] pc_now_i,
    output reg [31:0] pc_next_o,
    output reg branch_o,
    input wire ecall_i,
    input wire ebreak_i,
    input wire mret_i,
    input wire time_interrupt_i
);

mtvec_t mtvec;
mscratch_t mscratch;
mepc_t mepc;
mcause_t mcause;
mstatus_t mstatus;
mie_t mie;
mip_t mip;

reg [1:0] mode;

always_comb begin
    case(raddr_i)
        12'h305: rdata_o = mtvec;
        12'h340: rdata_o = mscratch;
        12'h341: rdata_o = mepc;
        12'h342: rdata_o = mcause;
        12'h300: rdata_o = mstatus;
        12'h304: rdata_o = mie;
        12'h344: rdata_o = mip;
        default: rdata_o = 32'h0;
    endcase
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
        pc_next_o <= 32'h0;
        branch_o <= 1'b0;
        mode <= 2'b0;
    end else begin
        mip.mtip <= time_interrupt_i;
        if ((mstatus.mie || mode != 2'b11) && mip.mtip && mie.mtie) begin
            mode <= 2'b11;
            mepc <= pc_now_i;
            pc_next_o <=  {mtvec.base, 2'b0};
            branch_o <= 1'b1;
            mcause.interrupt <= 1'b1;
            mcause.exception <= 31'd7;  //
            mstatus.mpp <= mode;
            mstatus.mpie <= mstatus.mie; 
            mstatus.mie <= 0;
        end else if (ecall_i) begin 
            mode <= 2'b11;
            mepc <= pc_now_i;
            pc_next_o <=  {mtvec.base, 2'b0};
            branch_o <= 1'b1;
            if (mode == 2'b00) begin
                mcause <= 32'd8;
            end else begin
                mcause <= 32'd11;
            end
            mstatus.mpp <= mode;
            mstatus.mpie <= mstatus.mie; 
            mstatus.mie <= 0;
        end else if (ebreak_i) begin
            mode <= 2'b11;
            mepc <= pc_now_i;
            pc_next_o <=  {mtvec.base, 2'b0};
            branch_o <= 1'b1;
            mcause <= 32'd3;
            mstatus.mpp <= mode;
            mstatus.mpie <= mstatus.mie; 
            mstatus.mie <= 0;
        end else if (mret_i) begin
            mode <= mstatus.mpp;
            pc_next_o <= mepc;
            branch_o <= 1'b1;
            mstatus.mpp <= 2'b0;
            mstatus.mpie <= 1'b1; 
            mstatus.mie <= mstatus.mpie;
        end else begin
            pc_next_o <= 32'h0;
            branch_o <= 1'b0;
            if (we_i) begin
                case(waddr_i)
                    12'h305: mtvec <= wdata_i;      //
                    12'h340: mscratch <= wdata_i;
                    12'h341: mepc <= wdata_i;       //
                    12'h342: mcause <= wdata_i;     //
                    12'h300: mstatus <= wdata_i;
                    12'h304: mie <= wdata_i;
                    12'h344: mip <= wdata_i;
                    default: ;
                endcase
            end
        end
    end
end

endmodule   