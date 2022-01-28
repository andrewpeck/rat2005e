//--------------------------------------------------------------------------------------------------------
//
//	Cylon sequence generator
//
//	09/20/05 Initial using ISE 7.1
//	09/20/05 ROM version uses 15 slices, SR version uses 17 slices with MXPRE=4
//
//--------------------------------------------------------------------------------------------------------
	module cylon10 (clock,q);

// Ports
	input 				clock;
	output	[7:0]		q;

// Scale clock down below visual fusion
	parameter MXPRE = 21;	// RAT frequency
//	parameter MXPRE = 19;	// TMB frequency
//	parameter MXPRE = 4;	// Simulation frequency
	reg	[MXPRE-1:0]	prescaler;

	always @(posedge clock) begin
	prescaler = prescaler+1;
	end
 
	wire next = (prescaler == 0);

// Startup wait
	reg [1:0] scnt;

	always @(posedge clock) begin
	if (scnt < 3) scnt=scnt+1;
	end

	wire init = (scnt !=3);

// ROM address run 0 to 13
	reg  [3:0] a;
	wire [7:0] rom;

	always @(posedge clock) begin
	if (init)	a = 0;
	else if (next) begin
	if (a==13)	a = 0;
	else		a = a+1;
	end
	end

	ROM16X1 urom0 (.A0(a[0]),.A1(a[1]),.A2(a[2]),.A3(a[3]),.O(rom[0]));
	ROM16X1 urom1 (.A0(a[0]),.A1(a[1]),.A2(a[2]),.A3(a[3]),.O(rom[1]));
	ROM16X1 urom2 (.A0(a[0]),.A1(a[1]),.A2(a[2]),.A3(a[3]),.O(rom[2]));
	ROM16X1 urom3 (.A0(a[0]),.A1(a[1]),.A2(a[2]),.A3(a[3]),.O(rom[3]));
	ROM16X1 urom4 (.A0(a[0]),.A1(a[1]),.A2(a[2]),.A3(a[3]),.O(rom[4]));
	ROM16X1 urom5 (.A0(a[0]),.A1(a[1]),.A2(a[2]),.A3(a[3]),.O(rom[5]));
	ROM16X1 urom6 (.A0(a[0]),.A1(a[1]),.A2(a[2]),.A3(a[3]),.O(rom[6]));	
	ROM16X1 urom7 (.A0(a[0]),.A1(a[1]),.A2(a[2]),.A3(a[3]),.O(rom[7]));

//                            FEDCBA9876543210
	defparam urom0.INIT = 16'b0100000000000001;
	defparam urom1.INIT = 16'b0010000000000010;
	defparam urom2.INIT = 16'b0001000000000100;
	defparam urom3.INIT = 16'b0000100000001000;
	defparam urom4.INIT = 16'b0000010000010000;
	defparam urom5.INIT = 16'b0000001000100000;
	defparam urom6.INIT = 16'b0000000101000000;
	defparam urom7.INIT = 16'b0000000010000000;

// Buffer output to minimize time to next stage
	reg [7:0] q;

	always @(posedge clock) begin
	q = rom;
	end

	endmodule

