// `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2023/03/29 16:58:55
// Design Name:
// Module Name: Counter
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module Counter(
    input cnt_in,                //counter clk
    input clk,
    input rst,
    input cnt_ctrl,             //cnt_ctrl=1, counter start; cnt_ctrl=0,counter stop
    input clear,                //clear = 1,cnt_out reset to 0; else cnt_out retain
    output done,                //cnt_ctrl transmit form 1 to 0, than done=1
    output reg [31:0] cnt_out
);

    reg done_reg;
    // reg cnt_flag;
    reg cnt_ctrl_delayed;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            done_reg <= 1'b0;
            cnt_ctrl_delayed <= 1'b1; 
        end else begin
            if (cnt_ctrl_delayed && !cnt_ctrl) begin
                done_reg <= 1'b1;
            end else begin
                done_reg <= 1'b0;
            end
            cnt_ctrl_delayed <= cnt_ctrl;
        end
    end


    assign done = done_reg;

    always @(posedge cnt_in or negedge rst) begin
        if (!rst) begin
            cnt_out <= 32'd0;
        end else if (clear) begin
            cnt_out <= 32'd0;
        end else if (cnt_ctrl) begin
            cnt_out <= cnt_out + 1'd1;
        end else begin
            cnt_out <= cnt_out ;
        end
    end

endmodule

