module regfile (
    input wire clk,
    input wire rst,
    input wire  [4:0]  rf_raddr_a,
    output reg [31:0] rf_rdata_a,
    input wire  [4:0]  rf_raddr_b,
    output reg [31:0] rf_rdata_b,
    input wire  [4:0]  rf_waddr,
    input wire  [31:0] rf_wdata,
    input wire  rf_we
);

    reg [31:0] rf_regs [0:31];

    always_comb begin
        rf_rdata_a = rf_regs[rf_raddr_a];
        rf_rdata_b = rf_regs[rf_raddr_b];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < 32; i = i + 1) begin
                rf_regs[i] <= 0;
            end
        end else begin
            if (rf_we && rf_waddr != 0) begin
                rf_regs[rf_waddr] <= rf_wdata;
            end
        end
    end

endmodule