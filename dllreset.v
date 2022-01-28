//---------------------------------------------------------------------------------------
// Resets DLL if lock has been lost
//
// Per Virtex2/Spartan2E data sheets, the maximum DLL lock time is 120uS.
// If lock is lost longer than this, assert reset for 3 clock cycles.
// Uses external clock because DLL clock may not be running if lock is lost.
//
//---------------------------------------------------------------------------------------
	module dllreset(clock,lock,reset,reset_ff);

	input	clock;		// External clock, not from a DLL
	input	lock;		// Lock status from DLL
	output	reset;		// Reset command to DLL
	output	reset_ff;	// Latched reset indicates at least 1 reset sent

// Count number consequtive clock cycles without lock
	`define N 13		// cnt13 goes high after 8192 cycles, = 205uS

	reg [`N:0]	cnt;
	wire		cnt_done;
	wire		clear;

	always @(posedge clock) begin
	if (clear)	cnt = 0;
	else	 	cnt = cnt+1;
	end

	assign cnt_done	= cnt[`N];

// Fire reset signal for 3 cycles
	reg [3:0]	sr;

	always @(posedge clock) begin
	sr[3:0]	= {sr[2:0],cnt_done};
	end

	assign reset = |sr[3:1];	// Do not FF this, as it will be high at power up, dunno why
	assign clear = |sr[3:0] | cnt_done | lock;

// Latch indicates reset happened at least once
	reg	reset_ff;	// synthesis attribute INIT of reset_ff is "R"

	always @(posedge clock) begin
	reset_ff	<= cnt_done | reset_ff;
	end

	endmodule
