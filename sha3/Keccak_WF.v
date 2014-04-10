
//==============================================================================
//	Module:		Keccak_WF
//	Desc:		W keccak units wrapped together
//				Ready-valid interface on both input and output 
//				Input has a funnel. Hash input has a fixed amount of chunks
//==============================================================================

module Keccak_WF (
	Clock, Reset, 
	DataInReady, DataInValid, DataIn,
	HashOutReady, HashOutValid, HashOut
);

	parameter IWidth = 512;
	parameter HashByteCount = 1;
	
	localparam HashInWidth = 64;
	localparam HashOutWidth = 512;
	
	input  Clock, Reset;
	
	output DataInReady;
	input  DataInValid;
	input  [IWidth-1:0] DataIn;
	
	input  HashOutReady;
	output HashOutValid;
	output [HashOutWidth-1:0] HashOut;
	
	// hash size param
	localparam HashChunkInByte = HashInWidth / 8;
    localparam HashChunkCount = HashByteCount / HashChunkInByte + 1;                         
    localparam BytesInLastChunk = HashByteCount % HashChunkInByte;
        // if a multiple of chunks, need to add one more empty chunk
	
	// hash in and out data path
	wire HashInValid, HashInReady;
	wire [HashInWidth-1:0] HashIn; 
	
	wire LastChunk, HashBufFull, HashBusy, HashReset;
	
	// Funnel --> HashEngine, controlled by a CounterAlarm
	
	FIFOShiftRound #(		.IWidth(				IWidth),
							.OWidth(				HashInWidth))
        HashInFunnel(	    .Clock(					Clock),
							.Reset(					Reset || LastChunk),
							.InData(				DataIn),
							.InValid(				DataInValid),
							.InAccept(				DataInReady),
							.OutData(			    HashIn),
							.OutValid(				HashInValid),
							.OutReady(				HashInReady)
						);
	
    keccak	
        HashEngine	(	    .clk(			Clock), 
							.reset(			HashReset), 
							.in(			HashIn), 
							.in_ready(		HashInValid), 
							.is_last(		LastChunk), 
							.byte_num(		BytesInLastChunk), 
							.buffer_full(	HashBufFull), 
							.out(			HashOut), 
							.out_ready(		HashOutValid)
						);

    CountAlarm #	(	    .Threshold(HashChunkCount))
        ChunkCtr	(	    .Clock(		Clock),
							.Reset(		Reset),
							.Enable(	HashInValid && HashInReady),
							.Done(		LastChunk)
						);

	assign HashReset = Reset || (HashOutValid && HashOutReady);
	assign HashInReady = !HashBusy && !HashBufFull;
	Register #(.Width(1)) Hash (Clock, HashReset, LastChunk, 1'b0, 1'bx, HashBusy);
	
endmodule
	