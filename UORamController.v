`include "Const.vh"

module UORamController
#(`include "UORAM.vh", `include "PathORAM.vh", `include "PLB.vh")
(
    input Clock, Reset, 
    
    // receive command from network
    output CmdInReady,
    input CmdInValid, 
    input [BECMDWidth-1:0] CmdIn,                // 00 for write, 01 for read, 10 for read_remove
    input [ORAMU-1:0] ProgAddrIn,
    
    // receive data from network
    output DataInReady,
    input DataInValid,
    input [FEDWidth-1:0] DataIn,
    
    // return data to network
    input  ReturnDataReady,
    output ReturnDataValid,
    output [FEDWidth-1:0] ReturnData,
    
    // send request to backend
    input  CmdOutReady,
    output CmdOutValid,
    output [BECMDWidth-1:0] CmdOut,
    output [ORAMU-1:0] AddrOut,
    output [ORAML-1:0] OldLeaf, NewLeaf,
    
    // send data to backend
    input  StoreDataReady,
    output StoreDataValid, 
    output [FEDWidth-1:0] StoreData,
    
    // receive response from backend
    output LoadDataReady,
    input  LoadDataValid,
    input  [FEDWidth-1:0] LoadData
);

    `include "PathORAMBackendLocal.vh";
    `include "CacheCmdLocal.vh";
    `include "PLBLocal.vh";  

    // FrontEnd state machines
    wire [BECMDWidth-1:0] LastCmd;
    Register #(.Width(2))
        CmdReg (Clock, Reset, 1'b0, CmdReady && CmdValid, CmdIn, LastCmd);
    
    reg [MaxLogRecursion-1:0] QDepth;   // TODO: maximum recursion
    reg [ORAMU-1:0] AddrQ [Recursion-1:0];
    
    wire Preparing, Accessing;
    wire RefillStarted, ExpectingProgramData;
    
    assign CmdInReady = !Preparing && !Accessing && !ExpectingProgramData && PPPCmdReady;
       
    // ================================== PosMapPLB ============================
    wire PPPCmdReady, PPPCmdValid;
    wire [1:0] PPPCmd;
    wire [ORAMU-1:0] PPPAddrIn, PPPAddrOut;   
    wire PPPRefill;
    wire [LeafWidth-1:0] PPPRefillData;  
    wire PPPOutReady, PPPValid, PPPHit, PPPUnInit, PPPEvict;
    wire PPPEvictDataValid;
    wire [LeafWidth-1:0] PPPEvictData;
       
    PosMapPLB #(.ORAMU(             ORAMU), 
                .ORAML(             ORAML), 
                .ORAMB(             ORAMB), 
                .NumValidBlock(     NumValidBlock), 
                .Recursion(         Recursion), 
                .LeafWidth(         LeafWidth), 
                .PLBCapacity(       PLBCapacity)) 
        PPP (   .Clock(             Clock), 
                .Reset(             Reset), 
                .CmdReady(          PPPCmdReady), 
                .CmdValid(          PPPCmdValid), 
                .Cmd(               PPPCmd), 
                .AddrIn(            PPPAddrIn), 
                .DInValid(          PPPRefill), 
                .DIn(               PPPRefillData), 
                .OutReady(          PPPOutReady), 
                .Valid(             PPPValid), 
                .Hit(               PPPHit), 
                .UnInit(            PPPUnInit), 
                .OldLeafOut(        OldLeaf), 
                .NewLeafOut(        NewLeaf), 
                .Evict(             PPPEvict), 
                .AddrOut(           PPPAddrOut),
                .EvictDataOutValid( PPPEvictDataValid), 
                .EvictDataOut(      PPPEvictData));   
 
    wire PPPMiss, PPPUnInitialized;
    wire PPPLookup, PPPInitRefill;
      
    assign PPPMiss = PPPValid && !PPPHit;
    assign PPPUnInitialized = PPPValid && PPPHit && PPPUnInit;
    
    assign PPPRefill = Accessing && (PPPRefillDataValid || PPPInitRefill);    
    assign PPPCmdValid = PPPLookup || (PPPRefill && !RefillStarted);
    assign PPPCmd = PPPRefill ? (PPPInitRefill ? CacheInitRefill : CacheRefill) : CacheWrite;//Preparing ? CacheRead : CacheWrite;
    assign PPPAddrIn = PPPRefill ? AddrQ[QDepth] : AddrQ[QDepth];
    
    assign PPPOutReady = Preparing ? PPPMiss : 
                            ((PPPMiss && !PPPEvict) || (PPPUnInitialized && QDepth > 0) || CmdOutReady);
            // four cases: 
            // (1) PLB miss in the prepare stage, 
            // (2) refill but no evict, must have PPPMiss there, or it will misfire on Hit & UnInit
            // (3) uninitialized PosMap block 
            // (4) request send to backend       
    // =============================================================================
    
    // ============================== Cmd to Backend ==============================
    wire EvictionRequest, InitRequest, SwitchReq, DataBlockReq;
    assign DataBlockReq = QDepth == 0;
    assign EvictionRequest = PPPValid && PPPEvict;
    assign InitRequest = DataBlockReq && PPPUnInitialized;
    assign CmdOutValid = Accessing && PPPValid && ((PPPHit && !PPPUnInit) || InitRequest || PPPEvict);

    // if EvictionRequest, write back a PosMap block; otherwise serve the next access in the queue  
    assign CmdOut = (EvictionRequest || InitRequest) ? BECMD_Append : !DataBlockReq ? BECMD_ReadRmv : LastCmd;
    assign AddrOut = EvictionRequest ? NumValidBlock + PPPAddrOut / LeafInBlock : AddrQ[QDepth];
    
    assign SwitchReq = (CmdOutReady && CmdOutValid && !EvictionRequest) || (!DataBlockReq && PPPUnInitialized);
                    // transition to next access, after sending out or initializing the current one
    // =============================================================================


    // front end control states
    Register #(.Width(1))
        PreparingReg (  .Clock(     Clock), 
                        .Reset(     Reset || (PPPValid && PPPHit)), 
                        .Set(       CmdInValid && CmdInReady), 
                        .Enable(    1'b0), 
                        .Out(       Preparing));    
    Register #(.Width(1))
        AccessingReg (  .Clock(     Clock), 
                        .Reset(     Reset || (Accessing && SwitchReq && DataBlockReq)), 
                        .Set(       Preparing && PPPValid && PPPHit), 
                        .Enable(    1'b0), 
                        .Out(       Accessing));  
    Register #(.Width(1))
        RefillStartReg (.Clock(     Clock), 
                        .Reset(     Reset || SwitchReq), 
                        .Set(       1'b0), 
                        .Enable(    1'b1),
                        .In(        RefillStarted || (PPPRefill && PPPCmdReady)),
                        .Out(       RefillStarted));  
    Register #(.Width(1))
      PPPInitRefillReg (.Clock(     Clock), 
                        .Reset(     Reset || (PPPInitRefill && PPPCmdReady)), 
                        .Set(       1'b0), 
                        .Enable(    1'b1),
                        .In(        SwitchReq && !DataBlockReq && PPPUnInitialized),
                        .Out(       PPPInitRefill));
    Register #(.Width(1))
      PPPLookupReg (.Clock(     Clock), 
                        .Reset(     Reset || (Accessing && SwitchReq)), 
                        .Set(       CmdInValid && CmdInReady),          // this sets up PLB lookup for the first access
                        .Enable(    1'b1),
                        .In(        Preparing ? PPPMiss : RefillStarted && PPPCmdReady),
                                                                        // make the next query after receiving the previous one
                        .Out(       PPPLookup));                                                                       
    
    //(Preparing && PPPValid && PPPHit) || 

    always @(posedge Clock) begin
       if (CmdInValid && CmdInReady) begin
            QDepth <= 0;                             
            AddrQ[0] = ProgAddrIn; 
        end
        
        else if (Preparing) begin
            if (PPPValid && PPPHit) begin       // PPP hit, done                
                $display("\t\tPosMap Hit  in Block %d for Block %d", AddrQ[QDepth+1], AddrQ[QDepth]);
            end
            else if (PPPMiss) begin             // PPP (PLB) miss, look for the next PosMap block
                QDepth <= QDepth + 1;
                AddrQ[QDepth+1] = NumValidBlock + AddrQ[QDepth] / LeafInBlock;
            
                $display("\t\tPosMap Miss in Block %d for Block %d", AddrQ[QDepth+1], AddrQ[QDepth]);
            end
        end
        
        else if (Accessing) begin       
            if (SwitchReq) begin                                          // sendint out or initializing the current one             
                if (!DataBlockReq && PPPUnInitialized)
                    $display("\t\tInitialize Block %d", AddrQ[QDepth]);
                else
                    $display("\t\tRequest Block %d", AddrQ[QDepth]);            
                QDepth <= QDepth - 1;                       
            end
            
            else if (CmdOutReady && CmdOutValid && EvictionRequest) begin
                $display("\t\tEvict Block %d to leaf %d", AddrOut, NewLeaf);
            end
        end
    end            

    // =================== data interface with network and backend ====================    
    UORamDataPath #(    .FEDWidth(          FEDWidth), 
                        .LeafWidth(         LeafWidth), 
                        .ORAMB(             ORAMB))
    DataScheduler (     .Clock(             Clock), 
                        .Reset(             Reset),
                        .SwitchReq(         SwitchReq),
                        .DataBlockReq(      DataBlockReq),
                        .Cmd(               LastCmd),
                        .ExpectingProgramData(  ExpectingProgramData),

                        // IO interface with network
                        .DataInReady(           DataInReady),
                        .DataInValid(           DataInValid),
                        .DataIn(                DataIn),                    
                        .ReturnDataReady(       ReturnDataReady), 
                        .ReturnDataValid(       ReturnDataValid), 
                        .ReturnData(            ReturnData),
                    
                        // IO interface with PPP
                        .PPPEvictDataReady(     ), 
                        .PPPEvictDataValid(     PPPEvictDataValid), 
                        .PPPEvictData(          PPPEvictData),
                        .PPPRefillDataReady(    1'b1),                    // PLB refill is always ready
                        .PPPRefillDataValid(    PPPRefillDataValid), 
                        .PPPRefillData(         PPPRefillData),        
                        
                        // IO interface with backend
                        .StoreDataReady(    StoreDataReady), 
                        .StoreDataValid(    StoreDataValid), 
                        .StoreData(         StoreData),
                        .LoadDataReady(     LoadDataReady), 
                        .LoadDataValid(     LoadDataValid), 
                        .LoadData(          LoadData)          
                );
    // ================================================================================    
endmodule
