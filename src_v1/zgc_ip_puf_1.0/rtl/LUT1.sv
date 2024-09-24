module LUT1 #(parameter INIT = 2'h0) (
    output O,
    input I0
);

    INVD0BWP40P140HVT u_inv (
        .I(I0),
        .ZN(O)
    );
    // assign O=I0;

endmodule