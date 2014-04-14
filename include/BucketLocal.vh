
	localparam					BlkSize_FEDChunks =		`divceil(ORAMB, FEDWidth);
	localparam					BlkSize_BEDChunks =		`divceil(ORAMB, BEDWidth);
	localparam					BktSize_BEDChunks =		ORAMZ * BlkSize_BEDChunks;
	localparam					PathSize_BEDChunks =	(ORAML + 1) * BktSize_BEDChunks;

	localparam					BlkBEDWidth =			`max(`log2(BlkSize_BEDChunks + 1), 1);
	localparam					PBEDWidth =				`log2(PathSize_BEDChunks);
	