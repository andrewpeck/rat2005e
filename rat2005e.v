//---------------------------------------------------------------------------------------------------------------------
//
//	RAT2005E rev 2.0
//
//	Latch data from 2 RPC cables at 40MHz
//	Multiplex and output to TMB at 80MHz
//	Drive status LEDs
//
//	05/27/03 Initial
//	05/29/03 New io names
//	06/04/03 Interstage clock polarity mux added
//	07/04/03 Add ALCT cable correctness, rear panel LEDs, and rename mux outputs
//	11/06/03 Invert RPC LVDS signals
//	11/07/03 Loopback rpc_rx, add LED signals
//	11/24/03 Mod sync mode to use teven/todd
//	12/02/03 Regroup rpc data at mux input for cleaner decode on TMB side
//	12/03/03 Enable all 4 RPC receiver banks
//	12/03/03 Connect dsn chip to tcrit and posneg
//	04/22/04 Copy from 2003a
//	04/22/04 Add alct_rxmon/txmon LED logic
//	04/23/04 Add jtag status
//	04/28/04 Regroup mux outputs to match TMB demux
//	05/07/04 New sync pattern
//	05/24/04 Mod injector to run full count on sync pulse
//	06/01/04 Add reset if DLL loses lock
//	06/02/04 Update jtag register assignments
//	06/03/04 Mod sync pattern
//	06/15/04 Un-invert RAT inputs per CERN test beam results
//	08/26/04 Tune alct cable led logic
//	08/23/05 Port from RAT2004a, un-invert RPC inputs
//	08/30/05 Use new ucf that swaps rpc0_rx[] with rpc1_rx[]
//	08/31/05 Add slew and speed constraints to output pins for best waveform shape
//	09/07/05 Add jtag register for rpc enables, add pullup for all rpc inputs
//	09/19/05 Port to ISE 7.1 required changes to synthesis attributes, now pass parameters inestead
//	09/19/04 Change rpc_free[1] to rpc_dsn, rpc_free[0] to rpc_free0
//	10/07/05 Add 3D3444 delay chip
//	10/14/05 New pin assignments for rev 2.0 pcb
//	10/17/05 Add jtag tap controller
//	11/29/05 New ddd module
//	11/30/05 Remove rpc2 dll, need the global buffer for 2x clock
//	12/21/05 Fix tap ir
//	01/10/06 Port to ise 8.1i add parity counters
//	01/12/06 Add jtag wr to rd register
//	01/13/06 Stop counters on ovf
//	01/18/06 Add ignore parity errors if data all 0s or all 1s
//	01/18/06 Add rpc data to user1 readout
//	02/01/06 Latch non-inverted rpc data on rising clock edge
//	02/02/06 Blank disabled RPC inputs
//	02/23/06 Change default RPC clock delay to 3 steps per recent CERN tests
//	08/16/06 Move ddd programming into TMB
//	08/17/06 Retained jtag ddd logic, but turned off autostart, allows tmb to write default delays
//	08/18/06 Latch current state of loop/posneg/synch before switching ddd mux
//	08/28/06 Remove sou_ff latching on sync edge
//
//---------------------------------------------------------------------------------------------------------------------
// Firmware version global definitions

	`define VERSION			05'hE		// Version ID
	`define MONTHDAY		16'h0828	// Version date
	`define YEAR			16'h2006	// Version date
//---------------------------------------------------------------------------------------------------------------------

	module rat2005e
	(
// Clocks
	GCLK0,
	GCLK1,
	GCLK2,
	GCLK3,

// 3D3444 Delay IC
	sck,
	sla,
	sin,
	sou,

// JTAG
	tckb,
	tmsb,
	tdib,
	tdob,

// RPC 
	rpc0_rxclock,
	rpc1_rxclock,
	rpc0_rx,
	rpc1_rx,
	rpc0_bxn,
	rpc1_bxn,
	rpc_en,

// TMB
	sync_mode,
	posneg,
	loop,
	rpc_rx,

// ALCT
	alct_txmon,
	alct_rxmon,

// Status
	dsn_io,
	t_crit,	
	rpc_free0,
	rpc_dsn,

// Xilinx dedicated
	D,
	nCS,
	nWRITE,
	BUSY,
	nINIT,

// Unused IOs
	rpc2_rx,
	rpc2_bxn,
	rpc2_rxclock,
	rpc_en2,
	unu
	);
//---------------------------------------------------------------------------------------------------------------------
// Ports
//
//---------------------------------------------------------------------------------------------------------------------
// Clocks
	input			GCLK0;				// 40MHz clock from TMB
	input			GCLK1;				// Not used
	input			GCLK2;				// RPC0 40MHz clock via 3D3444
	input			GCLK3;				// RPC1 40MHz clock via 3D3444

// 3D3444 Delay IC
	output			sck;				// Serial clock to 3D
	output			sla;				// Address latch
	output			sin;				// Serial data to 3D
	input			sou;				// Serial data from 3D

// JTAG
	input			tckb;				// TCK to firmware TAP
	input			tmsb;				// TMS
	input			tdib;				// TDI
	output			tdob;				// TDO

// RPC 
	input			rpc0_rxclock;		// 40MHz clock from RPC 0
	input			rpc1_rxclock;		// 40MHz clock from RPC 1

	input	[15:0]	rpc0_rx;			// Pad data from RPC 0
	input	[15:0]	rpc1_rx;			// Pad data from RPC 1

	input	[2:0]	rpc0_bxn;			// Pad data from RPC 0
	input	[2:0]	rpc1_bxn;			// Pad data from RPC 1

	output	[1:0]	rpc_en;				// Enable RPC LVDS receivers

// TMB
	input			sync_mode;			// 1=80MHz synch mode
	input			posneg;				// 1=Latch 40MHz RPC data on posedge
	input			loop;				// 1=Loopback mode
	output	[37:0]	rpc_rx;				// 80MHz RPC data to TMB

// ALCT
	input			alct_txmon;			// ALCT tx cable monitor
	input			alct_rxmon;			// ALCT rx cable monitor

// Status
	inout			dsn_io;				// Digital serial
	input			t_crit;				// Temperature fault	
	input			rpc_free0;			// Unassigned
	output			rpc_dsn;			// dsn drive to TMB

// Xilinx dedicated
	output	[7:0]	D;					// Front panel LED Array
	output			nCS;				// Misc output
	output			nWRITE;				// Misc output
	output			BUSY;				// Misc output
	output			nINIT; 				// Misc output

// Unused IOs
	input			rpc2_rxclock;		// Clock,    formerly RPC 2
	input	[2:0]	rpc2_bxn;			// Bxn data, formerly RPC 2
	input	[15:0]	rpc2_rx;			// Pad data, formerly RPC 2
	input	[11:0]	unu;				// Not used, formerly RPC 3
	output			rpc_en2;			// Not used, formerly RPC 2

//---------------------------------------------------------------------------------------------------------------------
// Clock DLLs
//
//---------------------------------------------------------------------------------------------------------------------
	wire [3:0] locked;

// Global clock buffers (if you enable the loc attributes, map step fails
	IBUFG ugclk0 (.I(GCLK0),.O(gclk0_ibufg)); //xsynthesis attribute LOC of ugclk0 is "GCLKPAD0"
	IBUFG ugclk1 (.I(GCLK1),.O(gclk1_ibufg)); //xsynthesis attribute LOC of ugclk1 is "GCLKPAD1"
	IBUFG ugclk2 (.I(GCLK2),.O(gclk2_ibufg)); //xsynthesis attribute LOC of ugclk2 is "GCLKPAD2"
	IBUFG ugclk3 (.I(GCLK3),.O(gclk3_ibufg)); //xsynthesis attribute LOC of ugclk3 is "GCLKPAD3"

// GCLK0: DLL0: TMB clock DLL generates clocks at 1x=40MHz, 2x=80MHz
	CLKDLLE udll0
	(	.CLKIN		(gclk0_ibufg),
		.CLKFB		(clock2x),
		.RST		(reset_dll0),
		.CLK0		(gclk0_dll),
		.CLK90		(),
		.CLK180		(),
		.CLK270		(),
		.CLK2X		(clock2x_dll),
		.CLK2X180	(),
		.CLKDV		(),
		.LOCKED		(locked[0])
	);
		// synthesis attribute LOC of udll0 is "DLL0"
		defparam udll0.STARTUP_WAIT = "TRUE";

// GCLK1: DLL1: RPC2 not used
	CLKDLLE udll1
	(	.CLKIN		(clock),
		.CLKFB		(gclk1_ibufg),	// clkfb requires ibufg input
		.RST		(1'b1),
		.CLK0		(rpc_en2),		// clk0 must drive obuf
		.CLK90		(),
		.CLK180		(),
		.CLK270		(),
		.CLK2X		(),
		.CLK2X180	(),
		.CLKDV		(),
		.LOCKED		(locked[1])
	);

// GCLK2: DLL2: RPC0
	CLKDLLE udll2
	(	.CLKIN		(gclk2_ibufg),
		.CLKFB		(clock_rpc0),
		.RST		(reset_dll2),
		.CLK0		(gclk2_dll),
		.CLK90		(),
		.CLK180		(),
		.CLK270		(),
		.CLK2X		(),
		.CLK2X180	(),
		.CLKDV		(),
		.LOCKED		(locked[2])
	);
		// synthesis attribute LOC of udll2 is "DLL2"
		defparam udll2.STARTUP_WAIT = "FALSE"; 

// GCLK3: DLL3: RPC1
	CLKDLLE udll3
	(	.CLKIN		(gclk3_ibufg),
		.CLKFB		(clock_rpc1),
		.RST		(reset_dll3),
		.CLK0		(gclk3_dll),
		.CLK90		(),
		.CLK180		(),
		.CLK270		(),
		.CLK2X		(),
		.CLK2X180	(),
		.CLKDV		(),
		.LOCKED		(locked[3])
	);
		// synthesis attribute LOC of udll3 is "DLL3"
		defparam udll3.STARTUP_WAIT = "FALSE"; 
 
// Global Clock Buffers, limited to 2 per DLL, 2 per chip edge
	BUFG ubufg0 (.I(gclk0_dll  ),.O(clock     ));	// synthesis attribute LOC of ubufg0 is "GCLKBUF0"
	BUFG ubufg1 (.I(clock2x_dll),.O(clock2x   ));	// synthesis attribute LOC of ubufg1 is "GCLKBUF1"
	BUFG ubufg2 (.I(gclk2_dll  ),.O(clock_rpc0));	// synthesis attribute LOC of ubufg2 is "GCLKBUF2"
	BUFG ubufg3 (.I(gclk3_dll  ),.O(clock_rpc1));	// synthesis attribute LOC of ubufg3 is "GCLKBUF3"

// Non-Global Clock buffers prevent compiler from automatic bufg insertion
	IBUF ibuf0 (.I(rpc0_rxclock),.O(clock_rpc0_buf));
	IBUF ibuf1 (.I(rpc1_rxclock),.O(clock_rpc1_buf));

	IBUF ibuf3 (.I(alct_rxmon  ),.O(alct_rxmon_buf));
	IBUF ibuf4 (.I(alct_txmon  ),.O(alct_txmon_buf));

// Reset DLLs if they lose lock
	dllreset udllreset0
	(
	.clock		(gclk0_ibufg),		// In	use non-DLL clock
	.lock		(locked[0]),		// In	lock status from DLL
	.reset		(reset_dll0),		// Out	reset to DLL
	.reset_ff	(reset_dll0_ff)		// Out	latches on if lost lock
	);

	dllreset udllreset2
	(
	.clock		(gclk0_ibufg),		// In	use non-DLL clock
	.lock		(locked[2]),		// In	lock status from DLL
	.reset		(reset_dll2),		// Out	reset to DLL
	.reset_ff	(reset_dll2_ff)		// Out	latches on if lost lock
	);

	dllreset udllreset3
	(
	.clock		(gclk0_ibufg),		// In	use non-DLL clock
	.lock		(locked[3]),		// In	lock status from DLL
	.reset		(reset_dll3),		// Out	reset to DLL
	.reset_ff	(reset_dll3_ff)		// Out	latches on if lost lock
	);

//---------------------------------------------------------------------------------------------------------------------
// Output pin drive strength, speed, and pull
//
//---------------------------------------------------------------------------------------------------------------------
// Output drive strength
	// synthesis attribute drive of rpc_rx		is "4";
	// synthesis attribute drive of dsn_io		is "4";
	// synthesis attribute drive of rpc_dsn		is "4";
	// synthesis attribute drive of D			is "4";
	// synthesis attribute drive of nCS			is "4";
	// synthesis attribute drive of nWRITE		is "4";
	// synthesis attribute drive of BUSY		is "4";
	// synthesis attribute drive of nINIT		is "4";

	// synthesis attribute slew  of rpc_rx		is "FAST";
	// synthesis attribute slew  of dsn_io		is "FAST";
	// synthesis attribute slew  of rpc_dsn		is "FAST";
	// synthesis attribute slew  of D			is "FAST";
	// synthesis attribute slew  of nCS			is "FAST";
	// synthesis attribute slew  of nWRITE		is "FAST";
	// synthesis attribute slew  of BUSY		is "FAST";
	// synthesis attribute slew  of nINIT		is "FAST";

// Input pullups: if LVDS receivers disabled, pull up RPC inputs to prevent float
	// synthesis attribute pullup of rpc0_rxclock is yes;
	// synthesis attribute pullup of rpc0_rx is yes;
	// synthesis attribute pullup of rpc0_bxn is yes;

	// synthesis attribute pullup of rpc1_rxclock is yes;
	// synthesis attribute pullup of rpc1_rx is yes;
	// synthesis attribute pullup of rpc1_bxn is yes;

	// synthesis attribute pullup of rpc2_rxclock is yes;
	// synthesis attribute pullup of rpc2_rx is yes;
	// synthesis attribute pullup of rpc2_bxn is yes;

	// synthesis attribute pullup of gclk1 is yes;
	// synthesis attribute pullup of unu is yes;

//---------------------------------------------------------------------------------------------------------------------
// Power up reset
//
//---------------------------------------------------------------------------------------------------------------------
// Power-up FF goes high after DCM locks
	wire	[3:0]	pdly = 1;	// Power-up reset delay
	wire	powerupq;
	reg		power_up;

	SRL16E upowerup (.CLK(clock),.CE(~power_up),.D(1'b1),.A0(pdly[0]),.A1(pdly[1]),.A2(pdly[2]),.A3(pdly[3]),.Q(powerupq));

	always @(posedge clock) begin
	power_up <= powerupq;
	end

	assign gbl_reset = !power_up;

//---------------------------------------------------------------------------------------------------------------------
// TMB control signal multiplexer
//
//---------------------------------------------------------------------------------------------------------------------
	reg  sck;
	reg  sla;
	reg  sin;
	reg  rpc_dsn;

	reg  msync_mode;
	reg  mposneg;
	reg  mloop;
	wire mrpc_dsn;

 	wire ddd_busy;
	wire dsck;
	wire dsla;
	wire dsin;

	wire ddd_tmb_pgm = rpc_free0;
	
	always @(posedge clock) begin
	if(!ddd_tmb_pgm)			// Latch control signals when TMB not writting to 3D3444
	msync_mode	<= sync_mode;
	mposneg		<= posneg;
	mloop		<= loop;
	end

	always @* begin

	if(ddd_tmb_pgm) begin		// TMB is writing to RATs DDD chip
	sck			= sync_mode;		// Out	Serial clock to 3D
	sla			= posneg;			// Out	Address latch
	sin			= loop;				// Out	Serial data to 3D
	rpc_dsn		= sou;				// In	Serial data from 3D out to TMB
	end
	
	else if (ddd_busy) begin	// RAT is writing to RATs DDD chip
	sck			= dsck;				// Out	Serial clock to 3D
	sla			= dsla;				// Out	Address latch
	sin			= dsin;				// Out	Serial data to 3D
	rpc_dsn		= mrpc_dsn;			// Out	Serial data dsn
	end

	else begin					// And now it's not
	sck			= 0;				// Out	Serial clock to 3D
	sla			= 0;				// Out	Address latch
	sin			= 0;				// Out	Serial data to 3D
	rpc_dsn		= mrpc_dsn;			// Out	Serial data dsn
	end
	end
	
//---------------------------------------------------------------------------------------------------------------------
// RPC Input Latch
//
//---------------------------------------------------------------------------------------------------------------------
// Buffer rpc_en
	reg rpc0_blank;
	reg rpc1_blank;
	
	always @(posedge clock) begin
	rpc0_blank <= ~rpc_en[0];
	rpc1_blank <= ~rpc_en[1];
	end

// IOB FFs latch 40MHz RPC inputs, no data inversion, latch on rising edge
	reg	[15:0]	rpc0_rx_ff;
	reg	[15:0]	rpc1_rx_ff;

	reg [2:0]	rpc0_bxn_ff;
	reg [2:0]	rpc1_bxn_ff;

	always @(posedge clock_rpc0 or posedge rpc0_blank) begin
	if(rpc0_blank) begin
	rpc0_rx_ff	<= 0;
	rpc0_bxn_ff	<= 0;
	end
	else begin
	rpc0_rx_ff	<= rpc0_rx;
	rpc0_bxn_ff	<= rpc0_bxn;
	end
	end

	always @(posedge clock_rpc1 or posedge rpc1_blank) begin
	if(rpc1_blank) begin
	rpc1_rx_ff	<= 0;
	rpc1_bxn_ff	<= 0;
	end
	else begin
	rpc1_rx_ff	<= rpc1_rx;
	rpc1_bxn_ff	<= rpc1_bxn;
	end
	end

// Output Grouping
	wire [37:0] rpc_rxin;

	assign rpc_rxin[18: 0]	= {rpc0_bxn_ff[2:0],rpc0_rx_ff[15:0]};	// rpc0
	assign rpc_rxin[37:19]	= {rpc1_bxn_ff[2:0],rpc1_rx_ff[15:0]};	// rpc1

//---------------------------------------------------------------------------------------------------------------------
// Sync to TMB clock
//
//---------------------------------------------------------------------------------------------------------------------
// Interstage sync to TMB 40MHz clock on both clock edges
	reg  [37:0] rpc_rxin_pos;
	reg  [37:0] rpc_rxin_neg;
	wire [37:0] rpc_rxin_posneg;

	always @(posedge clock) begin
	rpc_rxin_pos <= rpc_rxin;
	end

	always @(negedge clock) begin
	rpc_rxin_neg <= rpc_rxin;
	end

	assign rpc_rxin_posneg = (mposneg) ? rpc_rxin_pos : rpc_rxin_neg;

//---------------------------------------------------------------------------------------------------------------------
// Pattern injector
//
//---------------------------------------------------------------------------------------------------------------------
// Buffer sync_mode for injector and multiplexer
	reg	sync_mode_ff1;
	reg sync_mode_ff2;

	always @(posedge clock) begin
	sync_mode_ff1	<=	msync_mode;
	sync_mode_ff2	<=	sync_mode_ff1;
	end

// Injector state machine
	wire inj_cnt_done;

	reg [1:0] inj_sm;
	parameter idle	= 2'd0;
	parameter fire	= 2'd1;
	parameter hold	= 2'd2;

	// synthesis attribute safe_implementation of inj_sm is "yes";
	// synthesis attribute init                of inj_sm is "idle";

	always @(posedge clock) begin
	if   (gbl_reset)			inj_sm = idle;
	else begin
	case (inj_sm)
	idle:	if (sync_mode_ff1)	inj_sm = fire;
	fire:	if (inj_cnt_done)	inj_sm = hold;
	hold:	if (!sync_mode_ff1)	inj_sm = idle;
	default						inj_sm = idle;
	endcase
	end
	end

	wire inject = (inj_sm == fire);

// tbin counter during inject
	reg [4:0] inj_cnt;

	always @(posedge clock) begin
	if (inject) inj_cnt = inj_cnt+1;
	else		inj_cnt = 0;
	end

	assign inj_cnt_done = (inj_cnt == 5'd31);

// Merge bxn counter with pattern data
	wire [75:0]	inject_data;
	wire [2:0]	inj_bxn = inj_cnt[2:0];

	assign inject_data[18:0]	= {inj_bxn[2:0],16'hBBF1};	// RPC0
	assign inject_data[37:19]	= {inj_bxn[2:0],16'hCCF2};	// RPC1
	assign inject_data[56:38]	= {inj_bxn[2:0],16'hDDF3};	// RPC2 future
	assign inject_data[75:57]	= {inj_bxn[2:0],16'hEEF4};	// RPC3 never

// Insert sync pattern: 
	reg  [75:0] rpc_rxmux;
	wire [75:0] sync_data;

	assign sync_data[18:0]	= 19'h2AAAA;
	assign sync_data[37:19]	= 19'h55555;
	assign sync_data[56:38]	= 19'h55555;
	assign sync_data[75:57]	= 19'h2AAAA;

	always @(posedge clock) begin
	if		(inject)		rpc_rxmux <= inject_data;
	else if (sync_mode_ff2)	rpc_rxmux <= sync_data;
	else					rpc_rxmux <= {~rpc_rxin_posneg,rpc_rxin_posneg};// complement data just occupies time slot
	end

//---------------------------------------------------------------------------------------------------------------------
// Check parity
//
//---------------------------------------------------------------------------------------------------------------------
// Decompose packed data just for clarity
	wire [18:0] rpc0_pdata;
	wire [18:0] rpc1_pdata;
	reg			perr_reset;						// 0=enable parity error counters
	reg			parity_odd;						// 1=use odd parity, 0=use even
	reg			perr_ignore;					// 1=ignore all 0s and all 1s data words
	
	assign rpc0_pdata[18:0] = rpc_rxmux[18:0];	// Includes 16 pad bits + 3 bxn, high bxn is parity
	assign rpc1_pdata[18:0] = rpc_rxmux[37:19];	// Includes 16 pad bits + 3 bxn, high bxn is parity

// Check for all 0s or all 1s data word, in case it is to be ignored
	parameter NDATAB=19;						// Number data bits including parity
	
	wire rpc0_ignore = perr_ignore & ((rpc0_pdata==0) | (rpc0_pdata=={NDATAB{1'b1}}));
	wire rpc1_ignore = perr_ignore & ((rpc1_pdata==0) | (rpc0_pdata=={NDATAB{1'b1}}));

// Calculate parity
	wire rpc0_sum = ^rpc0_pdata[18:0];			// sum of data+parity bit
	wire rpc0_parity_ok = rpc0_sum^!parity_odd;	// ok if sum is odd if odd parity selected or sum is even and even selected

	wire rpc1_sum = ^rpc1_pdata[18:0];			// sum of data+parity bit
	wire rpc1_parity_ok = rpc1_sum^!parity_odd;	// ok if sum is odd if odd parity selected or sum is even and even selected
	
// Increment counters
	parameter NERRB	= 16;
	reg	[NERRB-1:0]	rpc0_cnt_perr;
	reg	[NERRB-1:0]	rpc1_cnt_perr;

	wire novf0 = (rpc0_cnt_perr 	< {NERRB{1'b1}});// Counter overflow disable
	wire novf1 = (rpc1_cnt_perr 	< {NERRB{1'b1}});

	always @(posedge clock) begin
	if (perr_reset | gbl_reset) begin				// clear counters
	rpc0_cnt_perr=0;
	rpc1_cnt_perr=0;
	end
	else begin										// count parity errors
	if (!rpc0_parity_ok && novf0 && !rpc0_ignore) rpc0_cnt_perr=rpc0_cnt_perr+1;
	if (!rpc1_parity_ok && novf1 && !rpc1_ignore) rpc1_cnt_perr=rpc1_cnt_perr+1;
	end
	end

//---------------------------------------------------------------------------------------------------------------------
// RPC Output to TMB
//
//---------------------------------------------------------------------------------------------------------------------
// Loop-back mode: rpc_rx[15:0] becomes input, others remain outputs, for now just z all
	reg nloop;

	always @(posedge clock) begin
	nloop <= !mloop;
	end

	wire rpc_rxoe = nloop;

// Output at 80MHz with TMB clock
	x_mux #(38) umux0
	(
	.din1st		(rpc_rxmux[37: 0]),
	.din2nd		(rpc_rxmux[75:38]),
	.clock1x	(clock),
	.clock2x	(clock2x),
	.dout		(rpc_rx[37:0]),
	.oe			(rpc_rxoe)
	);

//---------------------------------------------------------------------------------------------------------------------
// RPC Status
//
//---------------------------------------------------------------------------------------------------------------------
// RPC clock DLL lock status
	wire [1:0] rpc_dll_active;

	assign rpc_dll_active[0]=locked[2];	// RPC0 DLL locked
	assign rpc_dll_active[1]=locked[3];	// RPC1 DLL locked

// RPC lost lock at least once
	wire [1:0] rpc_lost_lock;

	assign rpc_lost_lock[0]=reset_dll2_ff;	// RPC0 DLL lost lock
	assign rpc_lost_lock[1]=reset_dll3_ff;	// RPC1 DLL lost lock

// RPC non-DLL clock status for LEDs
	reg  [1:0] rpc_clkff;
	reg  [1:0] phase0;
	reg  [1:0] phase1;
	wire [1:0] rpc_clk_active;

	always @(negedge clock_rpc0_buf) begin
	rpc_clkff[0] <= !rpc_clkff[0];
	end

	always @(negedge clock_rpc1_buf) begin
	rpc_clkff[1] <= !rpc_clkff[1];
	end

	always @(posedge clock) begin
	phase0[1:0]	<= rpc_clkff[1:0];
	phase1[1:0]	<= phase0[1:0];
	end

	assign rpc_clk_active[1:0] = phase0[1:0] ^ phase1[1:0];

//---------------------------------------------------------------------------------------------------------------------
// ALCT Status
//
//---------------------------------------------------------------------------------------------------------------------
// ALCT cable status for LEDs: rxmon=0/0=normal, txmon=0/1=normal, rxmon=txmon=1=no cable
	reg [7:0] clockdiv;
	reg [3:0] txmon_cnt;
	reg [15:0] txok_sr;
	reg mon_rst;

	wire txmon_clk =alct_txmon_buf;

	always @(posedge clock) begin							// divide 40MHz clock
	clockdiv=clockdiv+1;
	mon_rst<=clockdiv==0;	  								// reset rxmon/txmon counters
	end

	always @(posedge txmon_clk or posedge mon_rst) begin	// check for txmon toggling
	if(mon_rst)	txmon_cnt = 0;
	else		txmon_cnt = txmon_cnt+1;
	end

	wire txok_s0 = |txmon_cnt;								// expect it mostly non-zero, but not 1/1

	always @(posedge clock) begin							// itegrate to reduce flicker
	txok_sr[15:0]<={txok_sr[14:0],txok_s0};
	end

	wire txok = |txok_sr;
	wire rxok = !alct_rxmon_buf;

//---------------------------------------------------------------------------------------------------------------------
// Front Panel Display
//
//---------------------------------------------------------------------------------------------------------------------
// Front Panel LEDs
//   RPC  1 d1 G G d0  RPC  0
//   STAT 1 d3 G G d2  STAT 0  
//   ALCT A d5 G G d4  ALCT B
//   ERR  A d7 R R d6  ERR  R
//
	reg  [7:0]	led;
	wire [7:0]	cylon_q;
	reg	 [26:0] pup_test_cnt;
	reg	 [27:0]	pup_cylon_cnt;
	reg	 [4:0]	last_opcode;

// Display test all LEDs at power up
	wire pup_test_en=(pup_test_cnt[26]==0);
	always @(posedge clock) begin
	if(pup_test_en)pup_test_cnt = pup_test_cnt+1;
	end

// Display cylon after test
	wire pup_cylon_en=(pup_cylon_cnt[27]==0);
	always @(posedge clock) begin
	if(!pup_test_en) begin	// wait for test display to finish
	if(pup_cylon_en)pup_cylon_cnt = pup_cylon_cnt+1;
	end
	end

	cylon10 ucylon (.clock(clock),.q(cylon_q[7:0]));

	always @(posedge clock) begin
	if(reset_dll0_ff) begin				// Main clock lost lock, bummer
	led[3:0] = |cylon_q[3:0];
	led[7:4] = |cylon_q[7:4];
	end
	else if(pup_test_en) begin			// Turn on all leds at power up
	led[7:0] = 8'hFF;
	end
	else if(mloop | pup_cylon_en) begin	// Cylon mode
	led[7] = cylon_q[0];
	led[5] = cylon_q[1];
	led[3] = cylon_q[2];
	led[1] = cylon_q[3];
	led[0] = cylon_q[4];
	led[2] = cylon_q[5];
	led[4] = cylon_q[6];
	led[6] = cylon_q[7];
	end
	else if (sync_mode_ff1) begin		// TMB sync mode
	led[7] = cylon_q[0];
	led[5] = cylon_q[1];
	led[3] = cylon_q[2];
	led[1] = cylon_q[3];
	led[0] = cylon_q[0];
	led[2] = cylon_q[1];
	led[4] = cylon_q[2];
	led[6] = cylon_q[3];
	end
	else begin							// Normal running with ALCT
	led[0] = rpc_dll_active[0] & ~(rpc_lost_lock[0] & cylon_q[0]);
	led[1] = rpc_dll_active[1] & ~(rpc_lost_lock[1] & cylon_q[1]);
	led[2] = rpc_clk_active[0];
	led[3] = rpc_clk_active[1];
	led[4] = txok;
	led[5] = rxok;
//	led[6] = (rpc_dll_active[0] & rpc_lost_lock[0])|(rpc_dll_active[1] & rpc_lost_lock[1]);
	led[6] = ~(rpc_dll_active[0] | rpc_dll_active[1]);
	led[7] = !(txok & rxok);
	end
	end

//---------------------------------------------------------------------------------------------------------------------
// Digital Serial
//
//---------------------------------------------------------------------------------------------------------------------
// Digital Serial Number shares posneg, and rpc_dsn
	wire dsn_drive;

	assign dsn_drive= mposneg;							// share posneg with dsn driver
	assign dsn_io 	= (dsn_drive) ? 1'bz : dsn_drive;	// dsn chip signal
	assign mrpc_dsn	= dsn_io; 							// dsn output to tmb

//---------------------------------------------------------------------------------------------------------------------
// JTAG Registers
//
//---------------------------------------------------------------------------------------------------------------------
// JTAG declarations
	reg [1:0]	rpc_en;
	reg	[5:0]	rpc_future;

	wire 		ddd_autostart;
	wire		ddd_verify_ok;

	reg			ddd_start;
	reg	[15:0]	ddd_wr;
	reg	[3:0]	dddoe_wr;

// RAT status word for JTAG readout
	wire [223:0] rs;	
	reg	 [223:0] rssr;

	wire [31:0] ws;
	reg  [31:0] wssr;

 	wire [3:0]	version 	= `VERSION;
	wire [15:0]	monthday	= `MONTHDAY;
	wire [15:0]	year		= `YEAR;

	assign rs[3:0]		= 4'hB;						// Begin marker
	assign rs[7:4]		= version[3:0];				// Version ID
	assign rs[23:8]		= monthday[15:0];			// Version date
	assign rs[39:24]	= year[15:0];				// Version date

	assign rs[40]		= sync_mode_ff2;			// 1=80MHz synch mode
	assign rs[41]		= mposneg;					// 1=Latch 40MHz RPC data on posedge
	assign rs[42]		= mloop;					// 1=Loopback mode

	assign rs[44:43]	= rpc_en[1:0];				// RPC driver enables
	assign rs[46:45]	= rpc_clk_active[1:0];		// RPC direct clock status
	assign rs[47]		= locked[0];				// TMB  DLL locked
	assign rs[48]		= locked[2];				// RPC0 DLL locked
	assign rs[49]		= locked[3];				// RPC1 DLL locked
	assign rs[50]		= reset_dll0_ff;			// TMB  DLL lost lock
	assign rs[51]		= rpc_lost_lock[0];			// RPC0 DLL lost lock
	assign rs[52]		= rpc_lost_lock[1];			// RPC1 DLL lost lock
	
	assign rs[53]		= txok;						// ALCT tx cable status
	assign rs[54]		= rxok;						// ALCT rx cable status

	assign rs[55]		= t_crit;					// Over temperature threshold
	assign rs[56]		= rpc_free0;				// rpc_free0 from TMB
	assign rs[57]		= rpc_dsn;					// rpc_dsn to TMB

	assign rs[61:58]	= dddoe_wr[3:0];			// ddd status: output enables
	assign rs[77:62]	= ddd_wr[15:0];				// ddd status: delay valus
	assign rs[78]		= ddd_autostart;			// ddd status: 1=enble start on power-up
	assign rs[79]		= ddd_start;				// ddd status: start ddd machine 
	assign rs[80]		= ddd_busy;					// ddd status: state machine busy writing
	assign rs[81]		= ddd_verify_ok;			// ddd status: data readback verified OK

	assign rs[82]		= rpc0_parity_ok;			// rpc0 parity ok currently
	assign rs[83]		= rpc1_parity_ok;			// rpc1 parity ok currently
	assign rs[99:84]	= rpc0_cnt_perr[15:0];		// rpc0 parity error counter
	assign rs[115:100]	= rpc1_cnt_perr[15:0];		// rpc1 parity error counter

	assign rs[120:116]	= last_opcode[4:0];			// firmware tap cmd opcode
	assign rs[152:121]	= ws[31:0];					// Read back USER2 register
	assign rs[171:153]	= rpc0_pdata[18:0];			// Includes 16 pad bits + 3 bxn, high bxn is parity
	assign rs[190:172]	= rpc1_pdata[18:0];			// Includes 16 pad bits + 3 bxn, high bxn is parity
	assign rs[219:191]	= 0;						// Unused 

	assign rs[223:220]	= 4'hE;						// End marker

// RAT USER1 status shift register for JTAG readout
	wire DRCK1;
	wire SEL1;
	wire SHIFT;
	wire TDI;
	wire TDO1;

	wire ishift1 = SEL1 && SHIFT;
	wire iload1  = !ishift1;

	always @(posedge DRCK1) begin
	if (iload1)	rssr[223:0] = rs[223:0];			// load
	else		rssr[223:0] = {TDI,rssr[223:1]};	// shift
	end

	assign TDO1 = rssr[0];

// RAT USER2 control shift register
	wire DRCK2;
	wire SEL2;
	wire UPDATE;
	wire TDO2;

	wire ishift2 = SEL2 && SHIFT;
	wire iload2  = !ishift2;
	wire update2 = SEL2 && UPDATE;

	always @(posedge DRCK2) begin
	if	(iload2)wssr[31:0] = ws[31:0];			// load
	else		wssr[31:0] = {TDI,wssr[31:1]};	// shift
	end

	assign TDO2 = wssr[0];

// Power-up default delays and channel enables
	wire [1:0]	def_rpc_en;
	wire [3:0]	def_dddoe;
	wire [15:0]	def_ddd;

	assign def_rpc_en[1:0]	= 2'b11;		// 1=enable RPC receiver
	assign ddd_autostart	= 1'b0;			// 1=enble start on power-up
	assign def_dddoe[3:0]	= 4'b0011;		// 1=enable output

	assign def_ddd[3:0]		= 4'd3;			// RPC 0 clock delay
	assign def_ddd[7:4]		= 4'd3;			// RPC 1 clock delay
	assign def_ddd[11:8]	= 4'd0;			// Unused
	assign def_ddd[15:12]	= 4'd0;			// Unused

// RAT USER2 shift register flipflops
	always @(posedge clock) begin		// Load power up defaults
	if (gbl_reset) begin
	rpc_en[1:0]		<= def_rpc_en[1:0];	// rpc[2:0] receiver enables
	ddd_start		<= 1'b0;			// 1=start ddd machine
	ddd_wr[15:0]	<= def_ddd[15:0];	// ddd delay data
	dddoe_wr[3:0]	<= def_dddoe[3:0];	// ddd channel enables
	perr_reset		<= 1'b0;			// 0=enable parity error counters
	parity_odd		<= 1'b1;			// 1=use odd parity, 0=use even
	perr_ignore		<= 1'b0;			// 1=ignore all 0s and all 1s data words
	rpc_future[5:0]	<= 0;				// unassigned
	end
	else if (update2) begin
	rpc_en[1:0]		<= wssr[1:0];		// rpc[1:0] receiver enables
	ddd_start		<= wssr[2];			// 1=start ddd machine
	ddd_wr[15:0]	<= wssr[18:3];		// ddd delay data
	dddoe_wr[3:0]	<= wssr[22:19];		// ddd channel enables
	perr_reset		<= wssr[23];		// 0=enable parity error counters
	parity_odd		<= wssr[24];		// 1=use odd parity, 0=use even
	perr_ignore		<= wssr[25];		// 1=ignore all 0s and all 1s data words
	rpc_future[5:0]	<= wssr[31:26];		// unassigned
	end
	end
	
	assign ws[1:0]	= rpc_en[1:0];
	assign ws[2]	= ddd_start;
	assign ws[18:3] = ddd_wr[15:0];
	assign ws[22:19]= dddoe_wr[3:0];
	assign ws[23]	= perr_reset;
	assign ws[24]	= parity_odd;
	assign ws[25]	= perr_ignore;
	assign ws[31:26]= rpc_future[5:0];

// JTAG Interface, N.B. This Spartan2E uses Virtex BSCAN not SPARTAN2 BSCAN
	BSCAN_VIRTEX ubscan
	(
	.DRCK1	(DRCK1),
	.DRCK2	(DRCK2),
	.RESET	(),
	.SEL1	(SEL1),
	.SEL2	(SEL2),
	.SHIFT	(SHIFT),
	.TDI	(TDI),
	.UPDATE	(UPDATE),
	.TDO1	(TDO1),
	.TDO2	(TDO2)
	);

//---------------------------------------------------------------------------------------------------------------------
// JTAG Tap Controller
//
//---------------------------------------------------------------------------------------------------------------------
	wire [3:0]	state;

	parameter test_logic_reset	=	4'h0;
	parameter run_test_idle		=	4'h1;
	parameter select_dr_scan	=	4'h2;
	parameter capture_dr		=	4'h3;
	parameter shift_dr			=	4'h4;
	parameter exit1_dr			=	4'h5;
	parameter pause_dr			=	4'h6;
	parameter exit2_dr			=	4'h7;
	parameter update_dr			=	4'h8;
	parameter select_ir_scan	=	4'h9;
	parameter capture_ir		=	4'hA;
	parameter shift_ir			=	4'hB;
	parameter exit1_ir			=	4'hC;
	parameter pause_ir			=	4'hD;
	parameter exit2_ir			=	4'hE;
	parameter update_ir			=	4'hF;

	jtag ujtag
	(
	.tck	(tckb),			// In	Test Clock
	.tms	(tmsb),			// In	Test Mode Select
	.tdi	(tdib),			// In	Test Data Input
	.ntrst	(!gbl_reset),	// In	Test Reset, active low
	.tdo	(tdo_ir),		// Out	Test Data Output
	.state	(state[3:0])	// Out	JTAG machine state
	);

	assign tdob = tdo_ir;	// Scope test point

// Instruction & opcode registers
	reg [4:0]	irsr;
	reg [4:0]	opcode;

	wire ishift3 =(state==shift_ir | state==capture_ir);
	wire update3 =(state==update_ir);

	always @(posedge tckb) begin
	if (ishift3) irsr[4:0] <= {tdib,irsr[4:1]};			// shift right
	if (update3) begin
	opcode		<= irsr;								// current  opcode
	last_opcode	<= irsr;								// previous any opcode
//	if (irsr>=5'h10) last_opcode <=irsr;				// previous cmd opcode
 	end
	end

//---------------------------------------------------------------------------------------------------------------------
// 3D3444 Delay Chip
//
//---------------------------------------------------------------------------------------------------------------------
// DDD 3D3444 delay chip programming
	ddd_rat uddd_rat
	(	
	.clock			(clock),			// In	Delay chip data clock
	.gbl_reset		(gbl_reset),		// In	Global reset
	.power_up		(locked[0]),		// In	DCM clock lock, we wait for it
	.start			(ddd_start),		// In	Cycle start command
	.autostart_en	(ddd_autostart),	// In	Enable automatic power-up
	.oe				(dddoe_wr[3:0]), 	// In	Output enables 4'hF=enable all
	.delay_ch0		(ddd_wr[3:0]),		// In	Channel  0 delay steps
	.delay_ch1		(ddd_wr[7:4]),		// In	Channel  0 delay steps
	.delay_ch2		(ddd_wr[11:8]),		// In	Channel  0 delay steps
	.delay_ch3		(ddd_wr[15:12]),	// In	Channel  0 delay steps
	.serial_clock	(dsck),				// Out	3D3444 clock
	.serial_out		(dsin),				// Out	3D3444 data
	.adr_latch		(dsla),				// Out	3D3444 adr strobe
	.serial_in		(sou),				// In	3D3444 verify
	.busy			(ddd_busy),			// Out	State machine busy writing
	.verify_ok		(ddd_verify_ok)		// Out	Data readback verified OK
	);

//---------------------------------------------------------------------------------------------------------------------
// Miscellanea
//
//---------------------------------------------------------------------------------------------------------------------
// Occupy unused IOs
	wire	dummy	= (|rpc2_rx) | (|rpc2_bxn) | (|unu) | rpc2_rxclock | locked[1] | (|opcode);

// Xilinx dedicated
	assign	D[7:0]	= led[7:0];
	assign	nCS		= t_crit;
	assign	nWRITE	= 1'b0;
	assign	BUSY	= !reset_dll0_ff;	 // test point on PCB, high=never lost lock
	assign	nINIT	= dummy;

	endmodule
