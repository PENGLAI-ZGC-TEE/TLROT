module puf_reg_core (
  input                   clk_i,
  input                   rst_ni,
  input        [4:0]      puf_reg_select_i,
  input        [255:0]    puf_reg_write_data_i,
  input                   puf_reg_write_en_i,
  input                   puf_reg_read_en_i,
  output logic [255:0]    puf_reg_read_data_o
);

  localparam int NumReg = 8;

  // puf_reg storage
  logic [NumReg-1:0][255:0] puf_reg_storage;

  // puf_reg write logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      puf_reg_storage <= '0;
    end else if (puf_reg_write_en_i) begin
      puf_reg_storage[puf_reg_select_i] <= puf_reg_write_data_i;
    end
  end

  // puf_reg read logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      puf_reg_read_data_o <= '0;
    end else if (puf_reg_read_en_i) begin
      puf_reg_read_data_o <= puf_reg_storage[puf_reg_select_i];
    end
  end

endmodule
