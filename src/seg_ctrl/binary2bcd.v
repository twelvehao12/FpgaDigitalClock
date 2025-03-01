module binary2bcd(
    input wire sys_clk,
    input wire sys_rst_n,
    input wire [19:0] data,
    
    output reg [23:0] bcd_data
    );
    
    parameter CNT_SHIFT_NUM = 7'd20;
    
    reg [6:0] cnt_shift;
    reg [43:0] data_shift;
    reg shift_flag;
    
    // main
    // cnt_shift
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_shift <= 7'd0;
        end
        else if ((cnt_shift == CNT_SHIFT_NUM + 1) && (shift_flag)) begin
            cnt_shift <= 7'd0;
        end
        else if (shift_flag) begin
            cnt_shift <= cnt_shift + 1'b1;
        end
        else begin
            cnt_shift <= cnt_shift;
        end
    end
    
    // data_shift
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            data_shift <= 44'd0;
        end
        else if (cnt_shift == 7'd0) begin
            data_shift <= {24'b0, data};
        end
        else if ((cnt_shift <= CNT_SHIFT_NUM) && (!shift_flag)) begin
            data_shift[23:20] <= (data_shift[23:20] > 4)
            ? (data_shift[23:20] + 2'd3):(data_shift[23:20]);
            data_shift[27:24] <= (data_shift[27:24] > 4)
            ? (data_shift[27:24] + 2'd3):(data_shift[27:24]);
            data_shift[31:28] <= (data_shift[31:28] > 4)
            ? (data_shift[31:28] + 2'd3):(data_shift[31:28]);
            data_shift[35:32] <= (data_shift[35:32] > 4)
            ? (data_shift[35:32] + 2'd3):(data_shift[35:32]);
            data_shift[39:36] <= (data_shift[39:36] > 4)
            ? (data_shift[39:36] + 2'd3):(data_shift[39:36]);
            data_shift[43:40] <= (data_shift[43:40] > 4)
            ? (data_shift[43:40] + 2'd3):(data_shift[43:40]);
        end
        else if ((cnt_shift <= CNT_SHIFT_NUM) && (shift_flag)) begin
            data_shift <= data_shift << 1;
        end
        else begin
            data_shift <= data_shift;
        end
    end
    
    // shift_flag
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            shift_flag <= 1'b0;
        end
        else begin
            shift_flag <= ~shift_flag;
        end
    end
    
    // bcd_data
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            bcd_data <= 24'd0;
        end
        else if (cnt_shift == CNT_SHIFT_NUM + 1) begin
            bcd_data <= data_shift[43:20];
        end
        else begin
            bcd_data <= bcd_data;
        end
    end
    
endmodule
