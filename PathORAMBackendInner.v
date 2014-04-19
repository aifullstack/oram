
//==============================================================================
//	Section:	Includes
//==============================================================================
`include "Const.vh"
//==============================================================================

//==============================================================================
//	Module:		PathORAMBackendInner
//	Desc:		Stash, DRAM address and top level state machine that interfaces 
//				with the FrontEnd
//==============================================================================
module PathORAMBackendInner(
	Clock, Reset,

	Command, PAddr, CurrentLeaf, RemappedLeaf, 
	CommandValid, CommandReady,

	LoadData, 
	LoadValid, LoadReady,

	StoreData,
	StoreValid, StoreReady,
	
	DRAMCommandAddress, DRAMCommand, DRAMCommandValid, DRAMCommandReady,
	DRAMReadData, DRAMReadDataValid, DRAMReadDataReady,
	DRAMWriteData, DRAMWriteDataValid, DRAMWriteDataReady,

	ROPAddr, ROLeaf, REWRoundDummy, 
	
	DRAMInitComplete
	);
		
	//------------------------------------------------------------------------------
	//	Parameters & Constants
	//------------------------------------------------------------------------------

	`include "PathORAM.vh";
	`include "DDR3SDRAM.vh";
	`include "AES.vh";
	`include "Stash.vh";
	
	`include "StashLocal.vh"
	`include "DDR3SDRAMLocal.vh"
	`include "BucketLocal.vh"
	`include "BucketDRAMLocal.vh"
	`include "PathORAMBackendLocal.vh"
	
	localparam				SpaceRemaining =		BktHSize_RndBits - BktHSize_RawBits;
	
	localparam				STWidth =				3,
							ST_Initialize =			3'd0,
							ST_Idle =				3'd1,
							ST_Append =				3'd2,
							ST_StartRead =			3'd3,
							ST_PathRead =			3'd4,
							ST_StartWriteback =		3'd5,
							ST_PathWriteback =		3'd6;
								
	localparam				PRNGLWidth =			`divceil(ORAML, 8) * 8;
	
	//--------------------------------------------------------------------------
	//	System I/O
	//--------------------------------------------------------------------------
		
  	input 					Clock, Reset;
	
	//--------------------------------------------------------------------------
	//	Frontend Interface
	//--------------------------------------------------------------------------

	input	[BECMDWidth-1:0] Command;
	input	[ORAMU-1:0]		PAddr;
	input	[ORAML-1:0]		CurrentLeaf; // If Command == Append, this is XX 
	input	[ORAML-1:0]		RemappedLeaf;
	input					CommandValid;
	output 					CommandReady;

	// TODO set CommandReady = 0 if LoadDataReady = 0 (i.e., the front end can't take our result!)
	
	output	[FEDWidth-1:0]	LoadData;
	output					LoadValid;
	input 					LoadReady;

	input	[FEDWidth-1:0]	StoreData;
	input 					StoreValid;
	output 					StoreReady;
	
	//--------------------------------------------------------------------------
	//	DRAM Interface
	//--------------------------------------------------------------------------

	output	[DDRAWidth-1:0]	DRAMCommandAddress;
	output	[DDRCWidth-1:0]	DRAMCommand;
	output					DRAMCommandValid;
	input					DRAMCommandReady;
	
	input	[DDRDWidth-1:0]	DRAMReadData;
	input					DRAMReadDataValid;
	output					DRAMReadDataReady;
	
	output	[DDRDWidth-1:0]	DRAMWriteData;
	output					DRAMWriteDataValid;
	input					DRAMWriteDataReady;

	//--------------------------------------------------------------------------
	//	REW Interface
	//--------------------------------------------------------------------------
	
	output reg [ORAMU-1:0]	ROPAddr;
	output reg [ORAML-1:0]	ROLeaf;
	output reg				REWRoundDummy;
	
	//--------------------------------------------------------------------------
	//	Status Interface
	//--------------------------------------------------------------------------

	output					DRAMInitComplete;
								
	//--------------------------------------------------------------------------
	//	Wires & Regs
	//-------------------------------------------------------------------------- 

	// Control logic
	
	wire					AllResetsDone;
	reg		[STWidth-1:0]	CS, NS;
	wire					CSInitialize, CSIdle, CSAppend, CSStartRead, CSPathRead, CSPathWriteback, 
							CSStartWriteback;
	wire					CSORAMAccess;

	wire					SetDummy, ClearDummy;
	wire					AccessIsDummy;
	
	wire					AppendComplete, FullPathReadComplete, ROPathReadComplete, PathReadComplete, PathWritebackComplete;
	wire					OperationComplete_Pre, OperationComplete;
	
	wire					ROAccess, RWAccess, StartRW, REWRoundComplete;
	wire	[ORAML-1:0]		GentryLeaf_Pre;	
	
	wire	[ORAML-1:0]		DummyLeaf;
	wire					DummyLeaf_Valid;
	wire	[PRNGLWidth-1:0] DummyLeaf_Wide;
	
	// Front-end interfaces
	
	wire	[BECMDWidth-1:0] Command_Internal;
	wire	[ORAMU-1:0]		PAddr_Internal;
	wire	[ORAML-1:0]		CurrentLeaf_Internal, RemappedLeaf_Internal;
	wire					Command_InternalValid, Command_InternalReady;

	wire	[BlkBEDWidth-1:0] EvictBuf_Chunks;
	wire	[BlkBEDWidth-1:0] ReturnBuf_Space;
		
	wire	[BEDWidth-1:0]	Store_ShiftBufData;	
	wire					Store_ShiftBufValid, Store_ShiftBufReady;
	
	wire	[BEDWidth-1:0]	Load_ShiftBufData;
	wire					Load_ShiftBufValid, Load_ShiftBufReady;
	
	wire					EvictGate, UpdateGate;
	
	// Read pipeline
		
	(* mark_debug = "TRUE" *)	wire					HeaderDownShift_InValid, HeaderDownShift_InReady;
	wire					DataDownShift_InValid, DataDownShift_InReady;
		
	wire	[BktBSTWidth-1:0] BucketReadCtr;
	wire					ReadProcessingHeader;	
	
	(* mark_debug = "TRUE" *)	wire	[ORAMZ-1:0] 	HeaderDownShift_ValidBits;
	(* mark_debug = "TRUE" *)	wire	[BigUWidth-1:0]	HeaderDownShift_PAddrs;
	(* mark_debug = "TRUE" *)	wire	[BigLWidth-1:0]	HeaderDownShift_Leaves;
		
	(* mark_debug = "TRUE" *)	wire					ReadBlockIsValid, BlockPresent;
	
	wire	[BEDWidth-1:0]	DataDownShift_OutData;
	wire					DataDownShift_OutValid, DataDownShift_OutReady;
	wire					BlockReadValid, BlockReadReady;
	
	wire	[ORAMU-1:0]		HeaderDownShift_OutPAddr; 
	wire	[ORAML-1:0]		HeaderDownShift_OutLeaf;
	wire					HeaderDownShift_OutValid;		
	
	(* mark_debug = "TRUE" *)	wire	[PBEDWidth-1:0]	PathReadCtr;
	wire					DataDownShift_Transfer;
	
	wire					BlockReadCtr_Reset;
	wire	[BlkBEDWidth-1:0] BlockReadCtr; 	
	wire 					InPath_BlockReadComplete;	
	
	// Writeback pipeline

	wire					Stash_BlockReadComplete;
	
	wire	[ORAMU-1:0]		HeaderUpShift_InPAddr; 
	wire	[ORAML-1:0]		HeaderUpShift_InLeaf;
	wire					HeaderUpShift_InReady;
	(* mark_debug = "TRUE" *)	wire					HeaderUpShift_OutValid, HeaderUpShift_OutReady;

	(* mark_debug = "TRUE" *)	wire	[ORAMZ-1:0] 	HeaderUpShift_ValidBits;
	(* mark_debug = "TRUE" *)	wire	[BigUWidth-1:0]	HeaderUpShift_PAddrs;
	(* mark_debug = "TRUE" *)	wire	[BigLWidth-1:0]	HeaderUpShift_Leaves;	
	
	wire	[BEDWidth-1:0]	DataUpShift_InData;
	wire					DataUpShift_InValid, DataUpShift_InReady;
	wire	[DDRDWidth-1:0]	DataUpShift_OutData;
	(* mark_debug = "TRUE" *)	wire					DataUpShift_OutValid, DataUpShift_OutReady;

	wire					WritebackBlockIsValid;
	wire 					WritebackBlockCommit;
	
	(* mark_debug = "TRUE" *)	wire 					WritebackProcessingHeader;		
	wire	[DDRDWidth-1:0]	UpShift_HeaderFlit, BucketBuf_OutData;
	wire					BucketBuf_OutValid, BucketBuf_OutReady;
							
	wire					BucketWritebackValid;
	wire	[BktBSTWidth-1:0] BucketWritebackCtr;
							
	wire	[DDRDWidth-1:0]	UpShift_DRAMWriteData;
	
	wire					PathWritebackComplete_Commands_RW, PathWritebackComplete_Commands_RO, PathWritebackComplete_Data_Pre;
	wire					PathWritebackComplete_Commands, PathWritebackComplete_Data;	
	
	// Stash
	
	wire					Stash_IsIdle;
	
	wire					Stash_StartScanOp, Stash_SkipWritebackOp, Stash_StartWritebackOp;
	
	wire	[BEDWidth-1:0]	Stash_StoreData;						
	wire					Stash_StoreDataValid, Stash_StoreDataReady;
	
	wire	[BEDWidth-1:0]	Stash_ReturnData;
	wire					Stash_ReturnDataValid, Stash_ReturnDataReady;
	
	wire					Stash_ResetDone;
	
	wire					Stash_UpdateBlockValid, Stash_UpdateBlockReady;
	wire					Stash_EvictBlockValid, Stash_EvictBlockReady;

	wire					Stash_BlockWriteComplete;
	
	(* mark_debug = "TRUE" *)	wire					StashAlmostFull, StashOverflow;
	
	(* mark_debug = "TRUE" *)	wire	[SEAWidth-1:0]	StashOccupancy;
	(* mark_debug = "TRUE" *)	wire					BlockNotFound, BlockNotFoundValid;
	
	// ORAM initialization
	
	wire	[DDRAWidth-1:0]	DRAMInit_DRAMCommandAddress;
	wire	[DDRCWidth-1:0]	DRAMInit_DRAMCommand;
	wire					DRAMInit_DRAMCommandValid, DRAMInit_DRAMCommandReady;

	wire	[DDRDWidth-1:0]	DRAMInit_DRAMWriteData;
	wire					DRAMInit_DRAMWriteDataValid, DRAMInit_DRAMWriteDataReady;
	
	// Address generator
	
	wire	[DDRAWidth-1:0]	AddrGen_DRAMCommandAddress;
	wire	[DDRCWidth-1:0]	AddrGen_DRAMCommand;
	wire					AddrGen_DRAMCommandValid, AddrGen_DRAMCommandReady;

	wire 					AddrGen_HeaderWriteback;	
	wire					AddrGen_Reading;
	
	wire	[ORAML-1:0]		AddrGen_Leaf;
	wire					AddrGen_InReady, AddrGen_InValid;
	
	wire	[DDRAWidth-1:0]	AddrGen_DRAMCommandAddress_Internal;
	wire	[DDRCWidth-1:0]	AddrGen_DRAMCommand_Internal;
	wire					AddrGen_DRAMCommandValid_Internal, AddrGen_DRAMCommandReady_Internal;									

	//--------------------------------------------------------------------------
	//	Simulation checks
	//--------------------------------------------------------------------------

	`ifdef SIMULATION
		reg [STWidth-1:0] CS_Delayed;
		integer WriteCount_Sim = 0;
		reg	StartedFirstAccess = 1'b0;
		
		initial begin
			if (BEDWidth > DDRDWidth) begin
				$display("[%m @ %t] ERROR: BEDWidth should never be > DDRDWidth", $time);
				$stop;
			end
		end
		
		always @(posedge Clock) begin
			CS_Delayed <= CS;
		
			if (CSStartRead) StartedFirstAccess <= 1'b1;
				
			if (~CSInitialize & DRAMWriteDataValid & DRAMWriteDataReady)
				WriteCount_Sim = WriteCount_Sim + 1;
				
			if (StartedFirstAccess & CSIdle & (WriteCount_Sim % PathSize_DRBursts)) begin
				$display("[%m @ %t] We wrote back %d blocks (not aligned to path length ...)", $time, WriteCount_Sim);
				$stop;
			end
		
	`ifdef SIMULATION_VERBOSE_BE
			if (CS_Delayed != CS) begin
				if (CSStartRead)
					$display("[%m @ %t] Backend: start access, dummy = %b, command = %x, leaf = %x", $time, AccessIsDummy, Command_Internal, AddrGen_Leaf);
				if (CSAppend)
					$display("[%m @ %t] Backend: start append", $time);
			end
		
			if (DRAMCommandValid & DRAMCommandReady) begin
				$display("[%m @ %t] DRAM command write? = %b, addr = %d (hex = %x)", $time, DRAMCommand == DDR3CMD_Write, DRAMCommandAddress, DRAMCommandAddress);
			end
		
			if (DRAMWriteDataValid & DRAMWriteDataReady) begin
				$display("[%m @ %t] DRAM write %x", $time, DRAMWriteData);
			end
			
			if (DRAMReadDataValid) begin
				$display("[%m @ %t] DRAM read %x", $time, DRAMReadData);
			end
	`endif
		end
	`endif
	
	//--------------------------------------------------------------------------
	//	Control logic
	//--------------------------------------------------------------------------		

	assign	CSInitialize =							CS == ST_Initialize;
	assign	CSIdle =								CS == ST_Idle;
	assign	CSAppend =								CS == ST_Append;
	assign	CSStartRead =							CS == ST_StartRead;
	assign	CSStartWriteback =						CS == ST_StartWriteback;
	assign	CSPathRead =							CS == ST_PathRead;
	assign	CSPathWriteback =						CS == ST_PathWriteback;
	
	assign	CSORAMAccess =							~CSInitialize & ~CSIdle;
	
	assign	AllResetsDone =							Stash_ResetDone & DRAMInitComplete;

	assign	Stash_StartScanOp =						CSStartRead;
	assign	Stash_SkipWritebackOp =					CSStartRead & ROAccess;
	assign	Stash_StartWritebackOp =				CSStartWriteback; // Note: this will go high even for RO accesses; this is intended
	
	assign	OperationComplete_Pre =					CSPathWriteback & Stash_IsIdle & PathWritebackComplete & AddrGen_InReady;
		
	generate if (Overclock) begin
		Register #(			.Width(					1),
							.Initial(				0))
				oc_dly(		.Clock(					Clock),
							.Reset(					OperationComplete),
							.Set(					1'b0),
							.Enable(				1'b1),
							.In(					OperationComplete_Pre),
							.Out(					OperationComplete));		
	end else begin
		assign	OperationComplete =					OperationComplete_Pre;
	end endgenerate
	
	assign	Command_InternalReady =					AppendComplete | (OperationComplete & ~AccessIsDummy);

	assign	AddrGen_InValid =						CSStartRead | CSStartWriteback; 
	
	always @(posedge Clock) begin
		if (Reset) CS <= 							ST_Initialize;
		else CS <= 									NS;
	end
	
	always @( * ) begin
		NS = 										CS;
		case (CS)
			ST_Initialize : 
				if (AllResetsDone) 
					NS =						 	ST_Idle;
			ST_Idle :
				// stash capacity check gets highest priority
				if (DummyLeaf_Valid) begin
					if (SetDummy)
						NS =						ST_StartRead;
					// do appends first ("greedily") because they are cheap
					else if (Command_InternalValid	& 	Command_Internal == BECMD_Append)
						NS =						ST_Append;
					else if (Command_InternalValid 	& (	(Command_Internal == BECMD_Read) | 
														(Command_Internal == BECMD_ReadRmv))
													&	(ReturnBuf_Space >= BlkSize_BEDChunks))
						NS =						ST_StartRead;
					else if (Command_InternalValid 	& (	Command_Internal == BECMD_Update)
													& (	EvictBuf_Chunks >= BlkSize_BEDChunks))
						NS = 						ST_StartRead;
				end
			ST_Append :
				if (AppendComplete)
					NS = 							ST_Idle;
			ST_StartRead : 
				if (AddrGen_InReady)
					NS =							ST_PathRead;
			ST_PathRead : 							
				if (PathReadComplete)
					NS =							ST_StartWriteback;
			ST_StartWriteback :
				if (AddrGen_InReady)
					NS =							ST_PathWriteback;
			ST_PathWriteback : 
				if (OperationComplete)
					NS =							ST_Idle;
		endcase
	end
	
	//--------------------------------------------------------------------------
	//	Basic/REW split control logic
	//--------------------------------------------------------------------------
	
	generate if (EnableREW) begin:REW_CONTROL
		wire [ORAMU-1:0]	ROPAddr_Pre;
		wire [ORAML-1:0]	ROLeaf_Pre;
		wire				REWRoundDummy_Pre;	
		
		Counter	#(			.Width(					ORAML))
				gentry_leaf(.Clock(					Clock),
							.Reset(					Reset | (REWRoundComplete & &GentryLeaf_Pre)),
							.Set(					1'b0),
							.Load(					1'b0),
							.Enable(				REWRoundComplete),
							.In(					{ORAML{1'bx}}),
							.Count(					GentryLeaf_Pre));
		
		CountAlarm #(		.Threshold(				ORAME))
				rew_rnd_ctr(.Clock(					Clock | REWRoundComplete), 
							.Reset(					Reset), 
							.Enable(				OperationComplete),
							.Done(					StartRW));
		Register #(			.Width(					1))
				rew_rw(		.Clock(					Clock),
							.Reset(					Reset | REWRoundComplete),
							.Set(					StartRW),
							.Enable(				1'b0),
							.In(					1'bx),
							.Out(					RWAccess));
		assign	REWRoundComplete =					RWAccess & OperationComplete;
							
		assign	ClearDummy =						CSIdle & ~StashAlmostFull & ~RWAccess;
		assign	SetDummy =							CSIdle & (StashAlmostFull | RWAccess);
		
		assign	DummyLeaf =							(RWAccess) ? GentryLeaf_Pre : DummyLeaf_Wide[ORAML-1:0];

		assign	AddrGen_HeaderWriteback =			~RWAccess & CSStartWriteback;
		assign	ROAccess =							~RWAccess;
		
		assign	ROPAddr_Pre =						PAddr_Internal;
		assign	ROLeaf_Pre =						(REWRoundDummy) ? DummyLeaf : CurrentLeaf_Internal;
		assign	REWRoundDummy_Pre =					AccessIsDummy;
		
		if (Overclock) begin
			always @(posedge Clock) begin
				ROPAddr <=							ROPAddr_Pre;
				ROLeaf <=							ROLeaf_Pre;
				REWRoundDummy <=					REWRoundDummy_Pre;
			end
		end else begin
			always @( * ) begin
				ROPAddr =							ROPAddr_Pre;
				ROLeaf =							ROLeaf_Pre;
				REWRoundDummy =						REWRoundDummy_Pre;
			end		
		end
	end else begin:BASIC_CONTROL
		assign	ClearDummy =						CSIdle & ~StashAlmostFull;
		assign	SetDummy =							CSIdle & StashAlmostFull;
		
		assign	DummyLeaf =							DummyLeaf_Wide[ORAML-1:0];
		
		assign	AddrGen_HeaderWriteback =			1'b0;
		assign	ROAccess =							1'b0;
		
		always @( * ) begin
			ROPAddr =								{ORAMU{1'bx}};
			ROLeaf =								{ORAML{1'bx}};
			REWRoundDummy =							1'b0;
		end
	end endgenerate

	Register	#(			.Width(					1))
				dummy_reg(	.Clock(					Clock),
							.Reset(					Reset | ClearDummy),
							.Set(					SetDummy),
							.Enable(				1'b0),
							.In(					1'bx),
							.Out(					AccessIsDummy));
	
	PRNG 		#(			.RandWidth(				PRNGLWidth),	
							.SecretKey(				128'hd8_40_e1_a8_dc_ca_e7_ec_d9_1f_61_48_7a_f2_cb_00)) // TODO make dynamic
				leaf_gen(	.Clock(					Clock), 
							.Reset(					Reset),
							.RandOutReady(			OperationComplete),
							.RandOutValid(			DummyLeaf_Valid),
							.RandOut(				DummyLeaf_Wide));
	
	//--------------------------------------------------------------------------
	//	Front-end commands
	//--------------------------------------------------------------------------

	FIFORegister #(			.Width(					BECMDWidth + ORAMU + ORAML*2))
				cmd_reg(	.Clock(					Clock),
							.Reset(					Reset),
							.InData(				{Command,			PAddr, 			CurrentLeaf, 			RemappedLeaf}),
							.InValid(				CommandValid),
							.InAccept(				CommandReady),
							.OutData(				{Command_Internal,	PAddr_Internal,	CurrentLeaf_Internal,	RemappedLeaf_Internal}),
							.OutSend(				Command_InternalValid),
							.OutReady(				Command_InternalReady));
	
	//--------------------------------------------------------------------------
	//	Front-end stores
	//--------------------------------------------------------------------------	

	FIFOShiftRound #(		.IWidth(				FEDWidth),
							.OWidth(				BEDWidth))
				st_shift(	.Clock(					Clock),
							.Reset(					Reset),
							.InData(				StoreData),
							.InValid(				StoreValid),
							.InAccept(				StoreReady),
							.OutData(				Store_ShiftBufData),
							.OutValid(				Store_ShiftBufValid),
							.OutReady(				Store_ShiftBufReady));
							
	// SECURITY: Don't make a write-update unless the FE gives us a block first
	FIFORAM		#(			.Width(					BEDWidth),
							.Buffering(				BlkSize_BEDChunks))
				st_buf(		.Clock(					Clock),
							.Reset(					Reset),
							.OutFullCount(			EvictBuf_Chunks),
							.InData(				Store_ShiftBufData),
							.InValid(				Store_ShiftBufValid),
							.InAccept(				Store_ShiftBufReady),
							.OutData(				Stash_StoreData),
							.OutSend(				Stash_StoreDataValid),
							.OutReady(				Stash_StoreDataReady));

	//------------------------------------------------------------------------------
	//	Front-end loads
	//------------------------------------------------------------------------------								
	
	// SECURITY: Don't perform a read/rm until the front-end can take a whole block
	// NOTE: this should come before the shifter because the Stash ReturnData path 
	// doesn't have backpressure
	FIFORAM		#(			.Width(					BEDWidth),
							.Buffering(				BlkSize_BEDChunks))
				ld_buf(		.Clock(					Clock),
							.Reset(					Reset),
							.InEmptyCount(			ReturnBuf_Space),
							.InData(				Stash_ReturnData),
							.InValid(				Stash_ReturnDataValid),
							.InAccept(				Stash_ReturnDataReady),
							.OutData(				Load_ShiftBufData),
							.OutSend(				Load_ShiftBufValid),
							.OutReady(				Load_ShiftBufReady));	
	
	FIFOShiftRound #(		.IWidth(				BEDWidth),
							.OWidth(				FEDWidth))
				ld_shift(	.Clock(					Clock),
							.Reset(					Reset),
							.InData(				Load_ShiftBufData),
							.InValid(				Load_ShiftBufValid),
							.InAccept(				Load_ShiftBufReady),
							.OutData(				LoadData),
							.OutValid(				LoadValid),
							.OutReady(				LoadReady));
							
	//------------------------------------------------------------------------------
	//	Address generation & ORAM initialization
	//------------------------------------------------------------------------------

	assign	AddrGen_Reading = 						CSStartRead;
	assign	AddrGen_Leaf =							(AccessIsDummy) ? DummyLeaf : CurrentLeaf_Internal;
	
	// TODO pass AES header params
    AddrGen #(				.ORAMB(					ORAMB),
							.ORAMU(					ORAMU),
							.ORAML(					ORAML),
							.ORAMZ(					ORAMZ),
							.DDR_nCK_PER_CLK(		DDR_nCK_PER_CLK),
							.DDRDQWidth(			DDRDQWidth),
							.DDRCWidth(				DDRCWidth),
							.DDRAWidth(				DDRAWidth),
							.IVEntropyWidth(		IVEntropyWidth))
				addr_gen(	.Clock(					Clock),
							.Reset(					Reset | CSInitialize),
							.Start(					AddrGen_InValid), 
							.Ready(					AddrGen_InReady),
							.RWIn(					AddrGen_Reading),
							.BHIn(					AddrGen_HeaderWriteback),
							.leaf(					AddrGen_Leaf),
							.CmdReady(				AddrGen_DRAMCommandReady_Internal),
							.CmdValid(				AddrGen_DRAMCommandValid_Internal),
							.Cmd(					AddrGen_DRAMCommand_Internal), 
							.Addr(					AddrGen_DRAMCommandAddress_Internal));
	FIFORegister #(			.Width(					DDRAWidth + DDRCWidth),
							.FWLatency(				Overclock))
				addr_dly(	.Clock(					Clock),
							.Reset(					Reset),
							.InData(				{AddrGen_DRAMCommand_Internal,	AddrGen_DRAMCommandAddress_Internal}),
							.InValid(				AddrGen_DRAMCommandValid_Internal),
							.InAccept(				AddrGen_DRAMCommandReady_Internal),
							.OutData(				{AddrGen_DRAMCommand,			AddrGen_DRAMCommandAddress}),
							.OutSend(				AddrGen_DRAMCommandValid),
							.OutReady(				AddrGen_DRAMCommandReady));						
							
	// Basic path ORAM needs to zero/encrypt valid bits in a bucket.  REW ORAM 
	// uses gentry bucket version #s to determine whether a bucket is valid.
	generate if (EnableREW) begin:AUTO_INIT
		assign	DRAMInitComplete =					1'b1;
		assign	DRAMInit_DRAMCommandAddress =		{DDRAWidth{1'bx}};
		assign	DRAMInit_DRAMCommand =				DDR3CMD_Write;
		assign	DRAMInit_DRAMCommandValid =			1'b0;
		
		assign	DRAMInit_DRAMWriteData =			{DDRDWidth{1'bx}};
		assign	DRAMInit_DRAMWriteDataValid =		1'b0;
	end else begin:DRAM_INIT
		DRAMInitializer #(	.ORAMB(					ORAMB),
							.ORAMU(					ORAMU),
							.ORAML(					ORAML),
							.ORAMZ(					ORAMZ),
							.DDR_nCK_PER_CLK(		DDR_nCK_PER_CLK),
							.DDRDQWidth(			DDRDQWidth),
							.DDRCWidth(				DDRCWidth),
							.DDRAWidth(				DDRAWidth),
							.IVEntropyWidth(		IVEntropyWidth))
			dram_init(		.Clock(					Clock),
							.Reset(					Reset),
							.DRAMCommandAddress(	DRAMInit_DRAMCommandAddress),
							.DRAMCommand(			DRAMInit_DRAMCommand),
							.DRAMCommandValid(		DRAMInit_DRAMCommandValid),
							.DRAMCommandReady(		DRAMInit_DRAMCommandReady),
							.DRAMWriteData(			DRAMInit_DRAMWriteData),
							.DRAMWriteDataValid(	DRAMInit_DRAMWriteDataValid),
							.DRAMWriteDataReady(	DRAMInit_DRAMWriteDataReady),
							.Done(					DRAMInitComplete));
	end endgenerate

	//------------------------------------------------------------------------------
	//	StashTop
	//------------------------------------------------------------------------------
	
	StashTop	#(			.ORAMB(					ORAMB),
							.ORAMU(					ORAMU),
							.ORAML(					ORAML),
							.ORAMZ(					ORAMZ),
							.DDR_nCK_PER_CLK(		DDR_nCK_PER_CLK),
							.DDRDQWidth(			DDRDQWidth),
							.DDRCWidth(				DDRCWidth),
							.DDRAWidth(				DDRAWidth),
							.IVEntropyWidth(		IVEntropyWidth),
							.EnableREW(             EnableREW))
				stash_top(	.Clock(					Clock),
							.Reset(					Reset),
							
							.Stash_ResetDone(		Stash_ResetDone),
							.Stash_IsIdle(			Stash_IsIdle),
							.StashAlmostFull(       StashAlmostFull),
							
							.Stash_StartScanOp(		Stash_StartScanOp),
							.Stash_SkipWritebackOp(	Stash_SkipWritebackOp),
							.Stash_StartWritebackOp(Stash_StartWritebackOp),
							
							.Command(				Command_Internal),
							.PAddr(					PAddr_Internal),
							.CurrentLeaf(			AddrGen_Leaf),
							.RemappedLeaf(			RemappedLeaf_Internal),
							.AccessIsDummy(			AccessIsDummy),
							
							.Stash_ReturnData(		Stash_ReturnData),
							.Stash_ReturnDataValid(	Stash_ReturnDataValid),
							
							.Stash_StoreData(		Stash_StoreData),
							.Stash_StoreDataValid(	Stash_StoreDataValid),
							.Stash_StoreDataReady(	Stash_StoreDataReady),
							.AppendComplete(		AppendComplete),
							
							.DRAMReadData(			DRAMReadData),
							.DRAMReadDataValid(		DRAMReadDataValid),
							.DRAMReadDataReady(		DRAMReadDataReady),
							
							.DRAMWriteData(			DRAMWriteData),
							.DRAMWriteDataValid(	DRAMWriteDataValid),
							.DRAMWriteDataReady(	DRAMWriteDataReady),

							.ROAccess(				ROAccess),
							.CSIdle(				CSIdle),
							.CSAppend(				CSAppend),
							.CSORAMAccess(			CSORAMAccess),
							.PathReadComplete(		PathReadComplete));

	//------------------------------------------------------------------------------
	//	[Writeback path] Let control know the WB is complete
	//------------------------------------------------------------------------------

	// Count commands written back	
	CountAlarm #(			.Threshold(				PathSize_DRBursts))
				out_CRW_cnt(.Clock(					Clock), 
							.Reset(					Reset), 
							.Enable(				CSPathWriteback & DRAMInitComplete & ~ROAccess & DRAMCommandValid & DRAMCommandReady),
							.Done(					PathWritebackComplete_Commands_RW));
	generate if (EnableREW) begin:RO_CMD_CNT
		CountAlarm #(		.Threshold(				BktHSize_DRBursts * (ORAML + 1))) // header writeback
				out_CRO_cnt(.Clock(					Clock), 
							.Reset(					Reset), 
							.Enable(				CSPathWriteback & DRAMInitComplete & ROAccess & DRAMCommandValid & DRAMCommandReady),
							.Done(					PathWritebackComplete_Commands_RO));
	end endgenerate
	Register	#(			.Width(					1))
				out_C_hld(	.Clock(					Clock),
							.Reset(					Reset | CSIdle),
							.Set(					(PathWritebackComplete_Commands_RO | PathWritebackComplete_Commands_RW) & DRAMCommandValid & DRAMCommandReady),
							.Enable(				1'b0),
							.In(					1'bx),
							.Out(					PathWritebackComplete_Commands));
	
	// NOTE: this is like having a joint ready-valid.  We only have this logic 
	// here because a lot of the backend internal modules assume all data is 
	// flushed before next access.  This won't impact performance since the next 
	// read path won't be able to proceed until all writes are pushed to ORAM anyway.
	
	// Count data written back (identical logic as above)

	CountAlarm 	#(			.Threshold(				PathSize_DRBursts))
				rw_r_cnt(	.Clock(					Clock), 
							.Reset(					Reset | CSIdle), 
							.Enable(				DRAMWriteDataValid & DRAMWriteDataReady),
							.Done(					PathWritebackComplete_Data_Pre));
										
	Register	#(			.Width(					1))
				out_D_hld(	.Clock(					Clock),
							.Reset(					Reset | CSIdle),
							.Set(					PathWritebackComplete_Data_Pre & DRAMWriteDataValid & DRAMWriteDataReady),
							.Enable(				1'b0),
							.In(					1'bx),
							.Out(					PathWritebackComplete_Data));	
	
	assign	PathWritebackComplete =					(ROAccess) ? 	PathWritebackComplete_Commands : 
																	PathWritebackComplete_Commands & PathWritebackComplete_Data;

	//------------------------------------------------------------------------------
	//	DRAM interface multiplexing
	//------------------------------------------------------------------------------

	assign	DRAMCommandAddress =					(CSInitialize) ? DRAMInit_DRAMCommandAddress 	: AddrGen_DRAMCommandAddress;
	assign	DRAMCommand =							(CSInitialize) ? DRAMInit_DRAMCommand 			: AddrGen_DRAMCommand;
	assign	DRAMCommandValid =						(CSInitialize) ? DRAMInit_DRAMCommandValid 		: AddrGen_DRAMCommandValid; 
	assign	AddrGen_DRAMCommandReady =				DRAMCommandReady &	   ~CSInitialize;
	assign	DRAMInit_DRAMCommandReady =				DRAMCommandReady & 		CSInitialize;
	assign	DRAMInit_DRAMWriteDataReady =			DRAMWriteDataReady &	CSInitialize;
	
	assign	DRAMWriteData =							(CSInitialize) ? DRAMInit_DRAMWriteData : 		UpShift_DRAMWriteData;
	assign	DRAMWriteDataValid =					(CSInitialize) ? DRAMInit_DRAMWriteDataValid : 	BucketWritebackValid;
	
	assign	BucketBuf_OutReady =					~CSInitialize & ~WritebackProcessingHeader & DRAMWriteDataReady;
	assign	HeaderUpShift_OutReady =				~CSInitialize &  WritebackProcessingHeader & DRAMWriteDataReady;
		
	//------------------------------------------------------------------------------	
endmodule
//------------------------------------------------------------------------------