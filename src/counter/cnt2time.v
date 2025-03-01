module cnt2time(
    input clk,
    input rst_n,
    input [19:0] cnt_i,

    output reg [19:0] data
);

    reg [5:0] seconds;
    reg [5:0] minutes;
    reg [5:0] hours;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 20'b0;
        end
        else begin
            seconds = cnt_i % 60;
            minutes = cnt_i / 60 % 60;
            hours = cnt_i / 3600 % 24;
            data <= hours * 10000 + minutes * 100 + seconds;
        end
    end

endmodule
