module regfile (
    input wire clk,
    input wire rst,
    // output reg [31:0] rf_rdata_x_debug,
    // output reg [31:0] rf_rdata_y_debug,
    output reg [1023:0] rf_regs_debug,
    
    input wire [ 4:0] rf_raddr_a,
    output reg [31:0] rf_rdata_a,
    input wire [ 4:0] rf_raddr_b,
    output reg [31:0] rf_rdata_b,
    input wire [ 4:0] rf_waddr,
    input wire [31:0] rf_wdata,
    input wire  rf_we
);

    // assign rf_rdata_x_debug = rf_regs[14];
    // assign rf_rdata_y_debug = rf_regs[15];
    assign rf_regs_debug = {
        rf_regs[0],
        rf_regs[1],
        rf_regs[2],
        rf_regs[3],
        rf_regs[4],
        rf_regs[5],
        rf_regs[6],
        rf_regs[7],
        rf_regs[8],
        rf_regs[9],
        rf_regs[10],
        rf_regs[11],
        rf_regs[12],
        rf_regs[13],
        rf_regs[14],
        rf_regs[15],
        rf_regs[16],
        rf_regs[17],
        rf_regs[18],
        rf_regs[19],
        rf_regs[20],
        rf_regs[21],
        rf_regs[22],
        rf_regs[23],
        rf_regs[24],
        rf_regs[25],
        rf_regs[26],
        rf_regs[27],
        rf_regs[28],
        rf_regs[29],
        rf_regs[30],
        rf_regs[31]
    };

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