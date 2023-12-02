`include "../header.sv"

module icache # (
    parameter ICACHE_SIZE = 32,
    parameter INDEX_WIDTH = 5,  // ICACHE_SIZE = 2^INDEX_WIDTH
    parameter OFFSET_WIDTH = 2,
    parameter TAG_WIDTH = ADDR_WIDTH - OFFSET_WIDTH - INDEX_WIDTH  // 24
)(
    input wire clk,
    input wire rst,
    input wire fence_i,
    input wire[31:0] pc_i,
    input wire enable_i,

    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o,
    output reg [DATA_WIDTH-1:0] inst_o,
    output reg icache_ack_o
);

    typedef enum logic { 
        IF_ICACHE, 
        IF_MEM 
    } if_state_t;
    if_state_t if_state;

    logic [TAG_WIDTH + DATA_WIDTH:0] cache[ICACHE_SIZE];
    logic [TAG_WIDTH + DATA_WIDTH:0] cacheline_hit;
    logic cacheline_hit_valid;
    logic [TAG_WIDTH - 1:0] cacheline_hit_tag;
    logic [DATA_WIDTH - 1:0] cacheline_hit_data;
    logic cache_hit;
    logic [TAG_WIDTH - 1:0] pc_tag;
    logic [INDEX_WIDTH - 1:0] pc_index;

    assign pc_tag = pc_i[ADDR_WIDTH - 1:INDEX_WIDTH + OFFSET_WIDTH];
    assign pc_index = pc_i[INDEX_WIDTH + OFFSET_WIDTH - 1:OFFSET_WIDTH];
    assign cacheline_hit = cache[pc_index];
    assign cacheline_hit_valid = cacheline_hit[TAG_WIDTH + DATA_WIDTH];
    assign cacheline_hit_tag = cacheline_hit[TAG_WIDTH + DATA_WIDTH - 1:DATA_WIDTH];
    assign cacheline_hit_data = cacheline_hit[DATA_WIDTH - 1:0];
    assign cache_hit = (~fence_i) && (cacheline_hit_valid) && (pc_tag == cacheline_hit_tag);

    always_ff @(posedge clk) begin
        if (rst | fence_i) begin
            for (integer i = 0; i < ICACHE_SIZE; i = i + 1) begin
                cache[i][TAG_WIDTH + DATA_WIDTH] <= 1'b0;
            end
        end
        if (rst) begin
            if_state <= IF_ICACHE;
        end else begin
            case (if_state)
                IF_ICACHE: begin
                    if (enable_i) begin
                        if (cache_hit) begin
                            if_state <= IF_ICACHE;
                            wb_stb_o <= 1'b0;
                        end else begin
                            if_state <= IF_MEM;
                            wb_stb_o <= 1'b1;
                        end
                    end else begin
                        wb_stb_o <= 1'b0;
                    end
                end
                IF_MEM: begin
                    if (wb_ack_i) begin
                        cache[pc_index] <= {1'b1, pc_tag, wb_dat_i};
                        if_state <= IF_ICACHE;
                        wb_stb_o <= 1'b0;
                    end else begin
                        if_state <= IF_MEM;
                        wb_stb_o <= 1'b1;
                    end
                end
            endcase
        end
    end

    always_comb begin
        case (if_state)
            IF_ICACHE: begin
                if (enable_i) begin
                    if (cache_hit) begin
                        inst_o = cacheline_hit_data;
                        icache_ack_o = 1'b1;
                    end else begin
                        inst_o = 32'h0;
                        icache_ack_o = 1'b0;
                    end
                end else begin
                    // wb_stb_o = 1'b0;
                    inst_o = 32'h0;
                    icache_ack_o = 1'b1;
                end
            end
            IF_MEM: begin
                if (wb_ack_i) begin
                    inst_o = wb_dat_i;
                    icache_ack_o = 1'b1;
                end else begin
                    inst_o = 32'h0;
                    icache_ack_o = 1'b0;
                end
            end
            default: begin
                inst_o = 32'h0;
                icache_ack_o = 1'b0;
            end
        endcase
    end

    assign wb_cyc_o = wb_stb_o;
    assign wb_dat_o = {DATA_WIDTH{1'b0}};
    assign wb_sel_o = {DATA_WIDTH/8{1'b1}};
    assign wb_we_o = 1'b0;
    assign wb_adr_o = pc_i;
endmodule