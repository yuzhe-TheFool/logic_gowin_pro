//Copyright (C)2014-2026 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.12.02_SP2 (64-bit)
//IP Version: 1.0
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Tue Jun 23 17:34:44 2026

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	cons_fifo your_instance_name(
		.Data(Data), //input [31:0] Data
		.WrReset(WrReset), //input WrReset
		.RdReset(RdReset), //input RdReset
		.WrClk(WrClk), //input WrClk
		.RdClk(RdClk), //input RdClk
		.WrEn(WrEn), //input WrEn
		.RdEn(RdEn), //input RdEn
		.Rnum(Rnum), //output [14:0] Rnum
		.Q(Q), //output [15:0] Q
		.Empty(Empty), //output Empty
		.Full(Full) //output Full
	);

//--------Copy end-------------------
