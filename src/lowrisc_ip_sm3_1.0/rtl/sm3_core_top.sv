// `timescale 1ns / 1ps
// `include "./inc/sm3_cfg.v"
`include "sm3_cfg.sv"
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs / lf_gibbs@163.com
// Create Date: 2020/07/29 
// Design Name: sm3
// Module Name: sm3_core_top
// Description:
//      SM3 顶层模块，例化下层的 SM3 填充、扩展以及迭代压缩三个模块
//      输入位宽：INPT_DW1 定义，支持32/64
//      输出位宽：与输入位宽一致
// Dependencies: 
//      inc/sm3_cfg.v
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module sm3_core_top (

    input                       clk,
    input                       rst_n,
    input [`INPT_DW1:0]         msg_inpt_d,
    input [`INPT_BYTE_DW1:0]    msg_inpt_vld_byte,
    input                       msg_inpt_vld,
    input                       msg_inpt_lst,
    
    output                      msg_inpt_rdy,

    output[255:0]               cmprss_otpt_res,
    output                      cmprss_otpt_vld,
    output                      msg_inpt_rdy_re,
    output                      cmprss_vld_re,
    output[7:0]                 cmprss_res_re
);

//interface
sm3_if int_if();
wire msg_inpt_lst_real;

assign msg_inpt_lst_real = msg_inpt_lst & msg_inpt_vld;
assign msg_inpt_rdy_re = 1'b1;
assign cmprss_vld_re = cmprss_otpt_vld;
assign cmprss_res_re = {8{cmprss_otpt_vld}};

sm3_pad_core U_sm3_pad_core(

    .clk                    (clk                    ),
    .rst_n                  (rst_n                  ),

    .msg_inpt_d_i           (msg_inpt_d             ),
    .msg_inpt_vld_byte_i    (msg_inpt_vld_byte      ),
    .msg_inpt_vld_i         (msg_inpt_vld           ),
    .msg_inpt_lst_i         (msg_inpt_lst_real      ),

    .msg_inpt_rdy_o         (msg_inpt_rdy           ),

    .pad_otpt_ena_i         (int_if.pad_otpt_ena        ),

    .pad_otpt_d_o           (int_if.pad_otpt_d             ),
    .pad_otpt_lst_o         (int_if.pad_otpt_lst           ),
    .pad_otpt_vld_o         (int_if.pad_otpt_vld           )
); 

sm3_expnd_core U_sm3_expnd_core(
    
    .clk                    (clk                    ),
    .rst_n                  (rst_n                  ),


    .pad_inpt_d_i               ( int_if.pad_otpt_d                    ),
    .pad_inpt_vld_i             ( int_if.pad_otpt_vld                  ),
    .pad_inpt_lst_i             ( int_if.pad_otpt_lst                  ),

    .pad_inpt_rdy_o             ( int_if.pad_otpt_ena                  ),
    .expnd_otpt_wj_o            ( int_if.expnd_otpt_wj                 ),
    .expnd_otpt_wjj_o           ( int_if.expnd_otpt_wjj                ),
    .expnd_otpt_lst_o           ( int_if.expnd_otpt_lst                ),
    .expnd_otpt_vld_o           ( int_if.expnd_otpt_vld                )
);   

sm3_cmprss_core U_sm3_cmprss_core(
    .clk                    (clk                    ),
    .rst_n                  (rst_n                  ),


    .expnd_inpt_wj_i            ( int_if.expnd_otpt_wj                  ),
    .expnd_inpt_wjj_i           ( int_if.expnd_otpt_wjj                  ),
    .expnd_inpt_lst_i           ( int_if.expnd_otpt_lst                  ),
    .expnd_inpt_vld_i           ( int_if.expnd_otpt_vld                  ),

    .cmprss_otpt_res_o          ( cmprss_otpt_res               ),
    .cmprss_otpt_vld_o          ( cmprss_otpt_vld               )

);  
    
endmodule