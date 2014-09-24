// auto generated SRAM wrapper by rf1D_32soi_wrap_gen.py

module RF1DFCMN00128X078D02C064_WRAP (Clock, Enable, Write, _Addr, _DIn, _DOut);

	input Clock, Enable, Write;
	input [7-1:0] _Addr;
	input [78-1:0] _DIn;
	output [78-1:0] _DOut;

	RF1DFCMN00128X078D02C064 SRAM (
		.CLK(	Clock),
		.CE(	Enable),
		.RDWEN(	!Write),
		.DEEPSLEEP(	1'b0),

		.AB0(	_Addr[0]),
		.AC0(	_Addr[1]),
		.AW0(	_Addr[2]),
		.AW1(	_Addr[3]),
		.AW2(	_Addr[4]),
		.AW3(	_Addr[5]),
		.AW4(	_Addr[6]),

		.D0(	_DIn[0]),
		.D1(	_DIn[1]),
		.D2(	_DIn[2]),
		.D3(	_DIn[3]),
		.D4(	_DIn[4]),
		.D5(	_DIn[5]),
		.D6(	_DIn[6]),
		.D7(	_DIn[7]),
		.D8(	_DIn[8]),
		.D9(	_DIn[9]),
		.D10(	_DIn[10]),
		.D11(	_DIn[11]),
		.D12(	_DIn[12]),
		.D13(	_DIn[13]),
		.D14(	_DIn[14]),
		.D15(	_DIn[15]),
		.D16(	_DIn[16]),
		.D17(	_DIn[17]),
		.D18(	_DIn[18]),
		.D19(	_DIn[19]),
		.D20(	_DIn[20]),
		.D21(	_DIn[21]),
		.D22(	_DIn[22]),
		.D23(	_DIn[23]),
		.D24(	_DIn[24]),
		.D25(	_DIn[25]),
		.D26(	_DIn[26]),
		.D27(	_DIn[27]),
		.D28(	_DIn[28]),
		.D29(	_DIn[29]),
		.D30(	_DIn[30]),
		.D31(	_DIn[31]),
		.D32(	_DIn[32]),
		.D33(	_DIn[33]),
		.D34(	_DIn[34]),
		.D35(	_DIn[35]),
		.D36(	_DIn[36]),
		.D37(	_DIn[37]),
		.D38(	_DIn[38]),
		.D39(	_DIn[39]),
		.D40(	_DIn[40]),
		.D41(	_DIn[41]),
		.D42(	_DIn[42]),
		.D43(	_DIn[43]),
		.D44(	_DIn[44]),
		.D45(	_DIn[45]),
		.D46(	_DIn[46]),
		.D47(	_DIn[47]),
		.D48(	_DIn[48]),
		.D49(	_DIn[49]),
		.D50(	_DIn[50]),
		.D51(	_DIn[51]),
		.D52(	_DIn[52]),
		.D53(	_DIn[53]),
		.D54(	_DIn[54]),
		.D55(	_DIn[55]),
		.D56(	_DIn[56]),
		.D57(	_DIn[57]),
		.D58(	_DIn[58]),
		.D59(	_DIn[59]),
		.D60(	_DIn[60]),
		.D61(	_DIn[61]),
		.D62(	_DIn[62]),
		.D63(	_DIn[63]),
		.D64(	_DIn[64]),
		.D65(	_DIn[65]),
		.D66(	_DIn[66]),
		.D67(	_DIn[67]),
		.D68(	_DIn[68]),
		.D69(	_DIn[69]),
		.D70(	_DIn[70]),
		.D71(	_DIn[71]),
		.D72(	_DIn[72]),
		.D73(	_DIn[73]),
		.D74(	_DIn[74]),
		.D75(	_DIn[75]),
		.D76(	_DIn[76]),
		.D77(	_DIn[77]),
		.Q0(	_DOut[0]),
		.Q1(	_DOut[1]),
		.Q2(	_DOut[2]),
		.Q3(	_DOut[3]),
		.Q4(	_DOut[4]),
		.Q5(	_DOut[5]),
		.Q6(	_DOut[6]),
		.Q7(	_DOut[7]),
		.Q8(	_DOut[8]),
		.Q9(	_DOut[9]),
		.Q10(	_DOut[10]),
		.Q11(	_DOut[11]),
		.Q12(	_DOut[12]),
		.Q13(	_DOut[13]),
		.Q14(	_DOut[14]),
		.Q15(	_DOut[15]),
		.Q16(	_DOut[16]),
		.Q17(	_DOut[17]),
		.Q18(	_DOut[18]),
		.Q19(	_DOut[19]),
		.Q20(	_DOut[20]),
		.Q21(	_DOut[21]),
		.Q22(	_DOut[22]),
		.Q23(	_DOut[23]),
		.Q24(	_DOut[24]),
		.Q25(	_DOut[25]),
		.Q26(	_DOut[26]),
		.Q27(	_DOut[27]),
		.Q28(	_DOut[28]),
		.Q29(	_DOut[29]),
		.Q30(	_DOut[30]),
		.Q31(	_DOut[31]),
		.Q32(	_DOut[32]),
		.Q33(	_DOut[33]),
		.Q34(	_DOut[34]),
		.Q35(	_DOut[35]),
		.Q36(	_DOut[36]),
		.Q37(	_DOut[37]),
		.Q38(	_DOut[38]),
		.Q39(	_DOut[39]),
		.Q40(	_DOut[40]),
		.Q41(	_DOut[41]),
		.Q42(	_DOut[42]),
		.Q43(	_DOut[43]),
		.Q44(	_DOut[44]),
		.Q45(	_DOut[45]),
		.Q46(	_DOut[46]),
		.Q47(	_DOut[47]),
		.Q48(	_DOut[48]),
		.Q49(	_DOut[49]),
		.Q50(	_DOut[50]),
		.Q51(	_DOut[51]),
		.Q52(	_DOut[52]),
		.Q53(	_DOut[53]),
		.Q54(	_DOut[54]),
		.Q55(	_DOut[55]),
		.Q56(	_DOut[56]),
		.Q57(	_DOut[57]),
		.Q58(	_DOut[58]),
		.Q59(	_DOut[59]),
		.Q60(	_DOut[60]),
		.Q61(	_DOut[61]),
		.Q62(	_DOut[62]),
		.Q63(	_DOut[63]),
		.Q64(	_DOut[64]),
		.Q65(	_DOut[65]),
		.Q66(	_DOut[66]),
		.Q67(	_DOut[67]),
		.Q68(	_DOut[68]),
		.Q69(	_DOut[69]),
		.Q70(	_DOut[70]),
		.Q71(	_DOut[71]),
		.Q72(	_DOut[72]),
		.Q73(	_DOut[73]),
		.Q74(	_DOut[74]),
		.Q75(	_DOut[75]),
		.Q76(	_DOut[76]),
		.Q77(	_DOut[77]),
		.BW0(	1'b1),
		.BW1(	1'b1),
		.BW2(	1'b1),
		.BW3(	1'b1),
		.BW4(	1'b1),
		.BW5(	1'b1),
		.BW6(	1'b1),
		.BW7(	1'b1),
		.BW8(	1'b1),
		.BW9(	1'b1),
		.BW10(	1'b1),
		.BW11(	1'b1),
		.BW12(	1'b1),
		.BW13(	1'b1),
		.BW14(	1'b1),
		.BW15(	1'b1),
		.BW16(	1'b1),
		.BW17(	1'b1),
		.BW18(	1'b1),
		.BW19(	1'b1),
		.BW20(	1'b1),
		.BW21(	1'b1),
		.BW22(	1'b1),
		.BW23(	1'b1),
		.BW24(	1'b1),
		.BW25(	1'b1),
		.BW26(	1'b1),
		.BW27(	1'b1),
		.BW28(	1'b1),
		.BW29(	1'b1),
		.BW30(	1'b1),
		.BW31(	1'b1),
		.BW32(	1'b1),
		.BW33(	1'b1),
		.BW34(	1'b1),
		.BW35(	1'b1),
		.BW36(	1'b1),
		.BW37(	1'b1),
		.BW38(	1'b1),
		.BW39(	1'b1),
		.BW40(	1'b1),
		.BW41(	1'b1),
		.BW42(	1'b1),
		.BW43(	1'b1),
		.BW44(	1'b1),
		.BW45(	1'b1),
		.BW46(	1'b1),
		.BW47(	1'b1),
		.BW48(	1'b1),
		.BW49(	1'b1),
		.BW50(	1'b1),
		.BW51(	1'b1),
		.BW52(	1'b1),
		.BW53(	1'b1),
		.BW54(	1'b1),
		.BW55(	1'b1),
		.BW56(	1'b1),
		.BW57(	1'b1),
		.BW58(	1'b1),
		.BW59(	1'b1),
		.BW60(	1'b1),
		.BW61(	1'b1),
		.BW62(	1'b1),
		.BW63(	1'b1),
		.BW64(	1'b1),
		.BW65(	1'b1),
		.BW66(	1'b1),
		.BW67(	1'b1),
		.BW68(	1'b1),
		.BW69(	1'b1),
		.BW70(	1'b1),
		.BW71(	1'b1),
		.BW72(	1'b1),
		.BW73(	1'b1),
		.BW74(	1'b1),
		.BW75(	1'b1),
		.BW76(	1'b1),
		.BW77(	1'b1),


		.TAB0(	1'b0),
		.TAC0(	1'b0),
		.TAW0(	1'b0),
		.TAW1(	1'b0),
		.TAW2(	1'b0),
		.TAW3(	1'b0),
		.TAW4(	1'b0),
		.TQ0(	1'b0),
		.TQ1(	1'b0),
		.TQ2(	1'b0),
		.TQ3(	1'b0),
		.TQ4(	1'b0),
		.TQ5(	1'b0),
		.TQ6(	1'b0),
		.TQ7(	1'b0),
		.TQ8(	1'b0),
		.TQ9(	1'b0),
		.TQ10(	1'b0),
		.TQ11(	1'b0),
		.TQ12(	1'b0),
		.TQ13(	1'b0),
		.TQ14(	1'b0),
		.TQ15(	1'b0),
		.TQ16(	1'b0),
		.TQ17(	1'b0),
		.TQ18(	1'b0),
		.TQ19(	1'b0),
		.TQ20(	1'b0),
		.TQ21(	1'b0),
		.TQ22(	1'b0),
		.TQ23(	1'b0),
		.TQ24(	1'b0),
		.TQ25(	1'b0),
		.TQ26(	1'b0),
		.TQ27(	1'b0),
		.TQ28(	1'b0),
		.TQ29(	1'b0),
		.TQ30(	1'b0),
		.TQ31(	1'b0),
		.TQ32(	1'b0),
		.TQ33(	1'b0),
		.TQ34(	1'b0),
		.TQ35(	1'b0),
		.TQ36(	1'b0),
		.TQ37(	1'b0),
		.TQ38(	1'b0),
		.TQ39(	1'b0),
		.TQ40(	1'b0),
		.TQ41(	1'b0),
		.TQ42(	1'b0),
		.TQ43(	1'b0),
		.TQ44(	1'b0),
		.TQ45(	1'b0),
		.TQ46(	1'b0),
		.TQ47(	1'b0),
		.TQ48(	1'b0),
		.TQ49(	1'b0),
		.TQ50(	1'b0),
		.TQ51(	1'b0),
		.TQ52(	1'b0),
		.TQ53(	1'b0),
		.TQ54(	1'b0),
		.TQ55(	1'b0),
		.TQ56(	1'b0),
		.TQ57(	1'b0),
		.TQ58(	1'b0),
		.TQ59(	1'b0),
		.TQ60(	1'b0),
		.TQ61(	1'b0),
		.TQ62(	1'b0),
		.TQ63(	1'b0),
		.TQ64(	1'b0),
		.TQ65(	1'b0),
		.TQ66(	1'b0),
		.TQ67(	1'b0),
		.TQ68(	1'b0),
		.TQ69(	1'b0),
		.TQ70(	1'b0),
		.TQ71(	1'b0),
		.TQ72(	1'b0),
		.TQ73(	1'b0),
		.TQ74(	1'b0),
		.TQ75(	1'b0),
		.TQ76(	1'b0),
		.TQ77(	1'b0),
		.TBW0(	1'b0),
		.TBW1(	1'b0),
		.TBW2(	1'b0),
		.TBW3(	1'b0),
		.TBW4(	1'b0),
		.TBW5(	1'b0),
		.TBW6(	1'b0),
		.TBW7(	1'b0),
		.TBW8(	1'b0),
		.TBW9(	1'b0),
		.TBW10(	1'b0),
		.TBW11(	1'b0),
		.TBW12(	1'b0),
		.TBW13(	1'b0),
		.TBW14(	1'b0),
		.TBW15(	1'b0),
		.TBW16(	1'b0),
		.TBW17(	1'b0),
		.TBW18(	1'b0),
		.TBW19(	1'b0),
		.TBW20(	1'b0),
		.TBW21(	1'b0),
		.TBW22(	1'b0),
		.TBW23(	1'b0),
		.TBW24(	1'b0),
		.TBW25(	1'b0),
		.TBW26(	1'b0),
		.TBW27(	1'b0),
		.TBW28(	1'b0),
		.TBW29(	1'b0),
		.TBW30(	1'b0),
		.TBW31(	1'b0),
		.TBW32(	1'b0),
		.TBW33(	1'b0),
		.TBW34(	1'b0),
		.TBW35(	1'b0),
		.TBW36(	1'b0),
		.TBW37(	1'b0),
		.TBW38(	1'b0),
		.TBW39(	1'b0),
		.TBW40(	1'b0),
		.TBW41(	1'b0),
		.TBW42(	1'b0),
		.TBW43(	1'b0),
		.TBW44(	1'b0),
		.TBW45(	1'b0),
		.TBW46(	1'b0),
		.TBW47(	1'b0),
		.TBW48(	1'b0),
		.TBW49(	1'b0),
		.TBW50(	1'b0),
		.TBW51(	1'b0),
		.TBW52(	1'b0),
		.TBW53(	1'b0),
		.TBW54(	1'b0),
		.TBW55(	1'b0),
		.TBW56(	1'b0),
		.TBW57(	1'b0),
		.TBW58(	1'b0),
		.TBW59(	1'b0),
		.TBW60(	1'b0),
		.TBW61(	1'b0),
		.TBW62(	1'b0),
		.TBW63(	1'b0),
		.TBW64(	1'b0),
		.TBW65(	1'b0),
		.TBW66(	1'b0),
		.TBW67(	1'b0),
		.TBW68(	1'b0),
		.TBW69(	1'b0),
		.TBW70(	1'b0),
		.TBW71(	1'b0),
		.TBW72(	1'b0),
		.TBW73(	1'b0),
		.TBW74(	1'b0),
		.TBW75(	1'b0),
		.TBW76(	1'b0),
		.TBW77(	1'b0),
		.MIEMAT0(	1'b0),
		.MIEMAT1(	1'b0),
		.MIEMAW0(	1'b0),
		.MIEMAW1(	1'b0),
		.MIEMAWASS0(	1'b0),
		.MIEMAWASS1(	1'b0),
		.MIEMASASS0(	1'b0),
		.MIEMASASS1(	1'b0),
		.MIEMASASS2(	1'b0),
		.CR00(	1'b0),
		.CR01(	1'b0),
		.CR02(	1'b0),
		.CR03(	1'b0),
		.CR04(	1'b0),
		.CR05(	1'b0),
		.TCE(	1'b0),
		.TRDWEN(	1'b0),
		.TDEEPSLEEP(	1'b0),
		.MITESTM1(	1'b0),
		.MITESTM3(	1'b0),
		.MICLKMODE(	1'b0),
		.MILSMODE(	1'b0),
		.MIPIPEMODE(	1'b0),
		.MISTM(	1'b0),
		.MISASSD(	1'b0),
		.MIWASSD(	1'b0),
		.MIWRTM(	1'b0),
		.MIFLOOD(	1'b0),
		.CRE0(	1'b0));
endmodule
