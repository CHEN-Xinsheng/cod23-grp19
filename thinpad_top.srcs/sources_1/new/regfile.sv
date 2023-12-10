module regfile (
    input wire clk,
    input wire rst,
    // output reg [31:0] rf_rdata_x_debug,
    // output reg [31:0] rf_rdata_y_debug,
    output reg [31:0] rf_regs_debug[0:31],
    
    input wire [ 4:0] rf_raddr_a,
    output reg [31:0] rf_rdata_a,
    input wire [ 4:0] rf_raddr_b,
    output reg [31:0] rf_rdata_b,
    input wire [ 4:0] rf_waddr,
    input wire [31:0] rf_wdata,
    input wire  rf_we
);

    assign rf_regs_debug = rf_regs;

    reg [31:0] rf_regs [0:31];

    always_comb begin
        rf_rdata_a = (rf_we && rf_waddr != 0 && rf_waddr == rf_raddr_a) ? rf_wdata : rf_regs[rf_raddr_a];
        rf_rdata_b = (rf_we && rf_waddr != 0 && rf_waddr == rf_raddr_b) ? rf_wdata : rf_regs[rf_raddr_b];
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