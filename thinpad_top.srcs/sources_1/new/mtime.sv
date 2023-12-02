`include "header.sv"

module mtime (
    input wire clk,
    input wire rst,

    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [31:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    input wire [3:0] wb_sel_i,
    input wire wb_we_i,

    output reg time_interrupt_o
);

    mtime_t mtime;
    mtimecmp_t mtimecmp;

    assign time_interrupt_o = mtime >= mtimecmp;

    always_comb begin
        if (wb_cyc_i && wb_stb_i) begin
            if (~wb_we_i) begin
                case (wb_adr_i)
                    `MTIME_ADDR:      wb_dat_o = mtime[31:0];
                    `MTIME_ADDR+4:    wb_dat_o = mtime[63:32];
                    `MTIMECMP_ADDR:   wb_dat_o = mtimecmp[31:0];
                    `MTIMECMP_ADDR+4: wb_dat_o = mtimecmp[63:32];
                    default: wb_dat_o = 32'h0;
                endcase
            end else begin
                wb_dat_o = 32'h0;
            end
        end else begin
            wb_dat_o = 32'h0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            mtime <= 64'h0;
            mtimecmp <= 64'hffffffff;
        end else begin
            mtime <= mtime + 1;
            if (wb_cyc_i && wb_stb_i) begin
                if (wb_we_i) begin
                    case(wb_adr_i)
                        `MTIME_ADDR:      mtime[31:0] <= wb_dat_i;
                        `MTIME_ADDR+4:    mtime[63:32] <= wb_dat_i;
                        `MTIMECMP_ADDR:   mtimecmp[31:0] <= wb_dat_i;
                        `MTIMECMP_ADDR+4: mtimecmp[63:32] <= wb_dat_i;
                        default: ;
                    endcase
                end
            end
        end
    end

    assign wb_ack_o = wb_cyc_i & wb_stb_i;

endmodule