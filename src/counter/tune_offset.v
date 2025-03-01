module tune_offset(
    input clk,
    input rst_n,
    input [2:0] sys_status,
    input [1:0] tune_status,
    input [3:0] neg_keys_filtered,

    output reg [19:0] offset
);

    parameter S_TUNING  = 3'd3;
    parameter S_ALARMTUNING = 3'd5;

    parameter T_NONE = 2'd0;
    parameter T_HOUR = 2'd3;
    parameter T_MINUTE = 2'd2;
    parameter T_SECOND = 2'd1;

    parameter MV_LEFT  = 4'b0010;
    parameter MV_RIGHT = 4'b0100;

    parameter OFFSET_INIT = 20'h7ffff;

    // main
    // offset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            offset <= OFFSET_INIT;
        end
        else begin
            if (sys_status == S_TUNING || sys_status == S_ALARMTUNING) begin
                case (tune_status)
                    T_HOUR: begin
                        if (neg_keys_filtered == MV_LEFT) begin
                            if (offset < 3600) begin
                                offset <= offset;
                            end
                            else begin
                                offset <= offset - 3600;
                            end
                        end
                        else if (neg_keys_filtered == MV_RIGHT) begin
                            if (offset > 20'hfffff - 3600) begin
                                offset <= offset;
                            end
                            else begin
                                offset <= offset + 3600;
                            end
                        end
                    end
                    T_MINUTE: begin
                        if (neg_keys_filtered == MV_LEFT) begin
                            if (offset < 60) begin
                                offset <= offset;
                            end
                            else begin
                                offset <= offset - 60;
                            end
                        end
                        else if (neg_keys_filtered == MV_RIGHT) begin
                            if (offset > 20'hfffff - 60) begin
                                offset <= offset;
                            end
                            else begin
                                offset <= offset + 60;
                            end
                        end
                    end
                    T_SECOND: begin
                        if (neg_keys_filtered == MV_LEFT) begin
                            if (offset < 1) begin
                                offset <= offset;
                            end
                            else begin
                                offset <= offset - 1;
                            end
                        end
                        else if (neg_keys_filtered == MV_RIGHT) begin
                            if (offset > 20'hfffff - 1) begin
                                offset <= offset;
                            end
                            else begin
                                offset <= offset + 1;
                            end
                        end
                    end
                    default: begin
                        offset <= OFFSET_INIT;
                    end
                endcase
            end
            else begin
                offset <= OFFSET_INIT;
            end
        end
    end

endmodule