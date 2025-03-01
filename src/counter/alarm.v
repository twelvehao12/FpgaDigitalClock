module alarm(
    input clk,
    input rst_n,
    input [2:0] sys_status,
    input [19:0] offset,
    input [3:0] neg_keys_filtered,
    input [19:0] cnt_i, // Pass `cnt_j`

    output reg [19:0] cnt_alm,
    output reg reach_alarm_time
);

    parameter S_ALARMTUNING = 3'd5;
    parameter K_CONFIRM = 4'b1000;
    parameter OFFSET_INIT = 20'h7ffff;  // 20'hfffff/2

    localparam ALARM_OFF = 20'd86_400;   // 24:00:00
    localparam SEC_PER_DAY = 20'd86400; // 60*60*24 (seconds/day)

    reg [19:0] abs_offset;
    reg [19:0] cnt_tmp;

    // main
    // abs_offset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_offset <= 20'b0;
        end
        else begin
            if (sys_status == S_ALARMTUNING) begin
                if (offset < OFFSET_INIT) begin // negtive number
                    abs_offset <= OFFSET_INIT - offset;
                end
                else begin  // positive number
                    abs_offset <= offset - OFFSET_INIT;
                end
            end
        end
    end

    // cnt_alm
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_alm <= ALARM_OFF;
        end
        else begin
            if (sys_status == S_ALARMTUNING) begin
                if (offset < OFFSET_INIT) begin // negtive number
                    if (cnt_tmp < abs_offset) begin
                        cnt_alm <= ALARM_OFF;
                    end
                    else begin
                        cnt_alm <= cnt_tmp - abs_offset;
                    end
                end
                else begin  // positive number
                    if (cnt_tmp + abs_offset > SEC_PER_DAY) begin
                        cnt_alm <= ALARM_OFF;
                    end
                    else begin
                        cnt_alm <= cnt_tmp + abs_offset;
                    end
                end
            end
            else begin
                cnt_alm <= cnt_tmp;
            end
        end
    end

    // cnt_tmp
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_tmp <= ALARM_OFF;
        end
        else begin
            // Save offset changes
            if (sys_status == S_ALARMTUNING && neg_keys_filtered == K_CONFIRM) begin
                cnt_tmp <= cnt_alm;
            end
        end
    end

    // reach_alarm_time
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reach_alarm_time <= 20'b0;
        end
        else begin
            if (cnt_i == cnt_alm) begin
                reach_alarm_time <= 20'b1;
            end
            else begin
                reach_alarm_time <= 20'b0;
            end
        end
    end

endmodule