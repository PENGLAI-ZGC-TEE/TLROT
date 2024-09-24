// `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2023/03/30 17:03:05
// Design Name:
// Module Name: PUF1bit
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
`include "header.sv"

module PUF1bit(
    input clk,
    input rst,
    input timer_enable,             //PUF start
    input [127:0] challenge,
    output response_done,             //response generated, can be sent form UART
    output [1:0] response
);

`ifdef SYNTHESIS
// `define TEST
// `ifdef TEST
parameter NUM_LUTS = 5;
parameter  NUM_OSCILLATORS = 128;

wire [127:0]  mux_in_a;      //RO output to MUX
wire [127:0]  mux_in_b;
wire [127:0] dec_out_a;     //RO selected to work
wire [127:0] dec_out_b;
wire [6:0] dec_in_a;        //RO selected code(need to decode)
wire [6:0] dec_in_b;
wire [31:0] cnt_out_a;       // counter output
wire [31:0] cnt_out_b;
wire cnt_ctrl;              //timer output to control the counter
// (* keep="true" *) wire [639:0] ca;            //RO lines
// (* keep="true" *) wire [639:0] cb;
wire [127:0] ena;           //RO enable signle
wire [127:0] enb;
wire cnt_done, cnt_done_a, cnt_done_b;  //counter ready to read data
(* keep="true" *) wire mux_out_a, mux_out_b;

(* keep="true" *) wire [127:0] ro_a;
(* keep="true" *) wire [127:0] ro_b;

//wire [639:0] ca_test;            //RO lines
//wire [639:0] cb_test;

RO_Array128 puf_a (
  .rst(rst),
  .en(ena),
  .ro_out(ro_a)
);

assign mux_in_a = ro_a;
assign ena = dec_out_a;

RO_Array128 puf_b (
  .rst(rst),
  .en(enb),
  .ro_out(ro_b)
);

assign mux_in_b = ro_b;
assign enb = dec_out_b;

//  genvar i;
//   generate
//     for (i=0; i < NUM_OSCILLATORS; i=i+1) begin: puf_a
//     (* keep="true" *)  wire [NUM_LUTS-1:0] ca; 

//       LUT3 #(.INIT(8'h7F)) LUTa_init (
//         .O(ca[0]),
//         .I0(ena[i]),
//         .I1(rst),
//         .I2(ca[NUM_LUTS-1])
//       );

//     //   assign #2 ca[0] = !(ena[i] & rst & ca[NUM_LUTS-1]);

//       genvar j;
//       for (j=1; j < NUM_LUTS; j=j+1) begin: LUT_chain
//         LUT1 #(.INIT(2'h1)) LUT (
//           .O(ca[j]),
//           .I0(ca[j-1])
//         );
//       end

//       LUT1 #(.INIT(2'h1)) LUTa_last (
//         .O(ro_a[i]),
//         .I0(ca[NUM_LUTS-3]) 
//       );

//       assign mux_in_a[i] = ro_a[i];
//       assign ena[i] = dec_out_a[i];
//     end
//   endgenerate

// genvar m;
//   generate
//     for (m=0; m < NUM_OSCILLATORS; m=m+1) begin: puf_b
//     (* keep="true" *)  wire [NUM_LUTS-1:0] cb; 

//       LUT3 #(.INIT(8'h7F)) LUTa_init (
//         .O(cb[0]),
//         .I0(enb[m]),
//         .I1(rst),
//         .I2(cb[NUM_LUTS-1])
//       );
//     //   assign #2 cb[0] = !(enb[m] & rst & cb[NUM_LUTS-1]);

//       genvar n;
//       for (n=1; n < NUM_LUTS; n=n+1) begin: LUT_chain
//         LUT1 #(.INIT(2'h1)) LUT (
//           .O(cb[n]),
//           .I0(cb[n-1])
//         );
//       end

//       LUT1 #(.INIT(2'h1)) LUTa_last (
//         .O(ro_b[m]),
//         .I0(cb[NUM_LUTS-3]) 
//       );

//       assign mux_in_b[m] = ro_b[m];
//       assign enb[m] = dec_out_b[m];
//     end
//   endgenerate



//zdr: can be improved
assign dec_in_b = challenge[6:0];
assign dec_in_a = challenge[13:7];

PUFDec128 DecA(
    .i_Sel(dec_in_a),
    .o_Q(dec_out_a)
);

PUFDec128 DecB(
    .i_Sel(dec_in_b),
    .o_Q(dec_out_b)
);

PUFMux128 MuxA(
    .i_D(mux_in_a),
    .i_Sel(dec_in_a),
    .o_Q(mux_out_a)
);

PUFMux128 MuxB(
    .i_D(mux_in_b),
    .i_Sel(dec_in_b),
    .o_Q(mux_out_b)
);

Timer #(.target(6'd50)) u_timer(
    .rst(rst),
    .clk(clk),
    .enable(timer_enable),
    .ctrl(cnt_ctrl)
);

Counter CounterA(
    .cnt_in(mux_out_a),
    .clk(clk),
    .rst(rst),
    .cnt_out(cnt_out_a),
    .cnt_ctrl(cnt_ctrl),
    .done(cnt_done_a),
    .clear(cnt_clear)
);

Counter CounterB(
    .cnt_in(mux_out_b),
    .clk(clk),
    .rst(rst),
    .cnt_out(cnt_out_b),
    .cnt_ctrl(cnt_ctrl),
    .done(cnt_done_b),
    .clear(cnt_clear)
);

assign cnt_done = cnt_done_a && cnt_done_b;

Comp u_comp(
    .clk(clk),
    .rst(rst),
    .num1(cnt_out_a),
    .num2(cnt_out_b),
    .comp_en(cnt_done),
    .done(response_done),
    .result(response)
);

Timer #(.target(2)) u_cnt_clear(
    .rst(rst),
    .clk(clk),
    .enable(response_done),
    .ctrl(cnt_clear)
);

`else

localparam M = 15; // 定义LFSR运行周期的数量，根据需要修改
reg [127:0] lfsr; // 128位线性反馈移位寄存器
reg [3:0] done_counter; // 完成后的倒计时计数器
reg [7:0] run_counter; // LFSR运行计数器

reg [1:0] response_reg;
reg response_done_reg;

assign response = response_reg;
assign response_done = response_done_reg;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        lfsr <= 0;
        response_reg <= 0;
        response_done_reg <= 0;
        done_counter <= 0;
        run_counter <= 0;
    end else if (timer_enable) begin
        if (run_counter == 0) begin
            lfsr <= challenge;
            run_counter <= run_counter + 1;
        end  else if (run_counter < M) begin
            lfsr <= {lfsr[0]^lfsr[22]^lfsr[36]^lfsr[49]^lfsr[88],lfsr[37]^lfsr[85]^lfsr[96]^lfsr[108]^lfsr[122],lfsr[127:2]};
            run_counter <= run_counter + 1;
        end else  if (run_counter == M) begin
            response_reg <= lfsr[127:126]; // 取LFSR的高两位作为response
            response_done_reg <= 1; // 标记响应完成
            run_counter <= run_counter + 1; // 防止重复进入此条件分支
        end
    end else if (response_done_reg) begin
        if (done_counter < 2) begin
            done_counter <= done_counter + 1;
        end else begin
            response_done_reg <= 0; // 2个周期后将response_done置低
            done_counter <= 0; // 重置计数器
        end
    end else begin
        // 当timer_enable为低且response_done为低时，复位计数器
        run_counter <= 0;
        done_counter <= 0;
    end
end


`endif

endmodule

