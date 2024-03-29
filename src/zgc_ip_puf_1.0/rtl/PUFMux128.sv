
module PUFMux128 (
input [127:0] i_D,
input [6:0] i_Sel,
output reg o_Q
);

always @(*) begin
	case(i_Sel)
		7'b0000000: o_Q = i_D[0];
		7'b0000001: o_Q = i_D[1];
		7'b0000010: o_Q = i_D[2];
		7'b0000011: o_Q = i_D[3];
		7'b0000100: o_Q = i_D[4];
		7'b0000101: o_Q = i_D[5];
		7'b0000110: o_Q = i_D[6];
		7'b0000111: o_Q = i_D[7];
		7'b0001000: o_Q = i_D[8];
		7'b0001001: o_Q = i_D[9];
		7'b0001010: o_Q = i_D[10];
		7'b0001011: o_Q = i_D[11];
		7'b0001100: o_Q = i_D[12];
		7'b0001101: o_Q = i_D[13];
		7'b0001110: o_Q = i_D[14];
		7'b0001111: o_Q = i_D[15];
		7'b0010000: o_Q = i_D[16];
		7'b0010001: o_Q = i_D[17];
		7'b0010010: o_Q = i_D[18];
		7'b0010011: o_Q = i_D[19];
		7'b0010100: o_Q = i_D[20];
		7'b0010101: o_Q = i_D[21];
		7'b0010110: o_Q = i_D[22];
		7'b0010111: o_Q = i_D[23];
		7'b0011000: o_Q = i_D[24];
		7'b0011001: o_Q = i_D[25];
		7'b0011010: o_Q = i_D[26];
		7'b0011011: o_Q = i_D[27];
		7'b0011100: o_Q = i_D[28];
		7'b0011101: o_Q = i_D[29];
		7'b0011110: o_Q = i_D[30];
		7'b0011111: o_Q = i_D[31];
		7'b0100000: o_Q = i_D[32];
		7'b0100001: o_Q = i_D[33];
		7'b0100010: o_Q = i_D[34];
		7'b0100011: o_Q = i_D[35];
		7'b0100100: o_Q = i_D[36];
		7'b0100101: o_Q = i_D[37];
		7'b0100110: o_Q = i_D[38];
		7'b0100111: o_Q = i_D[39];
		7'b0101000: o_Q = i_D[40];
		7'b0101001: o_Q = i_D[41];
		7'b0101010: o_Q = i_D[42];
		7'b0101011: o_Q = i_D[43];
		7'b0101100: o_Q = i_D[44];
		7'b0101101: o_Q = i_D[45];
		7'b0101110: o_Q = i_D[46];
		7'b0101111: o_Q = i_D[47];
		7'b0110000: o_Q = i_D[48];
		7'b0110001: o_Q = i_D[49];
		7'b0110010: o_Q = i_D[50];
		7'b0110011: o_Q = i_D[51];
		7'b0110100: o_Q = i_D[52];
		7'b0110101: o_Q = i_D[53];
		7'b0110110: o_Q = i_D[54];
		7'b0110111: o_Q = i_D[55];
		7'b0111000: o_Q = i_D[56];
		7'b0111001: o_Q = i_D[57];
		7'b0111010: o_Q = i_D[58];
		7'b0111011: o_Q = i_D[59];
		7'b0111100: o_Q = i_D[60];
		7'b0111101: o_Q = i_D[61];
		7'b0111110: o_Q = i_D[62];
		7'b0111111: o_Q = i_D[63];
		7'b1000000: o_Q = i_D[64];
		7'b1000001: o_Q = i_D[65];
		7'b1000010: o_Q = i_D[66];
		7'b1000011: o_Q = i_D[67];
		7'b1000100: o_Q = i_D[68];
		7'b1000101: o_Q = i_D[69];
		7'b1000110: o_Q = i_D[70];
		7'b1000111: o_Q = i_D[71];
		7'b1001000: o_Q = i_D[72];
		7'b1001001: o_Q = i_D[73];
		7'b1001010: o_Q = i_D[74];
		7'b1001011: o_Q = i_D[75];
		7'b1001100: o_Q = i_D[76];
		7'b1001101: o_Q = i_D[77];
		7'b1001110: o_Q = i_D[78];
		7'b1001111: o_Q = i_D[79];
		7'b1010000: o_Q = i_D[80];
		7'b1010001: o_Q = i_D[81];
		7'b1010010: o_Q = i_D[82];
		7'b1010011: o_Q = i_D[83];
		7'b1010100: o_Q = i_D[84];
		7'b1010101: o_Q = i_D[85];
		7'b1010110: o_Q = i_D[86];
		7'b1010111: o_Q = i_D[87];
		7'b1011000: o_Q = i_D[88];
		7'b1011001: o_Q = i_D[89];
		7'b1011010: o_Q = i_D[90];
		7'b1011011: o_Q = i_D[91];
		7'b1011100: o_Q = i_D[92];
		7'b1011101: o_Q = i_D[93];
		7'b1011110: o_Q = i_D[94];
		7'b1011111: o_Q = i_D[95];
		7'b1100000: o_Q = i_D[96];
		7'b1100001: o_Q = i_D[97];
		7'b1100010: o_Q = i_D[98];
		7'b1100011: o_Q = i_D[99];
		7'b1100100: o_Q = i_D[100];
		7'b1100101: o_Q = i_D[101];
		7'b1100110: o_Q = i_D[102];
		7'b1100111: o_Q = i_D[103];
		7'b1101000: o_Q = i_D[104];
		7'b1101001: o_Q = i_D[105];
		7'b1101010: o_Q = i_D[106];
		7'b1101011: o_Q = i_D[107];
		7'b1101100: o_Q = i_D[108];
		7'b1101101: o_Q = i_D[109];
		7'b1101110: o_Q = i_D[110];
		7'b1101111: o_Q = i_D[111];
		7'b1110000: o_Q = i_D[112];
		7'b1110001: o_Q = i_D[113];
		7'b1110010: o_Q = i_D[114];
		7'b1110011: o_Q = i_D[115];
		7'b1110100: o_Q = i_D[116];
		7'b1110101: o_Q = i_D[117];
		7'b1110110: o_Q = i_D[118];
		7'b1110111: o_Q = i_D[119];
		7'b1111000: o_Q = i_D[120];
		7'b1111001: o_Q = i_D[121];
		7'b1111010: o_Q = i_D[122];
		7'b1111011: o_Q = i_D[123];
		7'b1111100: o_Q = i_D[124];
		7'b1111101: o_Q = i_D[125];
		7'b1111110: o_Q = i_D[126];
		default: o_Q = i_D[127];
	endcase
end

endmodule

