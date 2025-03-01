module sys_status_mgr(
    input clk,
    input rst_n, 
    input [3:0] neg_keys_filtered,
    input reach_alarm_time,

    output reg [2:0] sys_status
);

    parameter S_INIT = 3'd0;
    parameter S_NORM = 3'd1;
    parameter S_TUNESEL = 3'd2;
    parameter S_TUNING  = 3'd3;
    parameter S_TUNEALARM = 3'd4;
    parameter S_ALARMTUNING = 3'd5;
    parameter S_ALARMING = 3'd6;

    parameter K_CONFIRM = 4'b1000;
    parameter K_CANCEL  = 4'b0001;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sys_status <= 3'd0;
        end
        else begin
            case (sys_status)
                S_INIT: begin
                    if (neg_keys_filtered == 4'b0000) begin
                        sys_status <= S_NORM;
                    end
                    else begin
                        sys_status <= sys_status;
                    end
                end
                S_NORM: begin
                    if (neg_keys_filtered == 4'b1000) begin
                        sys_status <= S_TUNESEL;
                    end
                    else if (neg_keys_filtered == 4'b0001) begin
                        sys_status <= S_TUNEALARM;
                    end
                    else if (reach_alarm_time == 1'b1) begin
                        sys_status <= S_ALARMING;
                    end
                    else begin
                        sys_status <= sys_status;
                    end
                end
                S_TUNESEL: begin
                    if (neg_keys_filtered == K_CANCEL) begin
                        sys_status <= S_NORM;
                    end
                    else if (neg_keys_filtered == K_CONFIRM) begin
                        sys_status <= S_TUNING;
                    end
                    else begin
                        sys_status <= sys_status;
                    end
                end
                S_TUNING: begin
                    if (neg_keys_filtered == K_CANCEL) begin
                        sys_status <= S_TUNESEL;
                    end
                    else if (neg_keys_filtered == K_CONFIRM) begin
                        sys_status <= S_TUNESEL;
                    end
                    else begin
                        sys_status <= sys_status;
                    end
                end
                S_TUNEALARM: begin
                    if (neg_keys_filtered == K_CONFIRM) begin
                        sys_status <= S_ALARMTUNING;
                    end
                    else if (neg_keys_filtered == K_CANCEL) begin
                        sys_status <= S_NORM;
                    end
                    else begin
                        sys_status <= sys_status;
                    end
                end
                S_ALARMTUNING: begin
                    if (neg_keys_filtered == K_CANCEL) begin
                        sys_status <= S_TUNEALARM;
                    end
                    else if (neg_keys_filtered == K_CONFIRM) begin
                        sys_status <= S_TUNEALARM;
                    end
                    else begin
                        sys_status <= sys_status;
                    end
                end
                S_ALARMING: begin
                    if (|neg_keys_filtered) begin
                        sys_status <= S_NORM;
                    end
                    else begin
                        sys_status <= sys_status;
                    end
                end
                default: sys_status <= S_NORM;
            endcase
        end
    end

endmodule
