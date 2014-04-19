
	// Configured for the VC707 Evaluation board
	localparam	 			DDR_nCK_PER_CLK = 		4, // 200 Mhz interface; 800 Mhz DRAM
							DDRDQWidth =			64, // DQ bus width / DRAM word width
							DDRCWidth =				3, // Command width
							DDRAWidth =				28; // Address width max 2GB capacity = 2^34B; each unique 28b address maps to 64b of data
							
	localparam				DDRBstLen =				2 * DDR_nCK_PER_CLK, // Burst length (in # of 64b words) (TODO do not calculate this way!)
							DDRDWidth = 			DDRBstLen * DDRDQWidth, // Data width (512b @ 200 Mhz)
							DDRMWidth =				DDRDWidth / 8, // Write mask width
							DDRROWWidth =			8192; // Big Row size in DRAM column width: 1024 column * 8 banks (TODO: make this in terms of ROW/BANK params)

	localparam				DDR3CMD_Write = 		3'b000,
							DDR3CMD_Read = 			3'b001;	
