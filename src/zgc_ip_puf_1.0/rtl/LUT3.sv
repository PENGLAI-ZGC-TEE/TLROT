module LUT3 #(parameter INIT = 8'h00) (
    output O,
    input I0,
    input I1,
    input I2
);

    ND3D0BWP40P140HVT u_nand3 (
        .ZN(O),
        .A1(I0),
        .A2(I1),
        .A3(I2)
    );

endmodule