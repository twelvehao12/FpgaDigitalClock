module key_debounce(
    input clk,
    input rst_n,
    input key,

    output reg key_filtered
);

    parameter CNT_MAX = 20'd1_000_000;   // 20ms

    reg [19:0] cnt;
    reg key_d0;
    reg key_d1;

    // main
    // key_d[01]
    // Delay by 2 clk cycles
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_d0 <= 1'b1;
            key_d1 <= 1'b1;
        end
        else begin
            key_d0 <= key;
            key_d1 <= key_d0;
        end
    end

    // cnt
    // debouncing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 20'd0;
        end
        else begin
            if (key_d1 != key_d0) begin // key state changes
                cnt <= CNT_MAX;
            end
            else begin  // wait 20ms
                if (cnt > 20'd0) begin
                    cnt <= cnt - 1'b1;
                end
                else begin
                    cnt <= 20'd0;
                end
            end
        end
    end

    // outputs
    // key_filtered
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_filtered <= 1'b1;
        end
        else if (cnt == 20'd1) begin
            key_filtered <= key_d1;
        end
        else begin
            key_filtered <= key_filtered;
        end
    end

endmodule
