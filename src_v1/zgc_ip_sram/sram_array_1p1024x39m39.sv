module sram_array_1p1024x39m39(
  input logic         clk_i,
  input logic [9:0]   addr_i,
  input logic         req_i,
  input logic         write_i,
  input logic         wmask_i,
  input logic [38:0] wdata_i,
  output logic [38:0] rdata_o
);

localparam Width = 39;
localparam DataBitsPerMask = 39;
localparam MaskWidth = 1;

logic [Width-1:0]     mem [1024];
// logic [MaskWidth-1:0] wmask;

 always @(posedge clk_i) begin
    if (req_i) begin
      if (write_i) begin
        for (int i=0; i < MaskWidth; i = i + 1) begin
          if (wmask_i) begin
            mem[addr_i][i*DataBitsPerMask +: DataBitsPerMask] <=
              wdata_i[i*DataBitsPerMask +: DataBitsPerMask];
          end
        end
      end else begin
        rdata_o <= mem[addr_i];
      end
    end
 end

endmodule