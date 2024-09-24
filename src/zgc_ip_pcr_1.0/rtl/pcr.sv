module pcr import pcr_reg_pkg::*; (
  input                           clk_i,
  input                           rst_ni,

  // Bus interface
  input  tlul_pkg::tl_h2d_t       tl_i,
  output tlul_pkg::tl_d2h_t       tl_o
);

  // Register module instance
  pcr_reg2hw_t reg2hw;
  pcr_hw2reg_t hw2reg;

  pcr_reg_top u_reg (
    .clk_i,
    .rst_ni,
    .tl_i,
    .tl_o,
    .reg2hw,
    .hw2reg,
    .intg_err_o()
  );

  // Signals for PCR core
  logic [4:0]   pcr_select;
  logic [255:0] pcr_write_data;
  logic         pcr_write_en;
  logic         pcr_read_en;
  logic [255:0] pcr_read_data;

  // PCR core instance
  pcr_core u_pcr_core (
    .clk_i,
    .rst_ni,
    .pcr_select_i(pcr_select),
    .pcr_write_data_i(pcr_write_data),
    .pcr_write_en_i(pcr_write_en),
    .pcr_read_en_i(pcr_read_en),
    .pcr_read_data_o(pcr_read_data)
  );

  // Connect registers to PCR core
  assign pcr_select = reg2hw.ctrl.select.q;
  assign pcr_write_data = {reg2hw.pcr_wr[7].q, reg2hw.pcr_wr[6].q, reg2hw.pcr_wr[5].q, reg2hw.pcr_wr[4].q,
                           reg2hw.pcr_wr[3].q, reg2hw.pcr_wr[2].q, reg2hw.pcr_wr[1].q, reg2hw.pcr_wr[0].q};
  assign pcr_write_en = reg2hw.ctrl.wr_en.q;
  assign pcr_read_en = reg2hw.ctrl.rd_en.q;

  // Connect PCR core to registers
  always_comb begin
    for (int i = 0; i < 8; i++) begin
      hw2reg.pcr_rd[i].d = pcr_read_data[i*32 +: 32];
      hw2reg.pcr_rd[i].de = pcr_read_en;
    end
  end

endmodule
