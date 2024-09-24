module puf_reg import puf_reg_reg_pkg::*; (
  input                           clk_i,
  input                           rst_ni,

  // Bus interface
  input  tlul_pkg::tl_h2d_t       tl_i,
  output tlul_pkg::tl_d2h_t       tl_o
);

  // Register module instance
  puf_reg_reg2hw_t reg2hw;
  puf_reg_hw2reg_t hw2reg;

  puf_reg_reg_top u_reg (
    .clk_i,
    .rst_ni,
    .tl_i,
    .tl_o,
    .reg2hw,
    .hw2reg,
    .intg_err_o()
  );

  // Signals for puf_reg core
  logic [4:0]   puf_reg_select;
  logic [255:0] puf_reg_write_data;
  logic         puf_reg_write_en;
  logic         puf_reg_read_en;
  logic [255:0] puf_reg_read_data;

  // puf_reg core instance
  puf_reg_core u_puf_reg_core (
    .clk_i,
    .rst_ni,
    .puf_reg_select_i(puf_reg_select),
    .puf_reg_write_data_i(puf_reg_write_data),
    .puf_reg_write_en_i(puf_reg_write_en),
    .puf_reg_read_en_i(puf_reg_read_en),
    .puf_reg_read_data_o(puf_reg_read_data)
  );

  // Connect registers to puf_reg core
  assign puf_reg_select = reg2hw.ctrl.select.q;
  assign puf_reg_write_data = {reg2hw.puf_reg_wr[7].q, reg2hw.puf_reg_wr[6].q, reg2hw.puf_reg_wr[5].q, reg2hw.puf_reg_wr[4].q,
                           reg2hw.puf_reg_wr[3].q, reg2hw.puf_reg_wr[2].q, reg2hw.puf_reg_wr[1].q, reg2hw.puf_reg_wr[0].q};
  assign puf_reg_write_en = reg2hw.ctrl.wr_en.q;
  assign puf_reg_read_en = reg2hw.ctrl.rd_en.q;

  // Connect puf_reg core to registers
  always_comb begin
    for (int i = 0; i < 8; i++) begin
      hw2reg.puf_reg_rd[i].d = puf_reg_read_data[i*32 +: 32];
      hw2reg.puf_reg_rd[i].de = puf_reg_read_en;
    end
  end

endmodule
