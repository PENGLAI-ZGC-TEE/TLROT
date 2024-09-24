module sigin(data, address);
	input [7:0] address;
	output [7:0] data;
	reg [7:0] data;
	
	// an arbitrary data source here
	always @ (address) data = address + 1;
endmodule

