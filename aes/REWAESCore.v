
//==============================================================================
//	Section:	Includes
//==============================================================================
`include "Const.vh"
//==============================================================================

//==============================================================================
//	Module:		REWAESCore
//	Desc:		Control wrapper for Tiny AES in an REW ORAM design.
//				Input: RO/RW mask commands (in separate buffers).
//				Output: RO/RW masks (in order and in separate buffers).
//				
//				This module is meant to be clocked as fast as possible 
//				(e.g., 300 Mhz).
//
//	Notes on getting clock up:
//		- No reset to any module
//		- Size FIFOs smaller to use smaller data counts
//		- Disable FIFO reset
//==============================================================================
module REWAESCore(
	SlowClock, FastClock, 
	SlowReset,

	ROIVIn, ROBIDIn, ROCommandIn, ROCommandInValid, ROCommandInReady,
	RWIVIn, RWBIDIn, RWCommandInValid, RWCommandInReady,
	
	RODataOut, ROCommandOut, RODataOutValid, RODataOutReady,
	RWDataOut, RWDataOutValid, RWDataOutReady
	);

	//--------------------------------------------------------------------------
	//	Parameters & Constants
	//--------------------------------------------------------------------------

	`include "REWAES.vh";

	`include "REWAESLocal.vh"
	
	pass: EnableIV
	
	parameter				ROWidth =				128, // Width of RO input/output interface
							RWWidth =				512, // "" RW interface (should match DDRDWidth)
							BIDWidth =				34, // BucketID field width
							CIDWidth =				5, // ChunkID field width
							AESWidth =				128;	
	
	localparam				AESLatency =			21; // based on tiny_aes + external buffer we add; Note: the outer module can be oblivious to this
	
	//--------------------------------------------------------------------------
	//	System I/O
	//--------------------------------------------------------------------------
		
  	input 					SlowClock, FastClock, SlowReset;
	
	//--------------------------------------------------------------------------
	//	Input Interfaces
	//--------------------------------------------------------------------------

	//--------------------------------------------------------------------------
	//	Output Interfaces
	//--------------------------------------------------------------------------

	//--------------------------------------------------------------------------
	//	Wires & Regs
	//--------------------------------------------------------------------------
	
	// RO input interface
	
	// RW input interface
	
	// AES core
	
	wire	[AESUWidth-1:0]	CoreKey;
		
	wire	[DWidth-1:0]	CoreDataIn, CoreDataOut;
	wire					CoreDataInValid, CoreDataOutValid;
	
	wire	[ACCMDWidth-1:0] CoreCommandIn, CoreCommandOut;
	
	// Output interfaces
	
	wire					CommandOutIsRO, CommandOutIsRW;
	
	wire	[RWWidth-1:0]	MaskFIFODataIn;
	wire					MaskFIFODataInValid, MaskFIFOFull;
	
	wire					ROFIFOFull;

	//--------------------------------------------------------------------------
	//	Simulation Checks
	//--------------------------------------------------------------------------
		
	`ifdef SIMULATION
		initial begin
			if ((IVEntropyWidth + BIDWidth + PCCMDWidth) > 108) begin
				$display("[%m @ %t] ERROR: Data is too wide for ro_I_fifo.", $time);
				$stop;
			end
			
			if ((AESWidth + PCCMDWidth) > 144) begin
				$display("[%m @ %t] ERROR: Data is too wide for ro_O_fifo.", $time);
				$stop;
			end
			
			if (AESWidth != 128) begin
				$display("[%m @ %t] ERROR: width not supported.", $time);
				$stop;
			end
			
			if (RWWidth != 512) begin
				$display("[%m @ %t] ERROR: you need to re-generate the REWMaskFIFO to change this width.", $time);
				$stop;
			end
		end
		
		always @(posedge FastClock) begin
			if (ROFIFOFull & CommandOutIsRO) begin
				$display("[%m @ %t] ERROR: AES RO out fifo overflow.", $time);
				$stop;
			end
			 
			if (MaskFIFOFull & MaskFIFODataInValid) begin
				$display("[%m @ %t] ERROR: AES RW out fifo overflow.", $time);
				$stop;
			end			
		end
	`endif
	
	//--------------------------------------------------------------------------
	//	Key Management
	//--------------------------------------------------------------------------
	
	// TODO: Set it to something dynamic [this is actually important to get correct area numbers ...]
	assign	CoreKey =								{AESUWidth{1'b1}}; 
	
	//--------------------------------------------------------------------------
	//	RO Input Interface
	//--------------------------------------------------------------------------

	// Note: We split the input buffers so RW commands don't head of line block
	// RO commands.  
	
	assign	ROCommandInReady =						~ROCommandFull;
	AESSeedFIFO ro_I_fifo(	.rst(					SlowReset),
							.wr_clk(				SlowClock), 
							.rd_clk(				FastClock), 
							.din(					{ROIVIn, 	ROBIDIn, 	ROCommandIn}), 
							.wr_en(					ROCommandInValid),
							.full(					ROCommandFull), 							
							.dout(					{ROIV_Fifo, ROBID_Fifo, ROCommand_Fifo}), 
							.rd_en(					ROReady_Fifo), 
							.valid(					ROValid_Fifo));

	FIFORegister #(			.Width(					IVEntropyWidth + BIDWidth + PCCMDWidth),
							.Initial(				0),
							.InitialValid(			0))
				ro_state(	.Clock(					FastClock),
							.Reset(					1'b0),
							.InData(				{ROIV_Fifo, ROBID_Fifo, ROCommand_Fifo}),
							.InValid(				ROValid_Fifo),
							.InAccept(				ROReady_Fifo),
							.OutData(				{ROIV, ROBID, ROCommand}),
							.OutSend(				ROValid),
							.OutReady(				ROReady));
							
	assign	ROReady =								(ROCommand == PCMD_ROHeader) ? ROHeaderCID_Terminal : RODataCID_Terminal;
							
	Counter		#(			.Width(					CIDWidth),
							.Initial(				0))
				ro_cid(		.Clock(					FastClock),
							.Reset(					ROReady),
							.Set(					1'b0),
							.Load(					1'b0),
							.Enable(				ROValid),
							.In(					{CIDWidth{1'bx}}),
							.Count(					ROCID));		
	CountCompare #(			.Width(					CIDWidth),
							.Compare(				ROHeader_AESChunks))
				ro_H_stop(	.Count(					ROCID),
							.TerminalCount(			ROHeaderCID_Terminal));
	generate if (EnableIV) begin:DECRYPT_BKT				
		CountCompare #(		.Width(					CIDWidth),
							.Compare(				RWBkt_AESChunks))
				ro_D_stop(	.Count(					ROCID),
							.TerminalCount(			RODataCID_Terminal));			
	end else begin:DECRYPT_BLK
		CountCompare #(		.Width(					CIDWidth),
							.Compare(				RWBlk_AESChunks))
				ro_D_stop(	.Count(					ROCID),
							.TerminalCount(			RODataCID_Terminal));								
	end endgenerate
	
	assign	ROSeed =								{{SeedSpaceRemaining{1'b0}}, ROIV, ROBID, ROCID};
	
	//--------------------------------------------------------------------------
	//	RW Input Interface
	//--------------------------------------------------------------------------	
	
	RWSeed
	
	RWCommandFull
	
	RWValid
	
	assign	RWCommandInReady =						~RWCommandFull;
	AESSeedFIFO rw_I_fifo(	.rst(					SlowReset),
							.wr_clk(				SlowClock), 
							.rd_clk(				FastClock), 
							.din(					{RWIVIn, RWBIDIn}), 
							.wr_en(					RWCommandInValid),
							.full(					RWCommandFull), 						
							.rd_en(					), 
							.dout(					), 
							.valid(					));							
	
	Counter		#(			.Width(					)) Initial
				rw_cid(		.Clock(					),
							.Reset(					),
							.Set(					1'b0),
							.Load(					1'b0),
							.Enable(				),
							.In(					{{1'bx}}),
							.Count(					));
	CountCompare #(			.Width(					),
							.Compare(				))
				rw_stop(	.Count(					),
							.TerminalCount(			));
	
	//--------------------------------------------------------------------------
	//	Tiny AES Core
	//--------------------------------------------------------------------------
	
	assign	CoreDataIn =							(ROValid) ? ROSeed : RWSeed;
	assign	CoreDataInValid = 						ROValid | RWValid;
	assign	CoreCommandIn =							(ROValid) ? {1'b0, ROCommand} : CMD_RWData;
	
	aes_128 tiny_aes(		.clk(					FastClock),
							.state(					CoreDataIn), 
							.key(					CoreKey), 
							.out(					CoreDataOut));
							
	ShiftRegister #(		.PWidth(				AESLatency),
							.SWidth(				1 + ACCMDWidth),
							.Initial(				{AESLatency{1'b0}})
				V_shift(	.Clock(					FastClock), 
							.Reset(					1'b0), 
							.Load(					1'b0), 
							.Enable(				1'b1),
							.SIn(					{CoreDataInValid, 	CoreCommandIn}),
							.SOut(					{CoreDataOutValid, 	CoreCommandOut}));						
	
	assign	CommandOutIsRW =						CoreDataOutValid & CoreCommandOut[ACMDRWBit] == CMD_RWData[ACMDRWBit];
	assign	CommandOutIsRO =						CoreDataOutValid & CoreCommandOut[ACMDRWBit] != CMD_RWData[ACMDRWBit];
	
	//--------------------------------------------------------------------------
	//	RW Output Interface
	//--------------------------------------------------------------------------
	
	// Note: we need to shift this in the fast clock domain or there is no point 
	// in clocking this module fast.
	
	CountAlarm #(			.Threshold(				BlkSize_AESChunks),
							.Initial(				0))
				rw_shft_cnt(.Clock(					FastClock), 
							.Reset(					1'b0), 
							.Enable(				CommandOutIsRW),
							.Done(					MaskFIFODataInValid));	
	
	ShiftRegister #(		.PWidth(				RWWidth),
							.SWidth(				AESWidth),
							.Initial(				{RWWidth{1'b0}})
				rw_shift(	.Clock(					FastClock), 
							.Reset(					1'b0), 
							.Load(					1'b0), 
							.Enable(				CommandOutIsRW),
							.SIn(					CoreDataOut),
							.POut(					MaskFIFODataIn));
	
	REWMaskFIFO rw_O_fifo(	.rst(					SlowReset), 
							.wr_clk(				FastClock), 
							.rd_clk(				SlowClock), 
							.din(					MaskFIFODataIn), 
							.wr_en(					MaskFIFODataInValid), 
							.full(					MaskFIFOFull),
							.dout(					RWDataOut),
							.rd_en(					RWDataOutReady),
							.valid(					RWDataOutValid))
	
	//--------------------------------------------------------------------------
	//	RO Output Interface
	//--------------------------------------------------------------------------
	
	// Note: we use a single FIFO for all RO stuff (header masks, data of 
	// interest) so save on the routing / area cost of a second FIFO.  Adding 
	// the command bit here adds 0 additional logic since we just use the BRAM 
	// ECC bits.

	AESROFIFO 	ro_O_fifo(	.rst(					SlowReset),
							.wr_clk(				FastClock), 
							.rd_clk(				SlowClock), 
							.din(					{CoreDataOut,	CoreCommandOut[ACMDROBit]}), 
							.wr_en(					CommandOutIsRO),
							.full(					ROFIFOFull),
							.dout(					{RODataOut,		ROCommandOut}),
							.rd_en(					RODataOutReady),  
							.valid(					RODataOutValid));

	//--------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
