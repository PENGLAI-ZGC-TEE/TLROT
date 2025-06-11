module pcr_core (
  input                   clk_i,
  input                   rst_ni,
  input        [4:0]      pcr_select_i,
  input        [255:0]    pcr_write_data_i,
  input                   pcr_write_en_i,
  input                   pcr_read_en_i,
  output logic [255:0]    pcr_read_data_o
);

  localparam int NumPcr = 24;

  // PCR storage
  logic [NumPcr-1:0][255:0] pcr_storage;

  logic valid_select;
  assign valid_select = (pcr_select_i < 5'd24);

  // PCR write logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pcr_storage <= '0;
    end else if (pcr_write_en_i && valid_select) begin
      pcr_storage[pcr_select_i] <= pcr_write_data_i;
    end
  end

  // PCR read logic
  always_comb begin
    if (pcr_read_en_i && valid_select) begin
      pcr_read_data_o = pcr_storage[pcr_select_i];
    end else begin
      pcr_read_data_o = '0;
    end
  end

endmodule
