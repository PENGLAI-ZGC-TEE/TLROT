module RO_Array128 (
    input rst,
    input [127:0] en,
    output [127:0] ro_out
);

parameter  NUM_OSCILLATORS = 128;

genvar i;
  generate
    for (i=0; i < NUM_OSCILLATORS; i=i+1) begin: puf_array
      Single_RO u_ro (
        .en(en[i]),
        .rst(rst),
        .ro_out(ro_out[i])
      );
    end
  endgenerate

endmodule

