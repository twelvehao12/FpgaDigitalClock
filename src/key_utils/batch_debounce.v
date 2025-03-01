module batch_debounce(
    input clk,
    input rst_n,
    input [3:0] keys,

    output [3:0] neg_keys_filtered
);

    reg [3:0] keys_filter_d0;

    wire [3:0] keys_filtered;

    // main
    assign neg_keys_filtered = (~keys_filtered) & keys_filter_d0;

    // keys_filter_d0
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            keys_filter_d0 <= 4'b1111;
        end
        else begin
            keys_filter_d0 <= keys_filtered;
        end
    end

    // filters
    key_debounce u_key_debounce1(
        .clk(clk), 
        .rst_n(rst_n),
        .key(keys[0]),

        .key_filtered(keys_filtered[0])
    );
    key_debounce u_key_debounce2(
        .clk(clk), 
        .rst_n(rst_n),
        .key(keys[1]),

        .key_filtered(keys_filtered[1])
    );
    key_debounce u_key_debounce3(
        .clk(clk), 
        .rst_n(rst_n),
        .key(keys[2]),

        .key_filtered(keys_filtered[2])
    );
    key_debounce u_key_debounce4(
        .clk(clk), 
        .rst_n(rst_n),
        .key(keys[3]),

        .key_filtered(keys_filtered[3])
    );

endmodule
