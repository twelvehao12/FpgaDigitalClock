module tune_status_mgr(
    input clk,
    input rst_n,
    input [3:0] neg_keys_filtered,
    input [2:0] sys_status,

    output reg [1:0] tune_status
);

    parameter T_NONE = 2'd0;
    parameter T_HOUR = 2'd3;
    parameter T_MINUTE = 2'd2;
    parameter T_SECOND = 2'd1;

    parameter S_TUNESEL = 3'd2;
    parameter S_TUNING = 3'd3;
    parameter S_TUNEALARM = 3'd4;
    parameter S_ALARMTUNING = 3'd5;

    parameter MV_LEFT = 4'b0010;
    parameter MV_RIGHT = 4'b0100;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tune_status <= T_NONE;
        end
        else if (sys_status == S_TUNESEL || sys_status == S_TUNEALARM) begin
            case (tune_status)
                T_NONE: tune_status <= T_SECOND;
                T_SECOND: begin
                    if (neg_keys_filtered == MV_LEFT) begin
                        tune_status <= T_MINUTE;
                    end
                    else if (neg_keys_filtered == MV_RIGHT) begin
                        tune_status <= T_HOUR;
                    end
                    else begin
                        tune_status <= tune_status;
                    end
                end
                T_MINUTE: begin
                    if (neg_keys_filtered == MV_LEFT) begin
                        tune_status <= T_HOUR;
                    end
                    else if (neg_keys_filtered == MV_RIGHT) begin
                        tune_status <= T_SECOND;
                    end
                    else begin
                        tune_status <= tune_status;
                    end
                end
                T_HOUR: begin
                    if (neg_keys_filtered == MV_LEFT) begin
                        tune_status <= T_SECOND;
                    end
                    else if (neg_keys_filtered == MV_RIGHT) begin
                        tune_status <= T_MINUTE;
                    end
                    else begin
                        tune_status <= tune_status;
                    end
                end
                default: tune_status <= T_NONE;
            endcase
        end
        else if (sys_status == S_TUNING || sys_status == S_ALARMTUNING) begin
            tune_status <= tune_status;
        end
        else begin
            tune_status <= T_NONE;
        end
    end

endmodule
