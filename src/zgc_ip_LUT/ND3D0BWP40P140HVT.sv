module ND3D0BWP40P140HVT (
    input A1,
    input A2,
    input A3,
    output ZN
);

assign #2 ZN = !(A1 & A2 & A3);
    
endmodule