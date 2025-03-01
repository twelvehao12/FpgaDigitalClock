module led_ctrl (
    input clk,
    input rst_n,
    input [2:0] sys_status,
    input [1:0] tune_status,

    output reg [3:0] leds
);

    parameter S_INIT = 3'd0;
    parameter S_NORM = 3'd1;
    parameter S_TUNESEL = 3'd2;
    parameter S_TUNING  = 3'd3;
    parameter S_TUNEALARM = 3'd4;
    parameter S_ALARMTUNING = 3'd5;
    parameter S_ALARMING = 3'd6;

    parameter T_NONE = 2'd0;
    parameter T_HOUR = 2'd3;
    parameter T_MINUTE = 2'd2;
    parameter T_SECOND = 2'd1;

    localparam MAX_NUM = 26'd50_000_000 >> 3; // 1/8s

    reg [25:0] cnt;
    reg cnt_flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 26'b0;
            cnt_flag <= 1'b0;
        end
        else if (cnt < MAX_NUM - 1'b1) begin
            cnt <= cnt + 1'b1;
        end
        else begin
            cnt <= 26'b0;
            cnt_flag <= ~cnt_flag;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            leds <= 4'b0001;
        end
        else begin
            case (sys_status)
                S_INIT: leds <= 4'b0001;
                S_NORM: leds <= 4'b0010;
                S_TUNESEL: begin
                    case (tune_status)
                        T_SECOND: leds <= 4'b1100;
                        T_MINUTE: leds <= 4'b1010;
                        T_HOUR:   leds <= 4'b1001;
                        default:  leds <= 4'b1000;
                    endcase
                end
                S_TUNING: leds <= 4'b1111;
                S_TUNEALARM: begin
                    case (tune_status)
                        T_SECOND: leds <= 4'b1100;
                        T_MINUTE: leds <= 4'b1010;
                        T_HOUR:   leds <= 4'b1001;
                        default:  leds <= 4'b1000;
                    endcase
                end
                S_ALARMTUNING: leds <= 4'b1111;
                S_ALARMING: begin
                    if (cnt_flag) begin
                        leds <= 4'b1100;
                    end
                    else begin
                        leds <= 4'b0011;
                    end
                end
                default: leds <= leds;
            endcase
        end
    end

endmodule
