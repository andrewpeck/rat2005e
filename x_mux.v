//-------------------------------------------------------------------------------------------------------------------------------------
//
// 80 MHz multiplexer module
//
//-------------------------------------------------------------------------------------------------------------------------------------
	module x_mux(din1st,din2nd,clock1x,clock2x,dout,oe);
	parameter WIDTH = 1;

	input	[WIDTH-1:0]	din1st;
	input	[WIDTH-1:0]	din2nd;
	input				clock1x;
	input				clock2x;
	input				oe;
	output	[WIDTH-1:0]	dout;

// Local
	reg		[WIDTH-1:0]	din2nd_ff;
	wire	[WIDTH-1:0]	dout_mux;
	reg		[WIDTH-1:0]	dout;

// Latch second time slice to a holding FF FDCPE so dout will be aligned with 40MHz clock
	always @(posedge clock1x) begin
	din2nd_ff <= din2nd;
	end

// Mux selects 1st time slice then 2nd slice
	assign dout_mux[WIDTH-1:0] = (~clock1x) ? din1st[WIDTH-1:0] : din2nd_ff[WIDTH-1:0];

// Latch 80 MHz multiplexed outputs in FDCE IOB FFs
	always @(posedge clock2x) begin
	if(oe)	dout <= dout_mux;
	else	dout <= {WIDTH{1'bz}};
	end

	endmodule
