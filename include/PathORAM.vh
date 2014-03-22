
	// algorithm-level ORAM parameters
	parameter					ORAMB =				128, // block size in bits
								ORAMU =				32, // program addr (at byte-addressable block granularity) width
								ORAML =				2, // the number of bits needed to determine a path down the tree (actual # levels is ORAML + 1)
								ORAMZ =				2, // bucket Z
								ORAMC =				10, // Number of slots in the stash, _in addition_ to the length of one path
								
	           					FEDWidth =			64, // data width of frontend busses (reading/writing from/to stash, LLC network interface width)
								BEDWidth =			64, // backend datapath width (AES bits/cycle, should be == to DDRDWidth if possible)
	
								Overclock = 		1 // Pipeline various operations inside the stash (needed for 200 Mhz operation)
