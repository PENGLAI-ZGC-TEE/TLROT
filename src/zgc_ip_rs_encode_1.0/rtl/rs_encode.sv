`include "prim_assert.sv"

module rs_encode
  import rs_encode_reg_pkg::*;
(
  input  logic                                      clk_i,
  input  logic                                      rst_ni,
  input  logic                                      scan_mode,
  // Bus interface
  input  tlul_pkg::tl_h2d_t                         tl_i,
  output tlul_pkg::tl_d2h_t                         tl_o
);

  rs_encode_reg2hw_t               reg2hw;
  rs_encode_hw2reg_t               hw2reg;
  //wire                       ready_out;

  rs_encode_reg_top  u_rs_encode_reg_top (
    .clk_i                             ( clk_i           ),
    .rst_ni                            ( rst_ni          ),
    .tl_i                              ( tl_i            ),
    .hw2reg                            ( hw2reg          ),
    .devmode_i                         ( 1'b1            ),

    .tl_o                              ( tl_o            ),
    .reg2hw                            ( reg2hw          ),
    .intg_err_o                        (                 )
);

assign hw2reg.ctrl_signals.clrn.de = 1'd0;
assign hw2reg.ctrl_signals.encode_en.de = 1'd0;
assign hw2reg.ctrl_signals.clrn.d = 1'd0;
assign hw2reg.ctrl_signals.encode_en.d = 1'd0;
always_comb begin
  for (int i = 0; i < 42; i++) begin
    hw2reg.data_in[i].de = 1'd0;
    hw2reg.data_in[i].d = '0;
  end
end

rs_encode_wrapper  u_rs_encode_wrapper (
    .clk                     ( clk_i                         ),
    .rst_n                   ( rst_ni                        ),
    .clrn                    ( reg2hw.ctrl_signals.clrn.q ),
    .scan_mode                (scan_mode),
    .encode_en               ( reg2hw.ctrl_signals.encode_en.q ),
    .datain                  ( {reg2hw.data_in[41].q,reg2hw.data_in[40].q,reg2hw.data_in[39].q,reg2hw.data_in[38].q,reg2hw.data_in[37].q,reg2hw.data_in[36].q,reg2hw.data_in[35].q,reg2hw.data_in[34].q,reg2hw.data_in[33].q,reg2hw.data_in[32].q,reg2hw.data_in[31].q,reg2hw.data_in[30].q,reg2hw.data_in[29].q,reg2hw.data_in[28].q,reg2hw.data_in[27].q,reg2hw.data_in[26].q,reg2hw.data_in[25].q,reg2hw.data_in[24].q,reg2hw.data_in[23].q,reg2hw.data_in[22].q,reg2hw.data_in[21].q,reg2hw.data_in[20].q,reg2hw.data_in[19].q,reg2hw.data_in[18].q,reg2hw.data_in[17].q,reg2hw.data_in[16].q,reg2hw.data_in[15].q,reg2hw.data_in[14].q,reg2hw.data_in[13].q,reg2hw.data_in[12].q,reg2hw.data_in[11].q,reg2hw.data_in[10].q,reg2hw.data_in[9].q,reg2hw.data_in[8].q,reg2hw.data_in[7].q,reg2hw.data_in[6].q,reg2hw.data_in[5].q,reg2hw.data_in[4].q,reg2hw.data_in[3].q,reg2hw.data_in[2].q,reg2hw.data_in[1].q,reg2hw.data_in[0].q}),

    .encoded_data            ( {hw2reg.encoded_data_out[49].d,hw2reg.encoded_data_out[48].d,hw2reg.encoded_data_out[47].d,hw2reg.encoded_data_out[46].d,hw2reg.encoded_data_out[45].d,hw2reg.encoded_data_out[44].d,hw2reg.encoded_data_out[43].d,hw2reg.encoded_data_out[42].d,hw2reg.encoded_data_out[41].d,hw2reg.encoded_data_out[40].d,hw2reg.encoded_data_out[39].d,hw2reg.encoded_data_out[38].d,hw2reg.encoded_data_out[37].d,hw2reg.encoded_data_out[36].d,hw2reg.encoded_data_out[35].d,hw2reg.encoded_data_out[34].d,hw2reg.encoded_data_out[33].d,hw2reg.encoded_data_out[32].d,hw2reg.encoded_data_out[31].d,hw2reg.encoded_data_out[30].d,hw2reg.encoded_data_out[29].d,hw2reg.encoded_data_out[28].d,hw2reg.encoded_data_out[27].d,hw2reg.encoded_data_out[26].d,hw2reg.encoded_data_out[25].d,hw2reg.encoded_data_out[24].d,hw2reg.encoded_data_out[23].d,hw2reg.encoded_data_out[22].d,hw2reg.encoded_data_out[21].d,hw2reg.encoded_data_out[20].d,hw2reg.encoded_data_out[19].d,hw2reg.encoded_data_out[18].d,hw2reg.encoded_data_out[17].d,hw2reg.encoded_data_out[16].d,hw2reg.encoded_data_out[15].d,hw2reg.encoded_data_out[14].d,hw2reg.encoded_data_out[13].d,hw2reg.encoded_data_out[12].d,hw2reg.encoded_data_out[11].d,hw2reg.encoded_data_out[10].d,hw2reg.encoded_data_out[9].d,hw2reg.encoded_data_out[8].d,hw2reg.encoded_data_out[7].d,hw2reg.encoded_data_out[6].d,hw2reg.encoded_data_out[5].d,hw2reg.encoded_data_out[4].d,hw2reg.encoded_data_out[3].d,hw2reg.encoded_data_out[2].d,hw2reg.encoded_data_out[1].d,hw2reg.encoded_data_out[0].d} ),
    .valid                   ( hw2reg.state_signals.valid_bit.d ),
    .ready                   ( hw2reg.state_signals.ready_bit.d ),
    .ready_re                ( hw2reg.state_signals.ready_bit.de ),
    .valid_re                ( hw2reg.state_signals.valid_bit.de ),
    .encoded_data_re         ( {hw2reg.encoded_data_out[49].de,hw2reg.encoded_data_out[48].de,hw2reg.encoded_data_out[47].de,hw2reg.encoded_data_out[46].de,hw2reg.encoded_data_out[45].de,hw2reg.encoded_data_out[44].de,hw2reg.encoded_data_out[43].de,hw2reg.encoded_data_out[42].de,hw2reg.encoded_data_out[41].de,hw2reg.encoded_data_out[40].de,hw2reg.encoded_data_out[39].de,hw2reg.encoded_data_out[38].de,hw2reg.encoded_data_out[37].de,hw2reg.encoded_data_out[36].de,hw2reg.encoded_data_out[35].de,hw2reg.encoded_data_out[34].de,hw2reg.encoded_data_out[33].de,hw2reg.encoded_data_out[32].de,hw2reg.encoded_data_out[31].de,hw2reg.encoded_data_out[30].de,hw2reg.encoded_data_out[29].de,hw2reg.encoded_data_out[28].de,hw2reg.encoded_data_out[27].de,hw2reg.encoded_data_out[26].de,hw2reg.encoded_data_out[25].de,hw2reg.encoded_data_out[24].de,hw2reg.encoded_data_out[23].de,hw2reg.encoded_data_out[22].de,hw2reg.encoded_data_out[21].de,hw2reg.encoded_data_out[20].de,hw2reg.encoded_data_out[19].de,hw2reg.encoded_data_out[18].de,hw2reg.encoded_data_out[17].de,hw2reg.encoded_data_out[16].de,hw2reg.encoded_data_out[15].de,hw2reg.encoded_data_out[14].de,hw2reg.encoded_data_out[13].de,hw2reg.encoded_data_out[12].de,hw2reg.encoded_data_out[11].de,hw2reg.encoded_data_out[10].de,hw2reg.encoded_data_out[9].de,hw2reg.encoded_data_out[8].de,hw2reg.encoded_data_out[7].de,hw2reg.encoded_data_out[6].de,hw2reg.encoded_data_out[5].de,hw2reg.encoded_data_out[4].de,hw2reg.encoded_data_out[3].de,hw2reg.encoded_data_out[2].de,hw2reg.encoded_data_out[1].de,hw2reg.encoded_data_out[0].de} )
);

endmodule

