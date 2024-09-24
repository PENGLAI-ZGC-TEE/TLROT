module rsdec_berl_multiply (y, a, b, c, d, e);
	input [7:0] a, b, c, d;
	input e;
	output [7:0] y;
	wire [7:0] y;
	reg [7:0] p, q;

	always @ (a or c or e)
		if (e) p = c;
		else p = a;
	always @ (b or d or e)
		if (e) q = d;
		else q = b;

	multiply x0 (y, p, q);

endmodule

