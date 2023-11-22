module button_in (
    input wire clk,
    input wire reset,
    input wire push_btn,
    output wire trigger
);

    reg state, trigger_reg;
    always_ff @ (posedge clk or posedge reset) begin
        if(reset) begin
            state <= 0;
            trigger_reg <= 0;
        end else begin
            if (push_btn && ~state)
                trigger_reg <= 1;
            else
                trigger_reg <= 0;
            state <= push_btn;
        end
    end
    assign trigger = trigger_reg;

endmodule