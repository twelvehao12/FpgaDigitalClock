`timescale 1ns / 1ns

module tb_seg_led_top();

reg sys_clk;
reg sys_rst_n;

wire [5:0] seg_sel;
wire [7:0] seg_led;

parameter MAX_NUM = 26'd500_000;  // 10ms

always #10 sys_clk = ~sys_clk;

initial begin
    sys_clk = 1'b0;
    sys_rst_n = 1'b0;
    #200
    sys_rst_n = 1'b1;
end

seg_led_top #(
    .MAX_NUM(MAX_NUM)
) u_seg_led_top (
    .sys_clk (sys_clk),
    .sys_rst_n (sys_rst_n),
    
    .seg_sel (seg_sel),
    .seg_led (seg_led)
);

endmodule
