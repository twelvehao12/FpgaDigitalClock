module seg_led_top(
    input sys_clk,
    input sys_rst_n,
    input [3:0] keys,
    
    output [3:0] leds,
    output [5:0] seg_sel,
    output [7:0] seg_led
);

    wire [19:0] data;
    wire [5:0] point;
    wire en;
    wire sign;
    wire [19:0] alarm_data;
    wire reach_alarm_time;

    wire [19:0] seg_data;

    wire [3:0] neg_keys_filtered;
    wire [2:0] sys_status;
    wire [1:0] tune_status;

    wire [19:0] offset;
    
    parameter MAX_NUM = 26'd50_000_000; // 1s
    parameter OFFSET_INIT = 20'h7ffff;  // 20'hfffff/2
    
    // Used to test if data will overflow
    // parameter MAX_NUM = 26'd50_000; // 1/1000s

    // tsatus ctrl params
    // sys
    parameter S_INIT = 3'd0;
    parameter S_NORM = 3'd1;
    parameter S_TUNESEL = 3'd2;
    parameter S_TUNING  = 3'd3; 
    parameter S_TUNEALARM = 3'd4;
    parameter S_ALARMTUNING = 3'd5;
    parameter S_ALARMING = 3'd6;
    // tune selection
    parameter T_NONE = 2'd0;
    parameter T_HOUR = 2'd3;
    parameter T_MINUTE = 2'd2;
    parameter T_SECOND = 2'd1;
    // key
    parameter MV_LEFT  = 4'b0010;
    parameter MV_RIGHT = 4'b0100;
    parameter K_CONFIRM = 4'b1000;
    parameter K_CANCEL  = 4'b0001;
    
    // main
    count #(
        .MAX_NUM(MAX_NUM),
        .S_INIT(S_INIT),
        .S_NORM(S_NORM),
        .S_TUNESEL(S_TUNESEL),
        .S_TUNING(S_TUNING),
        .OFFSET_INIT(OFFSET_INIT)
    ) u_count (
        .clk (sys_clk),
        .rst_n (sys_rst_n),
        .sys_status (sys_status),
        .offset (offset),
        .neg_keys_filtered (neg_keys_filtered),
        
        .data (data),
        .point (point),
        .en (en),
        .sign (sign),
        .alarm_data (alarm_data),
        .reach_alarm_time (reach_alarm_time)
    );

    tune_offset #(
        .S_TUNING(S_TUNING),
        .T_NONE(T_NONE),
        .T_HOUR(T_HOUR),
        .T_MINUTE(T_MINUTE), 
        .T_SECOND(T_SECOND),
        .MV_LEFT(MV_LEFT),
        .MV_RIGHT(MV_RIGHT),
        .OFFSET_INIT(OFFSET_INIT)
    ) u_tune_offset (
        .clk (sys_clk),
        .rst_n (sys_rst_n),
        .neg_keys_filtered (neg_keys_filtered),
        .sys_status (sys_status),
        .tune_status (tune_status),

        .offset (offset)
    );

    seg_data_sel #(
        .S_TUNEALARM(S_TUNEALARM),
        .S_ALARMTUNING(S_ALARMTUNING)
    ) u_seg_data_sel (
        .clk (sys_clk),
        .rst_n (sys_rst_n),
        .sys_status (sys_status),
        .data (data),
        .alarm_data (alarm_data),

        .seg_data (seg_data)
    );

    seg_led u_seg_led (
        .clk (sys_clk),
        .rst_n (sys_rst_n),
        .data (seg_data),
        .point (point),
        .en (en),
        .sign (sign),
        
        .seg_sel (seg_sel),
        .seg_led (seg_led)
    );

    batch_debounce u_batch_debounce (
        .clk (sys_clk),
        .rst_n (sys_rst_n),
        .keys (keys),

        .neg_keys_filtered(neg_keys_filtered)
    );
    
    sys_status_mgr #(
        .S_INIT(S_INIT),
        .S_NORM(S_NORM),
        .S_TUNESEL(S_TUNESEL),
        .S_TUNING(S_TUNING),
        .K_CONFIRM(K_CONFIRM),
        .K_CANCEL(K_CANCEL)
    ) u_sys_status_mgr (
        .clk (sys_clk),
        .rst_n (sys_rst_n),
        .neg_keys_filtered (neg_keys_filtered),
        .reach_alarm_time (reach_alarm_time),

        .sys_status(sys_status)
    );

    tune_status_mgr #(
        .T_NONE(T_NONE),
        .T_HOUR(T_HOUR),
        .T_MINUTE(T_MINUTE), 
        .T_SECOND(T_SECOND),
        .S_TUNESEL(S_TUNESEL),
        .S_TUNING(S_TUNING),
        .MV_LEFT(MV_LEFT),
        .MV_RIGHT(MV_RIGHT)
    ) u_tune_status_mgr (
        .clk (sys_clk),
        .rst_n (sys_rst_n),
        .neg_keys_filtered (neg_keys_filtered),
        .sys_status (sys_status),

        .tune_status (tune_status)
    );

    led_ctrl #(
        .S_INIT(S_INIT),
        .S_NORM(S_NORM),
        .S_TUNESEL(S_TUNESEL),
        .S_TUNING(S_TUNING),
        .T_NONE(T_NONE),
        .T_HOUR(T_HOUR),
        .T_MINUTE(T_MINUTE), 
        .T_SECOND(T_SECOND)
    ) u_led_ctrl (
        .clk (sys_clk),
        .rst_n (sys_rst_n),
        .sys_status (sys_status),
        .tune_status (tune_status),

        .leds (leds)
    );

endmodule
