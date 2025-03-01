module seg_data_sel(
    input clk,
    input rst_n,
    input [2:0] sys_status,
    input [19:0] data,
    input [19:0] alarm_data,

    output reg [19:0] seg_data
);

    parameter S_TUNEALARM = 3'd4;
    parameter S_ALARMTUNING = 3'd5;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seg_data <= 20'd0;
        end
        else begin
            case (sys_status)
                S_TUNEALARM:    seg_data <= alarm_data;
                S_ALARMTUNING:  seg_data <= alarm_data;
                default: seg_data <= data;
            endcase
        end
    end

endmodule
