module count(
    input clk,
    input rst_n,
    input [2:0] sys_status,
    input [19:0] offset,
    input [3:0] neg_keys_filtered,
    
    output [19:0] data,
    output reg [5:0] point,
    output reg en,
    output reg sign,
    output [19:0] alarm_data,
    output reach_alarm_time
    );
    
    parameter MAX_NUM = 26'd50_000_000; // 1s
    parameter S_INIT = 3'd0;
    parameter S_NORM = 3'd1;
    parameter S_TUNESEL = 3'd2;
    parameter S_TUNING  = 3'd3;
    parameter S_TUNEALARM = 3'd4;
    parameter S_ALARMTUNING = 3'd5;
    parameter S_ALARMING = 3'd6;
    parameter K_CONFIRM = 4'b1000;
    parameter OFFSET_INIT = 20'h7ffff;  // 20'hfffff/2

    localparam SEC_PER_DAY = 20'd86400; // 60*60*24 (seconds/day)
    localparam RUNNING  = 1'b1;
    localparam STOPPING = 1'b0;
    
    reg [19:0] cnt_i;
    reg [25:0] cnt_100ms;
    reg cnt_100ms_flag;
    reg run;
    reg [19:0] abs_offset;
    reg [19:0] cnt_j;

    wire [19:0] cnt_alm;
    
    // main
    // run
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            run <= STOPPING;
        end
        else begin
            case (sys_status)
                S_INIT:        run <= STOPPING;
                S_NORM:        run <= RUNNING;
                S_TUNESEL:     run <= STOPPING;
                S_TUNING:      run <= STOPPING;
                S_TUNEALARM:   run <= RUNNING;
                S_ALARMTUNING: run <= RUNNING;
                S_ALARMING:    run <= RUNNING;
                default:       run <= run;
            endcase
        end
    end

    // cnt
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_100ms <= 26'b0;
            cnt_100ms_flag <= 1'b0;
        end
        else if (cnt_100ms < MAX_NUM - 1'b1) begin
            cnt_100ms <= cnt_100ms + 1'b1;
            cnt_100ms_flag <= 1'b0;
        end
        else begin
            cnt_100ms <= 26'b0;
            cnt_100ms_flag <= 1'b1;
        end
    end

    // abs_offset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_offset <= 20'b0;
        end
        else begin
            if (sys_status == S_TUNING) begin
                if (offset < OFFSET_INIT) begin // negtive number
                    abs_offset <= OFFSET_INIT - offset;
                end
                else begin  // positive number
                    abs_offset <= offset - OFFSET_INIT;
                end
            end
        end
    end

    // cnt_i
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_i <= 20'b0;
        end
        else begin
            if (cnt_100ms_flag) begin
                if (cnt_i < SEC_PER_DAY) begin
                    if (run == 1'b1) begin
                        cnt_i <= cnt_i + 1'b1;
                    end
                    else begin
                        cnt_i <= cnt_i;
                    end
                end
                else begin
                    cnt_i <= 20'b0;
                end
            end
            // Save offset changes
            if (sys_status == S_TUNING && neg_keys_filtered == K_CONFIRM) begin
                cnt_i <= cnt_j;
            end
        end
    end

    // cnt_j
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_j <= 20'b0;
        end
        else begin
            if (sys_status == S_TUNING) begin
                if (offset < OFFSET_INIT) begin // negtive number
                    if (cnt_i < abs_offset) begin
                        cnt_j <= cnt_j;
                    end
                    else begin
                        cnt_j <= cnt_i - abs_offset;
                    end
                end
                else begin  // positive number
                    if (cnt_i + abs_offset > SEC_PER_DAY) begin
                        cnt_j <= cnt_j;
                    end
                    else begin
                        cnt_j <= cnt_i + abs_offset;
                    end
                end
            end
            else begin
                cnt_j <= cnt_i;
            end
        end
    end

    // outputs
    // data
    // cnt_i to 24h time format (20'dhhmmss)
    cnt2time u_cnt2time (
        .clk(clk),
        .rst_n(rst_n), 
        .cnt_i(cnt_j),

        .data(data)
    );

    // Alarm ctrl module
    alarm #(
        .S_ALARMTUNING(S_ALARMTUNING),
        .K_CONFIRM(K_CONFIRM),
        .OFFSET_INIT(OFFSET_INIT)
    ) u_alarm (
        .clk(clk),
        .rst_n(rst_n),
        .sys_status (sys_status),
        .offset (offset),
        .neg_keys_filtered (neg_keys_filtered),
        .cnt_i(cnt_j),

        .cnt_alm (cnt_alm),
        .reach_alarm_time (reach_alarm_time)
    );

    cntalm2time u_cntalm2time (
        .clk(clk),
        .rst_n(rst_n), 
        .cnt_i(cnt_alm),

        .data(alarm_data)
    );

    // other outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            point <= 6'b010100;
            en <= 1'b0;
            sign <= 1'b0;
        end
        else begin
            point <= 6'b010100;
            en <= 1'b1;
            sign <= 1'b0;
        end
    end
    
endmodule
