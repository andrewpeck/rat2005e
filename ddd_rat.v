`timescale 1ns / 1ps
//-----------------------------------------------------------------------------------------------------------
// Programs Data Delay Devices 3D3444 clock delays on power-up
//
//
// 09/26/03	Initial
// 10/03/03 Power_up now comes from vme
// 10/13/03 Enabled all chip outputs
// 12/11/03 Add global reset
// 12/16/03 OE now programmable
// 09/22/05 Mod for ISE 7.1i
// 10/07/05 Copy from bdtest_v5
// 10/17/05 Mod to run with only 1 3d chip
// 11/29/05 Make verify OK go low on startup
//
//-----------------------------------------------------------------------------------------------------------
	module ddd_rat
	(
	clock,
	gbl_reset,
	power_up,
	start,
	autostart_en,
	oe,

	delay_ch0,
	delay_ch1,
	delay_ch2,
	delay_ch3,

	serial_clock,
	serial_out,
	adr_latch,
	serial_in,

	busy,
	verify_ok

// Debug
//	powerup_done,
//	ddd_sm
	);

// I/O Ports
	input			clock;				// Delay chip data clock
	input			gbl_reset;			// Global reset
	input			power_up;			// DLL clock lock, we wait for it
	input			start;				// Cycle start command
	input			autostart_en;		// Enable automatic power-up
	input	[3:0]	oe; 				// Output enables 4'hF=enable all

	input	[3:0]	delay_ch0;			// Channel  0 delay steps
	input	[3:0]	delay_ch1;			// Channel  1 delay steps
	input	[3:0]	delay_ch2;			// Channel  2 delay steps
	input	[3:0]	delay_ch3;			// Channel  3 delay steps

	output			serial_clock;		// 3D3444 clock
	output			serial_out;			// 3D3444 data
	output			adr_latch;			// 3D3444 adr strobe
	input			serial_in;			// 3D3444 verify

	output			busy;				// State machine busy writing
	output			verify_ok;			// Data readback verified OK

// Debug
//	output			powerup_done;
//	output	 [2:0]	ddd_sm;

// Registered outputs
	reg				serial_clock;
	reg				serial_out;
	reg				adr_latch;
	reg				busy;
	reg				verify_ok;

// FFs
	reg				start_ff;

// Local
	wire	[19:0]	tx_bit;

// State Machine declarations
	reg		 [2:0]	ddd_sm;

	parameter wait_fpga		=	3'd0;
	parameter wait_powerup	=	3'd1;
	parameter idle			=	3'd2;
	parameter init			=	3'd3;
	parameter write			=	3'd4;
	parameter latch			=	3'd5;
	parameter verify		=	3'd6;
	parameter unstart		=	3'd7;

	// synthesis attribute safe_implementation of ddd_sm is "yes";
	// synthesis attribute init                of ddd_sm is wait_fpga;

// FF buffer state machine trigger inputs
	always @(posedge clock) begin
	start_ff		<= start;
	end

// Power-up counter, wait for RAT to settle after power-on
	parameter MXPUP = 5;
	reg [MXPUP:0] powerup_cnt;

	always @(posedge clock) begin
	if (ddd_sm == wait_powerup)	powerup_cnt = powerup_cnt + 1;
	else						powerup_cnt = 0;
	end

	wire powerup_done =	powerup_cnt[MXPUP];	// Full count

// Serial data template
	assign	tx_bit[ 0]	= oe[3];			// Output Enables
	assign	tx_bit[ 1]	= oe[2];
	assign	tx_bit[ 2]	= oe[1];
	assign	tx_bit[ 3]	= oe[0];

	assign	tx_bit[ 4]	= delay_ch0[3];		// Delay Channel 0
	assign	tx_bit[ 5]	= delay_ch0[2];
	assign	tx_bit[ 6]	= delay_ch0[1];
	assign	tx_bit[ 7]	= delay_ch0[0];

	assign	tx_bit[ 8]	= delay_ch1[3];		// Delay Channel 1
	assign	tx_bit[ 9]	= delay_ch1[2];
	assign	tx_bit[10]	= delay_ch1[1];
	assign	tx_bit[11]	= delay_ch1[0];

	assign	tx_bit[12]	= delay_ch2[3];		// Delay Channel 2
	assign	tx_bit[13]	= delay_ch2[2];
	assign	tx_bit[14]	= delay_ch2[1];
	assign	tx_bit[15]	= delay_ch2[0];

	assign	tx_bit[16]	= delay_ch3[3];		// Delay Channel 3
	assign	tx_bit[17]	= delay_ch3[2];
	assign	tx_bit[18]	= delay_ch3[1];
	assign	tx_bit[19]	= delay_ch3[0];

// Serial clock runs at 1/2 clock speed to meet 3D4444 set up timing
	reg clock_half;

	always @(posedge clock) begin
	clock_half	= ~clock_half & (ddd_sm == write || ddd_sm == verify);
	end

// Write Serial data counter  
	reg	[4:0] write_cnt;

	wire write_cnt_clr	= !((ddd_sm == write) || (ddd_sm == verify)); 
	wire write_cnt_en	= (clock_half == 1) && ((ddd_sm == write) || (ddd_sm == verify));

	always @(posedge clock) begin
	if		(write_cnt_clr) write_cnt = 0;
	else if	(write_cnt_en ) write_cnt = write_cnt + 1;
	end

	wire write_done	= (write_cnt == 'd19) && (clock_half == 1);
	wire verify_done= (write_cnt == 'd19) && (clock_half == 1);

// Serial data shift register
	reg		[19:0]	shift_reg;
	wire sin = 1'b0;

	wire shift_en	= (clock_half == 1) && ((ddd_sm == write) || (ddd_sm == verify));	// Shift between serial_clock edges
	wire shift_load	= (ddd_sm == init) || (ddd_sm == latch);
 	
	always @(posedge clock) begin
	if		(shift_load) shift_reg = tx_bit[19:0];			// sync load
	else if (shift_en) begin								// shift enable
	shift_reg[19:0] = {sin,shift_reg[19:1]};				// shift right	
	end
	end
	wire	shiftout = shift_reg[0];

// Compare readback to expected data, latches 0 on any error, resets on init
	reg serial_in_ff;
	reg	shiftout_ff0;
	reg shiftout_ff1;
	reg compare;
	reg check_enable;

	always @(posedge clock) begin
	serial_in_ff <= serial_in;
	shiftout_ff0 <= shiftout;
	shiftout_ff1 <= shiftout_ff0;
	check_enable <= (ddd_sm == verify) && (clock_half == 1);
	end

	always @(posedge clock) begin
	if		(ddd_sm == init)compare = 1;
	else if	(check_enable) 	compare = compare & (serial_in_ff == shiftout_ff1);
	end

// Hold adr latch high, serial data out and clock low when not shifting out data, FF'd to remove LUT glitches
	wire sm_init = !power_up;

	always @(posedge clock or posedge sm_init) begin
	if (sm_init) begin
	 serial_clock	<= 1'b0;
	 serial_out		<= 1'b0;
	 adr_latch		<= 1'b1;
	 busy			<= 1'b0;
	end
	else begin
	 serial_clock	<= clock_half;
	 serial_out		<= shiftout & ((ddd_sm == write) || (ddd_sm == verify));
	 adr_latch		<= ~(ddd_sm == latch);
	 busy			<= ddd_sm != idle;
	end
	end

// Verify OK ff, clears on power up, or start, and latchs after readback
	always @(posedge clock or posedge sm_init) begin
	if		(sm_init)			verify_ok <= 1'b0;
	else if (ddd_sm == init)	verify_ok <= 1'b0;
	else if (ddd_sm == unstart)	verify_ok <= compare;
	end

// DDD State machine
	always @(posedge clock) begin
	if(gbl_reset)
	ddd_sm = wait_fpga;
	else begin
	case (ddd_sm)
	
	wait_fpga:										// Wait for FPGA DLLs to lock
	 if (power_up)		ddd_sm = wait_powerup;		// FPGA is ready

	wait_powerup:									// Wait for RAT board to power-up
	 if (powerup_done)								// Board is powered-up
	 begin
	 if (autostart_en)	ddd_sm = init;				// Start cycle if autostart enabled
	 else				ddd_sm = idle;				// Otherwise stay idle
	 end

	idle:											// Wait for JTAG command to program
	 if (start_ff)		ddd_sm = init;				// Start arrived

	init:				ddd_sm = write;				// Initialize

	write:											// Transmit clock and serial data
	 if (write_done)	ddd_sm = latch;				// All data sent

	latch:				ddd_sm = verify;			// Address latch

	verify:											// Read back data
	 if (verify_done)	ddd_sm = unstart;			// All data compared
	
	unstart:
	 if(!start_ff)		ddd_sm = idle;				// Wait for JTAG write command to go away

	default				ddd_sm = wait_fpga;
	endcase
	end
	end

	endmodule

