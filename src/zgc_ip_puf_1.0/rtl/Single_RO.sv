module Single_RO (
    input en,
    input rst,
    output ro_out
);
    parameter NUM_LUTS = 15;
    wire [NUM_LUTS-1:0] ca;

    BUFFD0BWP40P140HVT LUT_en (
        .I(en),
        .Z(en_buf)
    );

    BUFFD0BWP40P140HVT LUT_rst (
        .I(rst),
        .Z(rst_buf)
    );

    ND3D0BWP40P140HVT LUT_init (
        .ZN(ca[0]),
        .A1(en_buf),
        .A2(rst_buf),
        .A3(ca[NUM_LUTS-1])
      );

    //   assign #2 ca[0] = !(ena[i] & rst & ca[NUM_LUTS-1]);

      genvar j;
      for (j=1; j < NUM_LUTS; j=j+1) begin: LUT_chain
        INVD0BWP40P140HVT LUT (
          .ZN(ca[j]),
          .I(ca[j-1])
        );
      end

      INVD0BWP40P140HVT LUT_last (
        .ZN(ro_out),
        .I(ca[NUM_LUTS-3]) 
      );

endmodule