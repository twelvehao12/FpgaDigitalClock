module seg_led(
    input clk,
    input rst_n,
    input [19:0] data,
    input [5:0] point,
    input en,
    input sign,
    
    output reg [5:0] seg_sel,
    output reg [7:0] seg_led
    );
    
    localparam MAX_NUM = 50_000;
    
    reg [23:0] bcd_data_t;
    reg [15:0] cnt_1ms;
    reg cnt_1ms_flag;
    reg [2:0] cnt_sel;
    reg [3:0] bcd_data_disp;
    reg dot_disp;
    
    wire [23:0] bcd_data;
    
    // main
    // bcd_data_t
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bcd_data_t <= 24'b0;
        end
        else begin
            if (bcd_data[23:20] || point[5]) begin  // sixth digit != 0
                bcd_data_t <= bcd_data;
            end
            else if (bcd_data[19:16] || point[4]) begin // fifth digit != 0
                bcd_data_t[19:0] <= bcd_data[19:0];
                if (sign) begin
                    bcd_data_t[23:20] <= 4'd11;
                end
                else begin
                    bcd_data_t[23:20] <= 4'd10;
                end
            end
            else if (bcd_data[15:12] || point[3]) begin // fourth digit != 0
                bcd_data_t[15:0] <= bcd_data[15:0];
                bcd_data_t[23:20] <= 4'd10;
                if (sign) begin
                    bcd_data_t[19:16] <= 4'd11;
                end
                else begin
                    bcd_data_t[19:16] <= 4'd10;
                end
            end
            else if (bcd_data[11:8] || point[2]) begin // third digit != 0
                bcd_data_t[11:0] <= bcd_data[11:0];
                bcd_data_t[23:16] <= {2{4'd10}};
                if (sign) begin
                    bcd_data_t[15:12] <= 4'd11;
                end
                else begin
                    bcd_data_t[15:12] <= 4'd10;
                end
            end
            else if (bcd_data[7:4] || point[1]) begin // second digit != 0
                bcd_data_t[7:0] <= bcd_data[7:0];
                bcd_data_t[23:12] <= {3{4'd10}};
                if (sign) begin
                    bcd_data_t[11:8] <= 4'd11;
                end
                else begin
                    bcd_data_t[11:8] <= 4'd10;
                end
            end
            else begin
                bcd_data_t[3:0] <= bcd_data[3:0];
                bcd_data_t[23:8] <= {4{4'd10}};
                if (sign) begin
                    bcd_data_t[7:4] <= 4'd11;
                end
                else begin
                    bcd_data_t[7:4] <= 4'd10;
                end
            end
        end
    end
    
    // cnt_1ms
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_1ms <= 13'b0;
            cnt_1ms_flag <= 1'b0;
        end
        else if (cnt_1ms < MAX_NUM - 1'b1) begin
            cnt_1ms <= cnt_1ms + 1;
            cnt_1ms_flag <= 1'b0;
        end
        else begin
            cnt_1ms <= 13'b0;
            cnt_1ms_flag <= 1'b1;
        end
    end
    
    // cnt_sel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_sel <= 3'b0;
        end
        else if (cnt_1ms_flag) begin
            if (cnt_sel < 3'd5) begin
                cnt_sel <= cnt_sel + 1'b1;
            end
            else begin
                cnt_sel <= 3'b0;
            end
        end
        else begin
            cnt_sel <= cnt_sel;
        end
    end
    
    // seg_sel, bcd_data_disp, dot_disp
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seg_sel <= 6'b111111;
            bcd_data_disp <= 4'b0;
            dot_disp <= 1'b1;
        end
        else begin
            if (en) begin
                case (cnt_sel)
                    3'd0 : begin
                        seg_sel <= 6'b111110;
                        bcd_data_disp <= bcd_data_t[3:0];
                        dot_disp <= ~point[0];
                    end
                    3'd1 : begin
                        seg_sel <= 6'b111101;
                        bcd_data_disp <= bcd_data_t[7:4];
                        dot_disp <= ~point[1];
                    end
                    3'd2 : begin
                        seg_sel <= 6'b111011;
                        bcd_data_disp <= bcd_data_t[11:8];
                        dot_disp <= ~point[2];
                    end
                    3'd3 : begin
                        seg_sel <= 6'b110111;
                        bcd_data_disp <= bcd_data_t[15:12];
                        dot_disp <= ~point[3];
                    end
                    3'd4 : begin
                        seg_sel <= 6'b101111;
                        bcd_data_disp <= bcd_data_t[19:16];
                        dot_disp <= ~point[4];
                    end
                    3'd5 : begin
                        seg_sel <= 6'b011111;
                        bcd_data_disp <= bcd_data_t[23:20];
                        dot_disp <= ~point[5];
                    end
                    default : begin
                        seg_sel <= 6'b111111;
                        bcd_data_disp <= 4'b0;
                        dot_disp <= 1;
                    end
                endcase 
            end
            else begin  // !en
                seg_sel <= 6'b111111;
                bcd_data_disp <= 4'b0;
                dot_disp <= 1;
            end
        end
    end
    
    // seg_led
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seg_led <= 8'hff;
        end
        else begin
            case (bcd_data_disp)
                4'd0 : seg_led <= {dot_disp,7'b1000000};
                4'd1 : seg_led <= {dot_disp,7'b1111001};
                4'd2 : seg_led <= {dot_disp,7'b0100100};
                4'd3 : seg_led <= {dot_disp,7'b0110000};
                4'd4 : seg_led <= {dot_disp,7'b0011001};
                4'd5 : seg_led <= {dot_disp,7'b0010010};
                4'd6 : seg_led <= {dot_disp,7'b0000010};
                4'd7 : seg_led <= {dot_disp,7'b1111000};
                4'd8 : seg_led <= {dot_disp,7'b0000000};
                4'd9 : seg_led <= {dot_disp,7'b0010000};
                4'd10: seg_led <= {dot_disp,7'b1000000};  // '0' or '0.'
                4'd11: seg_led <= 8'b10111111;  // sign: '-'
                default : seg_led <= 8'hff;
            endcase
        end
    end
    
    binary2bcd u_binary2bcd (
        .sys_clk (clk),
        .sys_rst_n (rst_n),
        
        .data (data),
        .bcd_data (bcd_data)
    );
    
endmodule
